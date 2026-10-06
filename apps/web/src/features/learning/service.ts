import { and, asc, desc, eq, lte, sql } from "drizzle-orm";
import { formatInTimeZone } from "date-fns-tz";
import { differenceInCalendarDays, parseISO } from "date-fns";
import { topoOrder, topoRank, zigzag, type GraphNode } from "@axiom/content-schema";
import type { Lesson } from "@axiom/content-schema";
import { getDb } from "@/server/db/client";
import {
  contentPacks,
  itemResults,
  lessonAttempts,
  lessons,
  placementAnswers,
  placementSessions,
  profiles,
  reviewCards,
  skillMastery,
  skillNodes,
  streaks,
  worlds,
  user,
  xpEvents,
} from "@/server/db/schema";
import {
  applyMastery,
  emptyMastery,
  isMastered,
  missionBudget,
  nextPlacement,
  placementDone,
  rateAttempt,
  type MasterySnapshot,
} from "./domain/mastery";
import { scheduleReview } from "./domain/review";

function snapshotFrom(row?: { score: string; attempts: number; correctCount: number; recent: unknown }): MasterySnapshot {
  if (!row) return emptyMastery();
  return {
    score: Number(row.score),
    attempts: row.attempts,
    correctCount: row.correctCount,
    recent: Array.isArray(row.recent) ? (row.recent as boolean[]) : [],
  };
}

async function masteryMap(userId: string) {
  const rows = await getDb().select().from(skillMastery).where(eq(skillMastery.userId, userId));
  return new Map(rows.map((row) => [row.skillNodeId, snapshotFrom(row)]));
}

export async function getPublishedSkills() {
  return getDb().select().from(skillNodes).where(eq(skillNodes.status, "published")).orderBy(asc(skillNodes.sortOrder));
}

export async function getPath(userId: string) {
  const skills = await getPublishedSkills();
  const graph: GraphNode[] = skills.map((skill) => ({
    id: skill.id,
    prereqIds: skill.prereqIds,
    sortOrder: skill.sortOrder,
  }));
  const ordered = topoOrder(graph);
  const ranks = topoRank(graph);
  const lanes = new Map<string, "left" | "right">();
  const byRank = new Map<number, GraphNode[]>();
  for (const node of ordered) {
    const rank = ranks.get(node.id) ?? 0;
    const list = byRank.get(rank) ?? [];
    list.push(node);
    byRank.set(rank, list);
  }
  for (const group of byRank.values()) {
    for (const lane of zigzag(group)) lanes.set(lane.nodeId, lane.lane);
  }
  const mastery = await masteryMap(userId);
  const worldRows = await getDb().select().from(worlds);
  const worldName = new Map(worldRows.map((world) => [world.id, world.title]));
  const publishedLessons = await getDb().select().from(lessons).where(eq(lessons.status, "published"));
  const completed = await getDb()
    .select({ lessonId: lessonAttempts.lessonId })
    .from(lessonAttempts)
    .where(and(eq(lessonAttempts.userId, userId), sql`${lessonAttempts.completedAt} is not null`));
  const done = new Set(completed.map((row) => row.lessonId));
  const lessonsBySkill = new Map<string, string[]>();
  for (const lesson of [...publishedLessons].sort((a, b) => a.id.localeCompare(b.id))) {
    const list = lessonsBySkill.get(lesson.skillNodeId) ?? [];
    list.push(lesson.id);
    lessonsBySkill.set(lesson.skillNodeId, list);
  }
  const byId = new Map(skills.map((skill) => [skill.id, skill]));

  return ordered.map((node, index) => {
    const skill = byId.get(node.id)!;
    const snap = mastery.get(skill.id) ?? emptyMastery();
    const prereqsMastered = skill.prereqIds.every((id) => isMastered(mastery.get(id) ?? emptyMastery()));
    const state = isMastered(snap) ? "mastered" : prereqsMastered ? "available" : "locked";
    const rank = ranks.get(skill.id) ?? 0;
    const group = byRank.get(rank) ?? [];
    const lane = group.length > 1 ? (lanes.get(skill.id) ?? "left") : index % 2 === 0 ? "left" : "right";
    return {
      id: skill.id,
      title: skill.title,
      promise: skill.promise,
      pipAbility: skill.pipAbility,
      rank,
      lane,
      progress: Number(snap.score.toFixed(2)),
      worldTitle: worldName.get(skill.worldId) ?? "",
      state,
      lessonId: (lessonsBySkill.get(skill.id) ?? []).find((id) => !done.has(id)) ?? lessonsBySkill.get(skill.id)?.[0] ?? null,
      waitsOn:
        skill.prereqIds
          .filter((id) => !isMastered(mastery.get(id) ?? emptyMastery()))
          .map((id) => byId.get(id)?.title)
          .find((title) => Boolean(title)) ?? "",
    };
  });
}

export async function startAttempt(userId: string, lessonId: string, attemptId = crypto.randomUUID()) {
  const db = getDb();
  await db.insert(lessonAttempts).values({ id: attemptId, userId, lessonId }).onConflictDoNothing();
  return { attemptId };
}

export async function applyResults(
  userId: string,
  attemptId: string,
  results: { id: string; screenId: string; correct: boolean; latencyMs: number; errorCode?: string | null; hadMiss?: boolean }[],
) {
  const db = getDb();
  const [attempt] = await db.select().from(lessonAttempts).where(eq(lessonAttempts.id, attemptId));
  if (!attempt || attempt.userId !== userId) return { error: "attempt_not_found" as const };
  const [lesson] = await db.select().from(lessons).where(eq(lessons.id, attempt.lessonId));
  if (!lesson) return { error: "attempt_not_found" as const };
  const definition = lesson.definition as Lesson;
  const appliedIds: string[] = [];

  for (const result of results) {
    const inserted = await db
      .insert(itemResults)
      .values({
        id: result.id,
        attemptId,
        screenId: result.screenId,
        correct: result.correct,
        latencyMs: result.latencyMs,
        errorCode: result.errorCode ?? null,
        hadMiss: result.hadMiss ?? false,
        skillNodeId: lesson.skillNodeId,
      })
      .onConflictDoNothing()
      .returning({ id: itemResults.id });
    if (inserted.length === 0) continue;
    appliedIds.push(result.id);
    if (result.correct) {
      await db
        .insert(xpEvents)
        .values({ userId, amount: 10, reason: "correct_screen", idempotencyKey: result.id })
        .onConflictDoNothing();
    }
    const [existing] = await db
      .select()
      .from(skillMastery)
      .where(and(eq(skillMastery.userId, userId), eq(skillMastery.skillNodeId, lesson.skillNodeId)));
    const next = applyMastery(snapshotFrom(existing), { correct: result.correct });
    await db
      .insert(skillMastery)
      .values({
        userId,
        skillNodeId: lesson.skillNodeId,
        score: next.score.toFixed(5),
        attempts: next.attempts,
        correctCount: next.correctCount,
        recent: next.recent,
      })
      .onConflictDoUpdate({
        target: [skillMastery.userId, skillMastery.skillNodeId],
        set: {
          score: next.score.toFixed(5),
          attempts: next.attempts,
          correctCount: next.correctCount,
          recent: next.recent,
          updatedAt: new Date(),
        },
      });
    const screen = definition.screens.find((item) => item.id === result.screenId);
    const rating = rateAttempt({
      correct: result.correct,
      hadMiss: result.hadMiss ?? false,
      latencyMs: result.latencyMs,
      easyWithinMs: screen?.easyWithinMs ?? 8000,
    });
    const [card] = await db
      .select()
      .from(reviewCards)
      .where(and(eq(reviewCards.userId, userId), eq(reviewCards.skillNodeId, lesson.skillNodeId)));
    const scheduled = scheduleReview(card?.fsrs as never, rating, new Date());
    await db
      .insert(reviewCards)
      .values({
        userId,
        skillNodeId: lesson.skillNodeId,
        dueAt: new Date(scheduled.dueAt),
        stability: scheduled.stability.toString(),
        difficulty: scheduled.difficulty.toString(),
        reps: scheduled.reps,
        lapses: scheduled.lapses,
        state: scheduled.state,
        fsrs: scheduled.fsrs,
      })
      .onConflictDoUpdate({
        target: [reviewCards.userId, reviewCards.skillNodeId],
        set: {
          dueAt: new Date(scheduled.dueAt),
          stability: scheduled.stability.toString(),
          difficulty: scheduled.difficulty.toString(),
          reps: scheduled.reps,
          lapses: scheduled.lapses,
          state: scheduled.state,
          fsrs: scheduled.fsrs,
        },
      });
  }

  const mastery = snapshotFrom(
    (
      await db
        .select()
        .from(skillMastery)
        .where(and(eq(skillMastery.userId, userId), eq(skillMastery.skillNodeId, lesson.skillNodeId)))
    )[0],
  );
  const [xp] = await db
    .select({ total: sql<number>`coalesce(sum(${xpEvents.amount}), 0)` })
    .from(xpEvents)
    .where(eq(xpEvents.userId, userId));
  return { appliedIds, mastery, xpTotal: Number(xp?.total ?? 0) };
}

export async function completeAttempt(userId: string, attemptId: string) {
  const db = getDb();
  const [attempt] = await db.select().from(lessonAttempts).where(eq(lessonAttempts.id, attemptId));
  if (!attempt || attempt.userId !== userId) return { error: "attempt_not_found" as const };
  await db.update(lessonAttempts).set({ completedAt: new Date() }).where(eq(lessonAttempts.id, attemptId));
  const [profile] = await db.select().from(profiles).where(eq(profiles.userId, userId));
  const timezone = profile?.timezone || "UTC";
  const today = formatInTimeZone(new Date(), timezone, "yyyy-MM-dd");
  const [streak] = await db.select().from(streaks).where(eq(streaks.userId, userId));
  let current = 1;
  if (streak?.lastActiveDate === today) current = streak.current;
  else if (streak?.lastActiveDate && differenceInCalendarDays(parseISO(today), parseISO(streak.lastActiveDate)) === 1) {
    current = streak.current + 1;
  }
  const longest = Math.max(current, streak?.longest ?? 0);
  await db
    .insert(streaks)
    .values({ userId, current, longest, lastActiveDate: today, freezes: streak?.freezes ?? 2 })
    .onConflictDoUpdate({
      target: streaks.userId,
      set: { current, longest, lastActiveDate: today },
    });
  const [lesson] = await db.select().from(lessons).where(eq(lessons.id, attempt.lessonId));
  const [skill] = lesson ? await db.select().from(skillNodes).where(eq(skillNodes.id, lesson.skillNodeId)) : [];
  const definition = lesson?.definition as Lesson | undefined;
  const [xp] = await db
    .select({ total: sql<number>`coalesce(sum(${xpEvents.amount}), 0)` })
    .from(xpEvents)
    .where(eq(xpEvents.userId, userId));
  const facts = await db.select({ correct: itemResults.correct }).from(itemResults).where(eq(itemResults.attemptId, attemptId));
  const misses = facts.filter((fact) => !fact.correct).length;
  const mastery = snapshotFrom(
    lesson
      ? (
          await db
            .select()
            .from(skillMastery)
            .where(and(eq(skillMastery.userId, userId), eq(skillMastery.skillNodeId, lesson.skillNodeId)))
        )[0]
      : undefined,
  );
  const published = await getPublishedSkills();
  const index = skill ? published.findIndex((item) => item.id === skill.id) : -1;
  const follower = index >= 0 ? published.slice(index + 1).find((item) => item.worldId === skill?.worldId) : undefined;
  const publishedLessons = await db
    .select()
    .from(lessons)
    .where(and(eq(lessons.skillNodeId, lesson?.skillNodeId ?? ""), eq(lessons.status, "published")));
  const finished = await db
    .select({ lessonId: lessonAttempts.lessonId })
    .from(lessonAttempts)
    .where(and(eq(lessonAttempts.userId, userId), sql`${lessonAttempts.completedAt} is not null`));
  const finishedIds = new Set(finished.map((row) => row.lessonId));
  finishedIds.add(attempt.lessonId);
  const nextLesson = [...publishedLessons]
    .filter((item) => !finishedIds.has(item.id))
    .sort((a, b) => a.id.localeCompare(b.id))[0];
  const nextLessonTitle = nextLesson ? (nextLesson.definition as Lesson).title : null;
  return {
    streakCurrent: current,
    xpTotal: Number(xp?.total ?? 0),
    pipAbility: skill?.pipAbility ?? "",
    whyItMatters: definition?.whyItMatters ?? "",
    skillMastered: isMastered(mastery),
    nextTitle: follower?.title ?? null,
    nextLessonTitle,
    misses,
  };
}

export async function reviewQueue(userId: string) {
  const [profile] = await getDb().select().from(profiles).where(eq(profiles.userId, userId));
  const budget = missionBudget(profile?.dailyGoalMinutes ?? 5);
  const limit = budget >= 8 ? 6 : budget >= 6 ? 4 : 2;
  const rows = await getDb()
    .select()
    .from(reviewCards)
    .where(and(eq(reviewCards.userId, userId), lte(reviewCards.dueAt, new Date())))
    .orderBy(asc(reviewCards.dueAt))
    .limit(limit);
  return { skillIds: rows.map((row) => row.skillNodeId) };
}

export async function getLearner(userId: string) {
  const summary = await profileSummary(userId);
  const [account] = await getDb().select().from(user).where(eq(user.id, userId));
  return {
    id: userId,
    email: account?.email ?? "",
    role: account?.role ?? "learner",
    displayName: summary.displayName,
    dailyGoalMinutes: summary.dailyGoalMinutes,
    timezone: summary.timezone,
    onboardingCompletedAt: summary.onboardingCompletedAt,
    placementSkillId: summary.placementSkillId,
  };
}

export async function profileSummary(userId: string) {
  const db = getDb();
  const [profile] = await db.select().from(profiles).where(eq(profiles.userId, userId));
  const [streak] = await db.select().from(streaks).where(eq(streaks.userId, userId));
  const [xp] = await db
    .select({ total: sql<number>`coalesce(sum(${xpEvents.amount}), 0)` })
    .from(xpEvents)
    .where(eq(xpEvents.userId, userId));
  return {
    displayName: profile?.displayName ?? "",
    dailyGoalMinutes: profile?.dailyGoalMinutes ?? 5,
    timezone: profile?.timezone ?? "UTC",
    onboardingCompletedAt: profile?.onboardingCompletedAt?.toISOString() ?? null,
    placementSkillId: profile?.placementSkillId ?? null,
    streakCurrent: streak?.current ?? 0,
    streakLongest: streak?.longest ?? 0,
    xpTotal: Number(xp?.total ?? 0),
    todayDone:
      Boolean(streak?.lastActiveDate) &&
      String(streak?.lastActiveDate).slice(0, 10) ===
        formatInTimeZone(new Date(), profile?.timezone || "UTC", "yyyy-MM-dd"),
  };
}

export async function updateProfile(
  userId: string,
  patch: { displayName?: string; dailyGoalMinutes?: number; timezone?: string; onboardingCompletedAt?: string | null },
) {
  const db = getDb();
  await db
    .update(profiles)
    .set({
      displayName: patch.displayName,
      dailyGoalMinutes: patch.dailyGoalMinutes,
      timezone: patch.timezone,
      onboardingCompletedAt: patch.onboardingCompletedAt ? new Date(patch.onboardingCompletedAt) : undefined,
    })
    .where(eq(profiles.userId, userId));
  return profileSummary(userId);
}

export async function currentPack() {
  const [pack] = await getDb().select().from(contentPacks).orderBy(desc(contentPacks.publishedAt)).limit(1);
  return pack ?? null;
}

export async function packByVersion(version: string) {
  const [pack] = await getDb().select().from(contentPacks).where(eq(contentPacks.version, version)).limit(1);
  return pack ?? null;
}

function skillAtRank(skills: Awaited<ReturnType<typeof getPublishedSkills>>, rank: number) {
  const graph: GraphNode[] = skills.map((skill) => ({ id: skill.id, prereqIds: skill.prereqIds, sortOrder: skill.sortOrder }));
  const ranks = topoRank(graph);
  const ordered = topoOrder(graph);
  return ordered.map((node) => skills.find((skill) => skill.id === node.id)!).find((skill) => ranks.get(skill.id) === rank) ?? null;
}

export async function startPlacement(userId: string) {
  const skills = await getPublishedSkills();
  const graph: GraphNode[] = skills.map((skill) => ({ id: skill.id, prereqIds: skill.prereqIds, sortOrder: skill.sortOrder }));
  const ranks = topoRank(graph);
  const maxRank = Math.max(0, ...ranks.values());
  const [session] = await getDb()
    .insert(placementSessions)
    .values({ userId, low: 0, high: maxRank, asked: 0 })
    .returning();
  const mid = Math.floor(maxRank / 2);
  const skill = skillAtRank(skills, mid);
  return {
    sessionId: session.id,
    completed: false,
    skillId: skill?.id ?? null,
    screen: await firstScreen(skill?.id ?? null),
  };
}

export async function answerPlacement(userId: string, sessionId: string, correct: boolean) {
  const db = getDb();
  const [session] = await db.select().from(placementSessions).where(eq(placementSessions.id, sessionId));
  if (!session || session.userId !== userId) return { error: "attempt_not_found" as const };
  const step = nextPlacement({ low: session.low, high: session.high, correct });
  const asked = session.asked + 1;
  const skills = await getPublishedSkills();
  const graph: GraphNode[] = skills.map((skill) => ({ id: skill.id, prereqIds: skill.prereqIds, sortOrder: skill.sortOrder }));
  const mid = Math.min(Math.max(step.low, 0), Math.max(...topoRank(graph).values(), 0));
  const skill = skillAtRank(skills, mid);
  if (skill) {
    await db.insert(placementAnswers).values({ sessionId, skillNodeId: skill.id, correct });
  }
  const done = placementDone({ low: step.low, high: step.high, asked });
  await db
    .update(placementSessions)
    .set({
      low: step.low,
      high: step.high,
      asked,
      recommendedSkillId: done ? skill?.id ?? null : null,
      completedAt: done ? new Date() : null,
    })
    .where(eq(placementSessions.id, sessionId));
  if (done && skill) {
    await db.update(profiles).set({ placementSkillId: skill.id }).where(eq(profiles.userId, userId));
  }
  return {
    completed: done,
    skillId: skill?.id ?? null,
    screen: done ? null : await firstScreen(skill?.id ?? null),
  };
}

async function firstScreen(skillId: string | null) {
  if (!skillId) return null;
  const [lesson] = await getDb()
    .select()
    .from(lessons)
    .where(and(eq(lessons.skillNodeId, skillId), eq(lessons.status, "published")))
    .limit(1);
  if (!lesson) return null;
  const definition = lesson.definition as Lesson;
  return definition.screens[0] ?? null;
}

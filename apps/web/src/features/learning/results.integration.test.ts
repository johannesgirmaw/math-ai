import { randomUUID } from "node:crypto";
import { eq, sql } from "drizzle-orm";
import { describe, expect, it } from "vitest";
import { applyResults, startAttempt } from "@/features/learning/service";
import { getDb } from "@/server/db/client";
import { itemResults, lessonAttempts, lessons, profiles, skillNodes, streaks, user, worlds, xpEvents } from "@/server/db/schema";

const enabled = process.env.AXIOM_INTEGRATION === "1";

describe.skipIf(!enabled)("attempt facts", () => {
  it("stores one item row and one XP row when the same result is posted twice", async () => {
    const db = getDb();
    const userId = `user-${randomUUID()}`;
    const worldId = randomUUID();
    const skillId = randomUUID();
    const lessonId = randomUUID();
    const attemptId = randomUUID();
    const resultId = randomUUID();
    const screen = {
      id: "screen-1",
      prompt: "Pick the arrow.",
      primitive: {
        type: "choice",
        options: [
          { id: "a", label: "Right" },
          { id: "b", label: "Left" },
        ],
        correctOptionId: "a",
      },
      feedback: { wrong_option: "The arrow points right." },
      easyWithinMs: 8000,
      correctMessage: "That is the arrow.",
    };
    await db.insert(user).values({
      id: userId,
      name: "Ada",
      email: `${userId}@axiom.app`,
    });
    await db.insert(profiles).values({ userId, displayName: "Ada" });
    await db.insert(streaks).values({ userId });
    await db.insert(worlds).values({
      id: worldId,
      slug: `world-${userId}`,
      title: "Space",
      sortOrder: 0,
    });
    await db.insert(skillNodes).values({
      id: skillId,
      worldId,
      slug: `skill-${userId}`,
      title: "Arrows",
      promise: "You can point an arrow.",
      prereqIds: [],
      sortOrder: 0,
      pipAbility: "Pip can aim an arrow.",
    });
    await db.insert(lessons).values({
      id: lessonId,
      skillNodeId: skillId,
      title: "Arrows",
      version: 1,
      status: "published",
      definition: {
        id: lessonId,
        skillNodeId: skillId,
        title: "Arrows",
        version: 1,
        capstone: false,
        whyItMatters: "A vector is a move.",
        screens: [screen, screen, screen, screen, screen],
      },
    });

    await startAttempt(userId, lessonId, attemptId);
    await startAttempt(userId, lessonId, attemptId);
    const fact = {
      id: resultId,
      screenId: "screen-1",
      correct: true,
      latencyMs: 9000,
      errorCode: null,
      hadMiss: false,
    };
    const first = await applyResults(userId, attemptId, [fact]);
    const second = await applyResults(userId, attemptId, [fact]);
    const [items] = await db
      .select({ count: sql<number>`count(*)` })
      .from(itemResults)
      .where(eq(itemResults.attemptId, attemptId));
    const [xp] = await db.select({ count: sql<number>`count(*)` }).from(xpEvents).where(eq(xpEvents.userId, userId));
    const [attempts] = await db
      .select({ count: sql<number>`count(*)` })
      .from(lessonAttempts)
      .where(eq(lessonAttempts.id, attemptId));

    expect(first).toMatchObject({ appliedIds: [resultId] });
    expect(second).toMatchObject({ appliedIds: [] });
    expect(Number(items?.count)).toBe(1);
    expect(Number(xp?.count)).toBe(1);
    expect(Number(attempts?.count)).toBe(1);

    await db.delete(user).where(eq(user.id, userId));
    await db.delete(lessons).where(eq(lessons.id, lessonId));
    await db.delete(skillNodes).where(eq(skillNodes.id, skillId));
    await db.delete(worlds).where(eq(worlds.id, worldId));
  });
});

"use server";

import { createHash, randomUUID } from "node:crypto";
import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { eq } from "drizzle-orm";
import { assertAcyclic, canonicalJson, CycleError, lessonSchema, skillNodeSchema, type Lesson } from "@axiom/content-schema";
import { getAuth } from "@/server/auth";
import { getDb } from "@/server/db/client";
import { auditLog, contentPacks, lessons, skillNodes } from "@/server/db/schema";

async function actor() {
  const session = await getAuth().api.getSession({ headers: await headers() });
  const role = (session?.user as { role?: string } | undefined)?.role ?? "";
  return { id: session?.user.id ?? "", role };
}

function canEdit(role: string) {
  return role === "author" || role === "reviewer" || role === "admin";
}

export async function saveSkill(formData: FormData) {
  const user = await actor();
  if (!canEdit(user.role)) redirect("/");
  const id = String(formData.get("id") ?? "");
  const db = getDb();
  const rows = await db.select().from(skillNodes);
  const current = rows.find((skill) => skill.id === id);
  if (!current) redirect("/admin/skills");
  const prereqIds = String(formData.get("prereqIds") ?? "")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
  const parsed = skillNodeSchema.safeParse({
    id,
    worldId: current.worldId,
    slug: current.slug,
    title: String(formData.get("title") ?? ""),
    promise: String(formData.get("promise") ?? ""),
    prereqIds,
    sortOrder: Number(formData.get("sortOrder") ?? current.sortOrder),
    pipAbility: String(formData.get("pipAbility") ?? ""),
    status: current.status === "draft" ? "draft" : "published",
  });
  if (!parsed.success) {
    const message = parsed.error.issues.map((issue) => issue.message).join(" ");
    redirect(`/admin/skills/${id}?error=${encodeURIComponent(message)}`);
  }
  const graph = rows.map((skill) =>
    skill.id === id
      ? { id, prereqIds: parsed.data.prereqIds, sortOrder: parsed.data.sortOrder }
      : { id: skill.id, prereqIds: skill.prereqIds, sortOrder: skill.sortOrder },
  );
  try {
    assertAcyclic(graph);
  } catch (error) {
    const message = error instanceof CycleError ? `Cycle: ${error.nodeIds.join(" -> ")}` : "That change creates a cycle.";
    redirect(`/admin/skills/${id}?error=${encodeURIComponent(message)}`);
  }
  await db
    .update(skillNodes)
    .set({
      title: parsed.data.title,
      promise: parsed.data.promise,
      prereqIds: parsed.data.prereqIds,
      sortOrder: parsed.data.sortOrder,
      pipAbility: parsed.data.pipAbility,
    })
    .where(eq(skillNodes.id, id));
  redirect(`/admin/skills/${id}?saved=1`);
}

export async function saveLesson(formData: FormData) {
  const user = await actor();
  if (!canEdit(user.role)) redirect("/");
  const id = String(formData.get("id") ?? "");
  const intent = String(formData.get("intent") ?? "save");
  let body: unknown;
  try {
    body = JSON.parse(String(formData.get("definition") ?? ""));
  } catch {
    redirect(`/admin/lessons/${id}?error=${encodeURIComponent("That JSON could not be read.")}`);
  }
  const parsed = lessonSchema.safeParse(body);
  if (!parsed.success) {
    const message = parsed.error.issues.map((issue) => `${issue.path.join(".")}: ${issue.message}`).join(" ");
    redirect(`/admin/lessons/${id}?error=${encodeURIComponent(message)}`);
  }
  if (parsed.data.id !== id) {
    redirect(`/admin/lessons/${id}?error=${encodeURIComponent("The lesson id must stay the same.")}`);
  }
  const db = getDb();
  const [current] = await db.select().from(lessons).where(eq(lessons.id, id));
  if (!current) redirect("/admin/lessons");
  const status = current.status === "published" ? "published" : intent === "review" ? "in_review" : "draft";
  await db
    .update(lessons)
    .set({
      title: parsed.data.title,
      definition: parsed.data,
      status,
    })
    .where(eq(lessons.id, id));
  redirect(`/admin/lessons/${id}?saved=1`);
}

export async function publishPack() {
  const user = await actor();
  if (user.role !== "reviewer" && user.role !== "admin") return { error: "A reviewer publishes the pack." };
  const db = getDb();
  const skills = await db.select().from(skillNodes);
  const lessonRows = await db.select().from(lessons);
  const included = lessonRows.filter((lesson) => lesson.status === "published" || lesson.status === "in_review");
  const parsedLessons: Lesson[] = [];
  for (const lesson of included) {
    const parsed = lessonSchema.safeParse(lesson.definition);
    if (!parsed.success) {
      return { error: parsed.error.issues.map((issue) => issue.message).join(" ") };
    }
    parsedLessons.push(parsed.data);
  }
  const skillIds = new Set(parsedLessons.map((lesson) => lesson.skillNodeId));
  const packSkills = skills.filter((skill) => skillIds.has(skill.id));
  try {
    assertAcyclic(packSkills.map((skill) => ({ id: skill.id, prereqIds: skill.prereqIds, sortOrder: skill.sortOrder })));
  } catch (error) {
    if (error instanceof CycleError) return { error: `Cycle: ${error.nodeIds.join(" -> ")}` };
    return { error: "That pack contains a cycle." };
  }
  const body = {
    version: `v${Date.now()}`,
    skills: packSkills,
    lessons: parsedLessons,
  };
  const sha256 = createHash("sha256").update(canonicalJson(body)).digest("hex");
  const packId = randomUUID();
  await db.transaction(async (tx) => {
    await tx.insert(contentPacks).values({
      id: packId,
      version: body.version,
      sha256,
      manifest: {
        version: body.version,
        sha256,
        publishedAt: new Date().toISOString(),
        skillIds: packSkills.map((skill) => skill.id),
        lessonIds: parsedLessons.map((lesson) => lesson.id),
      },
      body,
    });
    for (const lesson of included) {
      await tx.update(lessons).set({ status: "published" }).where(eq(lessons.id, lesson.id));
    }
    await tx.insert(auditLog).values({
      actorId: user.id,
      action: "publish_pack",
      entity: "content_pack",
      entityId: packId,
    });
  });
  return { error: null as string | null, version: body.version };
}

export async function createLesson(formData: FormData) {
  const user = await actor();
  if (!canEdit(user.role)) redirect("/");
  const skillNodeId = String(formData.get("skillNodeId") ?? "");
  const title = String(formData.get("title") ?? "").trim();
  if (!skillNodeId || !title) redirect("/admin/lessons/new?error=Choose%20a%20skill%20and%20a%20title.");
  const id = randomUUID();
  const definition = lessonSchema.parse({
    id,
    skillNodeId,
    title,
    version: 1,
    capstone: false,
    whyItMatters: "A model uses this idea on a real input.",
    screens: ["one", "two", "three", "four", "five"].map((screenId, index) => ({
      id: screenId,
      prompt: `Screen ${index + 1}. Pick the move that matches the picture.`,
      primitive: {
        type: "choice",
        options: [
          { id: "a", label: "The move in the picture" },
          { id: "b", label: "A different move" },
        ],
        correctOptionId: "a",
      },
      feedback: { wrong_option: "That move does not match the picture." },
      easyWithinMs: 8000,
      correctMessage: "That move matches the picture.",
    })),
  });
  await getDb().insert(lessons).values({
    id,
    skillNodeId,
    title,
    version: 1,
    status: "draft",
    definition,
  });
  redirect(`/admin/lessons/${id}`);
}

import { eq } from "drizzle-orm";
import { assertAcyclic } from "@axiom/content-schema";
import { buildPackBody } from "@/content/curriculum";
import { getDb } from "./client";
import { contentPacks, lessons, skillNodes, worlds } from "./schema";

export async function seed() {
  const db = getDb();
  const pack = buildPackBody();
  assertAcyclic(
    pack.skills.map((skill) => ({
      id: skill.id,
      prereqIds: skill.prereqIds,
      sortOrder: skill.sortOrder,
    })),
  );

  for (const world of pack.worlds) {
    await db
      .insert(worlds)
      .values(world)
      .onConflictDoUpdate({
        target: worlds.slug,
        set: { title: world.title, sortOrder: world.sortOrder },
      });
  }

  for (const skill of pack.skills) {
    await db
      .insert(skillNodes)
      .values({
        id: skill.id,
        worldId: skill.worldId,
        slug: skill.slug,
        title: skill.title,
        promise: skill.promise,
        prereqIds: skill.prereqIds,
        sortOrder: skill.sortOrder,
        pipAbility: skill.pipAbility,
        status: skill.status,
      })
      .onConflictDoUpdate({
        target: skillNodes.id,
        set: {
          title: skill.title,
          promise: skill.promise,
          prereqIds: skill.prereqIds,
          sortOrder: skill.sortOrder,
          pipAbility: skill.pipAbility,
          status: skill.status,
        },
      });
  }

  for (const lesson of pack.lessons) {
    await db
      .insert(lessons)
      .values({
        id: lesson.id,
        skillNodeId: lesson.skillNodeId,
        title: lesson.title,
        version: lesson.version,
        status: "published",
        definition: lesson,
      })
      .onConflictDoUpdate({
        target: lessons.id,
        set: { title: lesson.title, definition: lesson, status: "published" },
      });
  }

  await db
    .insert(contentPacks)
    .values({
      id: "40000000-0000-4000-8000-000000000001",
      version: "v1",
      sha256: pack.sha256,
      manifest: pack.manifest,
      body: pack.body,
    })
    .onConflictDoUpdate({
      target: contentPacks.version,
      set: { sha256: pack.sha256, manifest: pack.manifest, body: pack.body },
    });

  const count = await db.select().from(skillNodes).where(eq(skillNodes.status, "published"));
  console.log(`Seeded ${count.length} skills and pack ${pack.sha256.slice(0, 12)}`);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  seed().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
  });
}

import { Suspense } from "react";
import { asc } from "drizzle-orm";
import { getDb } from "@/server/db/client";
import { skillNodes, worlds } from "@/server/db/schema";
import { SkillsTable } from "@/features/studio/skills-table";

export default async function SkillsPage() {
  const db = getDb();
  const [skills, worldRows] = await Promise.all([
    db.select().from(skillNodes).orderBy(asc(skillNodes.sortOrder)),
    db.select().from(worlds),
  ]);
  const slugById = new Map(worldRows.map((world) => [world.id, world.slug]));
  return (
    <main className="flex flex-col gap-4">
      <h1 className="text-3xl">Skills</h1>
      <Suspense fallback={<p>Loading skills</p>}>
        <SkillsTable
          rows={skills.map((skill) => ({
            id: skill.id,
            title: skill.title,
            promise: skill.promise,
            status: skill.status,
            worldSlug: slugById.get(skill.worldId) ?? "",
          }))}
        />
      </Suspense>
    </main>
  );
}

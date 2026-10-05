import Link from "next/link";
import { notFound } from "next/navigation";
import { getDb } from "@/server/db/client";
import { skillNodes } from "@/server/db/schema";
import { SkillForm } from "@/features/studio/skill-form";
import { SaveToast } from "@/features/studio/save-toast";

export default async function SkillEditorPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ error?: string; saved?: string }>;
}) {
  const { id } = await params;
  const query = await searchParams;
  const rows = await getDb().select().from(skillNodes);
  const skill = rows.find((item) => item.id === id);
  if (!skill) notFound();
  return (
    <main className="flex max-w-xl flex-col gap-4">
      <Link href="/admin/skills" className="text-sm">
        All skills
      </Link>
      <h1 className="text-3xl">{skill.title}</h1>
      <SaveToast saved={query.saved} />
      {query.error ? <p className="text-destructive">{query.error}</p> : null}
      <SkillForm
        id={skill.id}
        title={skill.title}
        promise={skill.promise}
        pipAbility={skill.pipAbility}
        sortOrder={skill.sortOrder}
        prereqIds={skill.prereqIds}
        others={rows.filter((item) => item.id !== skill.id).map((item) => ({ id: item.id, title: item.title }))}
      />
    </main>
  );
}

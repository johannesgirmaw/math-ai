import Link from "next/link";
import { asc } from "drizzle-orm";
import { getDb } from "@/server/db/client";
import { skillNodes } from "@/server/db/schema";
import { createLesson } from "@/features/studio/actions";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export default async function NewLessonPage({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
  const query = await searchParams;
  const skills = await getDb().select().from(skillNodes).orderBy(asc(skillNodes.sortOrder));
  return (
    <main className="flex max-w-xl flex-col gap-4">
      <Link href="/admin/lessons" className="text-sm">
        All lessons
      </Link>
      <h1 className="text-3xl">New lesson</h1>
      {query.error ? <p className="text-destructive">{query.error}</p> : null}
      <form action={createLesson} className="flex flex-col gap-4">
        <Label htmlFor="skillNodeId">Skill</Label>
        <select
          id="skillNodeId"
          name="skillNodeId"
          className="h-14 rounded-[20px] border border-input bg-card px-4"
          required
        >
          {skills.map((skill) => (
            <option key={skill.id} value={skill.id}>
              {skill.title}
            </option>
          ))}
        </select>
        <Label htmlFor="title">Title</Label>
        <Input id="title" name="title" required />
        <Button type="submit">Create draft</Button>
      </form>
    </main>
  );
}

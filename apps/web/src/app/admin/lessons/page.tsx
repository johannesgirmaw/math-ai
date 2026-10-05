import Link from "next/link";
import { asc } from "drizzle-orm";
import { getDb } from "@/server/db/client";
import { lessons } from "@/server/db/schema";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

export default async function LessonsPage() {
  const rows = await getDb().select().from(lessons).orderBy(asc(lessons.title));
  return (
    <main className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-3xl">Lessons</h1>
        <Button asChild size="sm">
          <Link href="/admin/lessons/new">New lesson</Link>
        </Button>
      </div>
      {rows.map((lesson) => (
        <article key={lesson.id} className="rounded-[20px] border border-border bg-card px-4 py-3">
          <div className="flex items-center justify-between gap-3">
            <h2 className="text-xl">
              <Link href={`/admin/lessons/${lesson.id}`}>{lesson.title}</Link>
            </h2>
            <Badge>{lesson.status}</Badge>
          </div>
        </article>
      ))}
    </main>
  );
}

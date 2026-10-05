import Link from "next/link";
import { eq } from "drizzle-orm";
import { notFound } from "next/navigation";
import { lessonSchema } from "@axiom/content-schema";
import { getDb } from "@/server/db/client";
import { lessons } from "@/server/db/schema";
import { LessonEditor } from "@/features/studio/lesson-editor";
import { SaveToast } from "@/features/studio/save-toast";

export default async function LessonEditorPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ error?: string; saved?: string }>;
}) {
  const { id } = await params;
  const query = await searchParams;
  const [lesson] = await getDb().select().from(lessons).where(eq(lessons.id, id));
  if (!lesson) notFound();
  const parsed = lessonSchema.safeParse(lesson.definition);
  return (
    <main className="flex flex-col gap-4">
      <Link href="/admin/lessons" className="text-sm">
        All lessons
      </Link>
      <h1 className="text-3xl">{lesson.title}</h1>
      <SaveToast saved={query.saved} />
      {query.error ? <p className="text-destructive">{query.error}</p> : null}
      {parsed.success ? (
        <LessonEditor initial={parsed.data} />
      ) : (
        <p className="text-destructive">This lesson does not match the schema yet.</p>
      )}
    </main>
  );
}

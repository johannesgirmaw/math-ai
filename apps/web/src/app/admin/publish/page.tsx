import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { getAuth } from "@/server/auth";
import { publishPack } from "@/features/studio/actions";
import { Button } from "@/components/ui/button";
import { SaveToast } from "@/features/studio/save-toast";

async function publish() {
  "use server";
  const result = await publishPack();
  if (result.error) redirect(`/admin/publish?error=${encodeURIComponent(result.error)}`);
  redirect(`/admin/publish?published=${encodeURIComponent(result.version ?? "")}`);
}

export default async function PublishPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string; published?: string }>;
}) {
  const session = await getAuth().api.getSession({ headers: await headers() });
  const role = (session?.user as { role?: string } | undefined)?.role;
  const canPublish = role === "reviewer" || role === "admin";
  if (!session) redirect("/");
  const query = await searchParams;
  return (
    <main className="flex flex-col gap-4">
      <h1 className="text-3xl">Publish</h1>
      <SaveToast published={query.published} />
      {query.published ? <p>Published {query.published}</p> : null}
      {query.error ? <p className="text-destructive">{query.error}</p> : null}
      {canPublish ? (
        <form action={publish}>
          <Button type="submit">Publish pack</Button>
        </form>
      ) : (
        <p>A reviewer publishes the pack. You can keep drafting.</p>
      )}
    </main>
  );
}

import { SignInForm } from "@/features/studio/sign-in-form";

export default async function SignInPage({
  searchParams,
}: {
  searchParams: Promise<{ next?: string; reason?: string }>;
}) {
  const params = await searchParams;
  const next = params.next?.startsWith("/admin") ? params.next : "/admin/skills";
  return (
    <main className="mx-auto flex min-h-screen max-w-md flex-col justify-center gap-6 px-6 py-16">
      <div>
        <p className="font-heading text-3xl">Axiom studio</p>
        <p className="mt-2 text-muted-foreground">Sign in to edit lessons. A learner account stays on the path.</p>
      </div>
      {params.reason === "learner" ? (
        <p className="rounded-[20px] border border-border bg-card p-4">
          This account is a learner. The studio needs an author, reviewer, or admin role.
        </p>
      ) : null}
      <SignInForm nextPath={next} />
    </main>
  );
}

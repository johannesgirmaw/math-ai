import { SiteFrame } from "@/components/brand/site-frame";
import { SignInForm } from "@/features/studio/sign-in-form";

export default async function SignInPage({
  searchParams,
}: {
  searchParams: Promise<{ next?: string; reason?: string }>;
}) {
  const params = await searchParams;
  const next = params.next?.startsWith("/admin") ? params.next : "/admin/skills";
  return (
    <SiteFrame footer={false}>
      <main className="mx-auto flex min-h-[70vh] max-w-md flex-col justify-center gap-6 px-6 py-16">
        <div>
          <p className="text-sm font-semibold tracking-[0.16em] text-teal">STUDIO</p>
          <h1 className="mt-2 text-3xl">Edit the path</h1>
          <p className="mt-2 text-muted-foreground">Sign in to edit lessons. A learner account stays on the path.</p>
        </div>
        {params.reason === "learner" ? (
          <p className="rounded-[20px] border border-border bg-card p-4">
            This account is a learner. The studio needs an author, reviewer, or admin role.
          </p>
        ) : null}
        <SignInForm nextPath={next} />
      </main>
    </SiteFrame>
  );
}

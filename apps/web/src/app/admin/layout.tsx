import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { NuqsAdapter } from "nuqs/adapters/next/app";
import { Toaster } from "sonner";
import { SiteHeader, studioLinks } from "@/components/brand/site-frame";
import { getAuth } from "@/server/auth";

export const dynamic = "force-dynamic";

const allowed = new Set(["author", "reviewer", "admin"]);

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const session = await getAuth().api.getSession({ headers: await headers() });
  const role = (session?.user as { role?: string } | undefined)?.role ?? "";
  if (!session) redirect("/sign-in?next=/admin/skills");
  if (!allowed.has(role)) redirect("/sign-in?reason=learner");
  return (
    <div className="flex min-h-screen flex-col bg-background">
      <SiteHeader links={studioLinks} lockup="symbol" />
      <div className="mx-auto flex w-full max-w-5xl flex-1 flex-col gap-6 px-6 py-8">
        <NuqsAdapter>{children}</NuqsAdapter>
      </div>
      <Toaster />
    </div>
  );
}

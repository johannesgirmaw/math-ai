import Link from "next/link";
import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { NuqsAdapter } from "nuqs/adapters/next/app";
import { Toaster } from "sonner";
import { getAuth } from "@/server/auth";

const allowed = new Set(["author", "reviewer", "admin"]);

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const session = await getAuth().api.getSession({ headers: await headers() });
  const role = (session?.user as { role?: string } | undefined)?.role ?? "";
  if (!session || !allowed.has(role)) redirect("/");
  return (
    <div className="mx-auto flex min-h-screen max-w-5xl flex-col gap-6 px-6 py-8">
      <header className="flex items-center justify-between">
        <p className="font-heading text-2xl">Axiom studio</p>
        <nav className="flex gap-4 text-sm">
          <Link href="/admin/skills">Skills</Link>
          <Link href="/admin/lessons">Lessons</Link>
          <Link href="/admin/publish">Publish</Link>
          <Link href="/admin/health">Health</Link>
        </nav>
      </header>
      <NuqsAdapter>{children}</NuqsAdapter>
      <Toaster />
    </div>
  );
}

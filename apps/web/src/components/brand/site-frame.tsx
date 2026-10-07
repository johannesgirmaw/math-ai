import Link from "next/link";
import { BrandLockup, BrandMark } from "@/components/brand/brand-mark";

const marketingLinks = [
  { href: "/method", label: "Method" },
  { href: "/sign-in", label: "Sign in" },
  { href: "/privacy", label: "Privacy" },
];

export const studioLinks = [
  { href: "/admin/skills", label: "Skills" },
  { href: "/admin/lessons", label: "Lessons" },
  { href: "/admin/publish", label: "Publish" },
  { href: "/admin/health", label: "Health" },
];

export function SiteHeader({
  links = marketingLinks,
  lockup = "stacked",
}: {
  links?: { href: string; label: string }[];
  lockup?: "stacked" | "symbol";
}) {
  return (
    <header className="border-b-2 border-gold bg-background">
      <div className="mx-auto flex w-full max-w-5xl flex-col items-start gap-4 px-6 py-4 md:flex-row md:items-center md:justify-between">
        <Link href="/" className="shrink-0" aria-label={lockup === "symbol" ? "MATH SI" : undefined}>
          {lockup === "stacked" ? <BrandLockup /> : <BrandMark className="h-12 w-auto" />}
        </Link>
        <nav className="flex flex-wrap gap-x-5 gap-y-2 text-sm font-medium">
          {links.map((link) => (
            <Link key={link.href} href={link.href} className="text-teal hover:underline">
              {link.label}
            </Link>
          ))}
        </nav>
      </div>
    </header>
  );
}

export function SiteFooter() {
  return (
    <footer className="mt-auto bg-charcoal text-white">
      <div className="mx-auto flex max-w-5xl flex-col gap-6 px-6 py-10">
        <BrandLockup tone="dark" />
        <p className="max-w-md text-sm text-white/80">Super intelligence rooted in precise mathematical logic.</p>
        <nav className="flex flex-wrap gap-4 text-sm">
          <Link href="/method" className="hover:text-gold">
            Method
          </Link>
          <Link href="/privacy" className="hover:text-gold">
            Privacy
          </Link>
          <Link href="/terms" className="hover:text-gold">
            Terms
          </Link>
        </nav>
      </div>
    </footer>
  );
}

export function SiteFrame({
  children,
  links,
  footer = true,
  lockup = "stacked",
}: {
  children: React.ReactNode;
  links?: { href: string; label: string }[];
  footer?: boolean;
  lockup?: "stacked" | "symbol";
}) {
  return (
    <div className="flex min-h-screen flex-col bg-background">
      <SiteHeader links={links} lockup={lockup} />
      <div className="flex-1">{children}</div>
      {footer ? <SiteFooter /> : null}
    </div>
  );
}

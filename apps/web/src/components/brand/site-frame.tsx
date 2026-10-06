import Image from "next/image";
import Link from "next/link";

const marketingLinks = [
  { href: "/method", label: "Method" },
  { href: "/privacy", label: "Privacy" },
];

export const studioLinks = [
  { href: "/admin/skills", label: "Skills" },
  { href: "/admin/lessons", label: "Lessons" },
  { href: "/admin/publish", label: "Publish" },
  { href: "/admin/health", label: "Health" },
];

export function SiteHeader({ links = marketingLinks }: { links?: { href: string; label: string }[] }) {
  return (
    <header className="border-b-2 border-gold bg-background">
      <div className="mx-auto flex w-full max-w-5xl flex-col items-start gap-4 px-6 py-4 md:flex-row md:items-center md:justify-between">
        <Link href="/" className="shrink-0">
          <Image
            src="/brand/math-si-logo.png"
            alt="MATH SI"
            width={185}
            height={120}
            priority
            className="h-[120px] w-auto"
          />
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
        <Image src="/brand/math-si-logo.png" alt="MATH SI" width={148} height={96} className="h-24 w-auto" />
        <p className="max-w-md text-sm text-white/80">Intelligent systems rooted in precise mathematical logic.</p>
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
}: {
  children: React.ReactNode;
  links?: { href: string; label: string }[];
  footer?: boolean;
}) {
  return (
    <div className="flex min-h-screen flex-col bg-background">
      <SiteHeader links={links} />
      <div className="flex-1">{children}</div>
      {footer ? <SiteFooter /> : null}
    </div>
  );
}

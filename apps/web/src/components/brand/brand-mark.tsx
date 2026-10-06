import Image from "next/image";
import { cn } from "@/lib/utils";

export function BrandMark({
  className,
  tone = "light",
}: {
  className?: string;
  tone?: "light" | "dark";
}) {
  return (
    <Image
      src={tone === "dark" ? "/brand/math-si-mark-on-dark.png" : "/brand/math-si-mark.png"}
      alt=""
      width={972}
      height={498}
      className={cn("h-[72px] w-auto", className)}
    />
  );
}

export function BrandLockup({ tone = "light", className }: { tone?: "light" | "dark"; className?: string }) {
  const onDark = tone === "dark";
  return (
    <span className={cn("inline-flex flex-col items-center gap-3", className)}>
      <BrandMark className="h-[72px]" tone={tone} />
      <span
        className={cn(
          "font-heading text-[15px] leading-none font-bold tracking-[0.28em]",
          onDark ? "text-white" : "text-charcoal",
        )}
      >
        MATH SI
      </span>
    </span>
  );
}

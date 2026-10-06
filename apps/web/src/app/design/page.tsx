import { notFound } from "next/navigation";
import { SiteFrame } from "@/components/brand/site-frame";
import { PipMark } from "@/components/pip-mark";
import { Banner } from "@/components/ui/banner";
import { Button } from "@/components/ui/button";
import { ProgressDots } from "@/components/ui/progress-dots";
import { Separator } from "@/components/ui/separator";

const swatches = [
  { name: "Analytical Teal", hex: "#005F73" },
  { name: "Luminous Gold", hex: "#D4AF37" },
  { name: "Charcoal Slate", hex: "#2B2D42" },
  { name: "Pure White", hex: "#FFFFFF" },
];

export default function DesignPage() {
  if (process.env.NODE_ENV === "production") notFound();
  return (
    <SiteFrame>
      <main className="mx-auto flex max-w-xl flex-col gap-6 px-6 py-10">
        <h1 className="text-4xl">Design</h1>
        <p className="text-sm font-semibold tracking-[0.16em] text-teal">FUNCTION OF AI</p>
        <div className="grid grid-cols-2 gap-3">
          {swatches.map((swatch) => (
            <div key={swatch.hex} className="overflow-hidden rounded-[20px] border border-border bg-card">
              <div className="h-16 border-b border-border" style={{ background: swatch.hex }} />
              <p className="px-3 py-2 text-sm">
                {swatch.name}
                <span className="mt-1 block text-muted-foreground">{swatch.hex}</span>
              </p>
            </div>
          ))}
        </div>
        <Button>Primary</Button>
        <Button variant="secondary">Secondary</Button>
        <Separator />
        <ProgressDots count={7} index={2} />
        <Banner tone="miss">The arrow points up. The target sits to the right.</Banner>
        <Banner tone="success">The tip matches the target.</Banner>
        <div className="flex items-end gap-6">
          <PipMark label="Pip resting" />
          <PipMark mastered label="Pip mastered" />
        </div>
      </main>
    </SiteFrame>
  );
}

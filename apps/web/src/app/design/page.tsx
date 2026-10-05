import { notFound } from "next/navigation";
import { PipMark } from "@/components/pip-mark";
import { Banner } from "@/components/ui/banner";
import { Button } from "@/components/ui/button";
import { ProgressDots } from "@/components/ui/progress-dots";
import { Separator } from "@/components/ui/separator";

export default function DesignPage() {
  if (process.env.NODE_ENV === "production") notFound();
  return (
    <main className="mx-auto flex max-w-xl flex-col gap-6 px-6 py-10">
      <h1 className="text-4xl">Design</h1>
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
  );
}

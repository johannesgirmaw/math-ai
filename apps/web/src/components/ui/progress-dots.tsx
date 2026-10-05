import { cn } from "@/lib/utils";

export function ProgressDots({ count, index }: { count: number; index: number }) {
  return (
    <div className="flex gap-2" aria-label={`Step ${index + 1} of ${count}`}>
      {Array.from({ length: count }, (_, dot) => (
        <span key={dot} className={cn("h-2.5 rounded-full", dot === index ? "w-6 bg-primary" : "w-2.5", dot < index && "bg-primary", dot > index && "bg-border")} />
      ))}
    </div>
  );
}

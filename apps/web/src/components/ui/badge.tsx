import { cn } from "@/lib/utils";

function Badge({ className, ...props }: React.ComponentProps<"span">) {
  return (
    <span
      className={cn("inline-flex items-center rounded-full bg-secondary px-3 py-1 text-xs font-medium", className)}
      {...props}
    />
  );
}

export { Badge };

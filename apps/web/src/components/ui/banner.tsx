export function Banner({ tone, children }: { tone: "success" | "miss"; children: string }) {
  const color = tone === "success" ? "#1F7A4D" : "#8C3A32";
  const mark = tone === "success" ? "✓" : "×";
  return (
    <p className="flex items-start gap-3 rounded-[20px] border border-border bg-card p-4" style={{ borderLeftWidth: 4, borderLeftColor: color }}>
      <span aria-hidden="true" style={{ color }}>
        {mark}
      </span>
      <span>{children}</span>
    </p>
  );
}

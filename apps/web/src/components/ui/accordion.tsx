export function Accordion({ items }: { items: { question: string; answer: string }[] }) {
  return (
    <div className="flex flex-col gap-2">
      {items.map((item) => (
        <details key={item.question} className="rounded-[20px] border border-border bg-card px-4 py-3">
          <summary className="cursor-pointer text-lg font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring">
            {item.question}
          </summary>
          <p className="pt-3 text-muted-foreground">{item.answer}</p>
        </details>
      ))}
    </div>
  );
}

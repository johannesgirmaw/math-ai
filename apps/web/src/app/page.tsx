import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { WaitlistForm } from "@/features/waitlist/form";

const steps = [
  { title: "Place an arrow", body: "A tail and a tip. That is a vector." },
  { title: "See agreement", body: "Two arrows that point together score a dot product." },
  { title: "Teach Pip", body: "The score lets Pip match the closer pattern." },
];

const titles = ["Coordinate plane", "Dot product", "Matrix times vector", "Eigen direction"];

export default function HomePage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-3xl flex-col gap-16 px-6 py-16">
      <header className="flex items-center justify-between">
        <p className="font-heading text-2xl">Axiom</p>
        <nav className="flex gap-4 text-sm">
          <Link href="/method">Method</Link>
          <Link href="/privacy">Privacy</Link>
        </nav>
      </header>
      <section className="flex flex-col gap-6">
        <Badge>Math for people who want AI to click</Badge>
        <h1 className="text-5xl leading-tight">Train the mind that trains the machine.</h1>
        <p className="max-w-xl text-lg text-muted-foreground">
          Five quiet minutes. One idea. A small robot ability at the end. From arrows on a plane to the math inside a learning machine.
        </p>
      </section>
      <section className="grid gap-4 md:grid-cols-3">
        {steps.map((step) => (
          <Card key={step.title}>
            <CardHeader>
              <CardTitle>{step.title}</CardTitle>
            </CardHeader>
            <CardContent>{step.body}</CardContent>
          </Card>
        ))}
      </section>
      <section>
        <h2 className="mb-4 text-3xl">The path</h2>
        <ol className="flex flex-col gap-2">
          {titles.map((title) => (
            <li key={title} className="rounded-[20px] border border-border bg-card px-4 py-3">
              {title}
            </li>
          ))}
        </ol>
      </section>
      <section className="flex flex-col gap-4">
        <h2 className="text-3xl">Questions</h2>
        <p>Who it is for. Teens and adults who want the math inside AI to feel obvious.</p>
        <p>How long. A few minutes.</p>
        <p>Cost. The learning path is free.</p>
        <p>Is it a chatbot. You do the math yourself.</p>
      </section>
      <section id="waitlist" className="flex flex-col gap-4">
        <h2 className="text-3xl">Get the first build</h2>
        <WaitlistForm />
      </section>
      <footer className="flex gap-4 text-sm text-muted-foreground">
        <Link href="/method">Method</Link>
        <Link href="/privacy">Privacy</Link>
        <Link href="/terms">Terms</Link>
      </footer>
    </main>
  );
}

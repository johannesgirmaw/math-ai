import type { Metadata } from "next";
import { SiteFrame } from "@/components/brand/site-frame";
import { PipMark } from "@/components/pip-mark";
import { Accordion } from "@/components/ui/accordion";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { getPublicPathTitles } from "@/features/marketing/path";
import { WaitlistForm } from "@/features/waitlist/form";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: { absolute: "MATH SI" },
  description:
    "Train the mind that trains the machine. Super intelligence rooted in precise mathematical logic.",
  alternates: { canonical: "/" },
};

const steps = [
  {
    title: "Place an arrow",
    body: "A tail and a tip. That is a vector.",
    mark: (
      <svg width="64" height="40" viewBox="0 0 64 40" aria-hidden="true">
        <line x1="8" y1="28" x2="48" y2="12" stroke="#005F73" strokeWidth="4" strokeLinecap="round" />
        <circle cx="48" cy="12" r="5" fill="#2B2D42" />
      </svg>
    ),
  },
  {
    title: "See agreement",
    body: "Two arrows that point together score a dot product.",
    mark: (
      <svg width="64" height="40" viewBox="0 0 64 40" aria-hidden="true">
        <line x1="8" y1="28" x2="40" y2="16" stroke="#2B2D42" strokeWidth="4" strokeLinecap="round" opacity="0.35" />
        <line x1="8" y1="32" x2="44" y2="22" stroke="#005F73" strokeWidth="4" strokeLinecap="round" />
      </svg>
    ),
  },
  {
    title: "Teach Pip",
    body: "The score lets Pip match the closer pattern.",
    mark: <PipMark label="Pip" />,
  },
];

const questions = [
  { question: "Who is it for?", answer: "Teens and adults who want the math inside super intelligence to feel obvious." },
  { question: "How long is a session?", answer: "A few minutes. One mission, one idea." },
  { question: "Do the lessons cost money?", answer: "The learning path is free." },
  { question: "Is it a chatbot?", answer: "You do the math yourself." },
];

export default async function HomePage() {
  const titles = await getPublicPathTitles();
  return (
    <SiteFrame>
    <main className="mx-auto flex max-w-5xl flex-col gap-16 px-6 py-10 md:py-16">
      <section className="flex max-w-xl flex-col gap-6">
        <p className="text-sm font-semibold tracking-[0.16em] text-teal">FUNCTION OF SI</p>
        <h1 className="font-heading text-4xl leading-tight md:text-5xl">Train the mind that trains the machine.</h1>
        <p className="text-lg text-muted-foreground">
          MATH SI turns precise mathematical ideas into short missions. Five quiet minutes. One idea. A small ability at the end.
        </p>
        <div className="flex flex-wrap gap-3">
          <Button asChild>
            <a href="/download/math-si.apk">Download for Android</a>
          </Button>
          <Button asChild variant="outline">
            <a href="#waitlist">Join the waitlist</a>
          </Button>
        </div>
      </section>
      <section className="grid gap-4 md:grid-cols-3">
        {steps.map((step) => (
          <Card key={step.title} className="border-t-2 border-t-gold">
            <CardHeader>
              {step.mark}
              <CardTitle>{step.title}</CardTitle>
            </CardHeader>
            <CardContent>{step.body}</CardContent>
          </Card>
        ))}
      </section>
      <section>
        <h2 className="mb-4 text-3xl">The path</h2>
        <ol className="grid gap-2 md:grid-cols-2">
          {titles.map((title) => (
            <li key={title}>
              <Card>
                <CardContent className="py-4">{title}</CardContent>
              </Card>
            </li>
          ))}
        </ol>
      </section>
      <section className="flex max-w-2xl flex-col gap-4">
        <h2 className="text-3xl">Questions</h2>
        <Accordion items={questions} />
      </section>
      <section id="waitlist" className="flex max-w-md flex-col gap-4">
        <h2 className="text-3xl">Get the first build</h2>
        <WaitlistForm />
      </section>
    </main>
    </SiteFrame>
  );
}

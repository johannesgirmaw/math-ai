import { notFound } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function DesignPage() {
  if (process.env.NODE_ENV === "production") notFound();
  return (
    <main className="mx-auto flex max-w-xl flex-col gap-6 px-6 py-10">
      <h1 className="text-4xl">Design</h1>
      <Button>Primary</Button>
      <Button variant="secondary">Secondary</Button>
      <Card>
        <CardHeader>
          <CardTitle>Pip</CardTitle>
        </CardHeader>
        <CardContent className="flex items-center gap-4">
          <span className="inline-block size-16 rounded-2xl bg-primary" aria-label="Pip resting" />
          <Badge>Mastered</Badge>
        </CardContent>
      </Card>
      <p className="border-l-4 border-destructive pl-3">The arrow points up. The target sits to the right.</p>
      <p className="border-l-4 border-green-800 pl-3">The tip matches the target.</p>
    </main>
  );
}

"use client";

import { useActionState } from "react";
import { joinWaitlist } from "@/features/waitlist/actions";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export function WaitlistForm() {
  const [state, action, pending] = useActionState(async (_prev: { ok: boolean; error?: string } | null, formData: FormData) => {
    return joinWaitlist(formData);
  }, null);

  if (state?.ok) return <p>You are on the list.</p>;

  return (
    <form action={action} className="flex max-w-md flex-col gap-3">
      <Label htmlFor="email">Email</Label>
      <Input id="email" name="email" type="email" required aria-describedby={state?.error ? "email-error" : undefined} />
      {state?.error ? (
        <p id="email-error" className="text-sm text-destructive">
          {state.error}
        </p>
      ) : null}
      <Button type="submit" disabled={pending}>
        Join the list
      </Button>
    </form>
  );
}

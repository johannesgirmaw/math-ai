"use server";

import { z } from "zod";
import { getDb } from "@/server/db/client";
import { waitlistEmails } from "@/server/db/schema";

const emailSchema = z.string().trim().email().transform((value) => value.toLowerCase());

export async function joinWaitlist(formData: FormData) {
  const parsed = emailSchema.safeParse(formData.get("email"));
  if (!parsed.success) return { ok: false as const, error: "Enter a valid email." };
  try {
    await getDb().insert(waitlistEmails).values({ email: parsed.data });
  } catch (error) {
    const message = error instanceof Error ? error.message : "";
    if (!message.toLowerCase().includes("unique") && !message.toLowerCase().includes("duplicate")) {
      console.error(error);
      return { ok: false as const, error: "Could not save that email." };
    }
    console.info("waitlist duplicate");
  }
  return { ok: true as const };
}

"use server";

import { z } from "zod";
import { logger } from "@/server/logger";
import { getDb } from "@/server/db/client";
import { waitlistEmails } from "@/server/db/schema";

const emailSchema = z.string().trim().email().transform((value) => value.toLowerCase());

export async function joinWaitlist(formData: FormData) {
  const parsed = emailSchema.safeParse(formData.get("email"));
  if (!parsed.success) return { ok: false as const, error: "Enter a valid email." };
  try {
    await getDb().insert(waitlistEmails).values({ email: parsed.data });
  } catch (error) {
    const code = typeof error === "object" && error && "code" in error ? String(error.code) : "";
    const message = error instanceof Error ? error.message : "";
    const duplicate = code === "23505" || /unique|duplicate/i.test(message);
    if (!duplicate) {
      logger.error(error);
      return { ok: false as const, error: "Could not save that email." };
    }
    logger.info("waitlist duplicate");
  }
  const apiKey = process.env.RESEND_API_KEY;
  if (apiKey) {
    try {
      await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          from: "Axiom <onboarding@resend.dev>",
          to: parsed.data,
          subject: "You are on the list",
          text: "You are on the Axiom list.",
        }),
      });
    } catch (error) {
      logger.info({ err: error }, "waitlist confirmation was not sent");
    }
  }
  return { ok: true as const };
}

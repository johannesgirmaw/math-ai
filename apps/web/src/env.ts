import { createEnv } from "@t3-oss/env-nextjs";
import { z } from "zod";

export const env = createEnv({
  server: {
    DATABASE_URL: z.string().url(),
    BETTER_AUTH_SECRET: z.string().min(16),
    BETTER_AUTH_URL: z.string().url(),
    SENTRY_DSN: z.string().optional().default(""),
    RESEND_API_KEY: z.string().optional().default(""),
    E2E_AUTHOR_EMAIL: z.string().optional().default(""),
    E2E_AUTHOR_PASSWORD: z.string().optional().default(""),
  },
  client: {
    NEXT_PUBLIC_SITE_URL: z.string().url(),
    NEXT_PUBLIC_POSTHOG_KEY: z.string().optional().default(""),
    NEXT_PUBLIC_POSTHOG_HOST: z.string().optional().default(""),
  },
  runtimeEnv: {
    DATABASE_URL: process.env.DATABASE_URL,
    BETTER_AUTH_SECRET: process.env.BETTER_AUTH_SECRET,
    BETTER_AUTH_URL: process.env.BETTER_AUTH_URL,
    SENTRY_DSN: process.env.SENTRY_DSN,
    RESEND_API_KEY: process.env.RESEND_API_KEY,
    E2E_AUTHOR_EMAIL: process.env.E2E_AUTHOR_EMAIL,
    E2E_AUTHOR_PASSWORD: process.env.E2E_AUTHOR_PASSWORD,
    NEXT_PUBLIC_SITE_URL: process.env.NEXT_PUBLIC_SITE_URL,
    NEXT_PUBLIC_POSTHOG_KEY: process.env.NEXT_PUBLIC_POSTHOG_KEY,
    NEXT_PUBLIC_POSTHOG_HOST: process.env.NEXT_PUBLIC_POSTHOG_HOST,
  },
  skipValidation: process.env.SKIP_ENV_VALIDATION === "true",
  emptyStringAsUndefined: true,
});

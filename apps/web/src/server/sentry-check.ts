import { requestLogger } from "./logger";

async function main() {
  const dsn = process.env.SENTRY_DSN ?? "";
  if (!dsn) {
    console.warn("SENTRY_DSN is absent; skipping sentry check");
    return;
  }
  const Sentry = await import("@sentry/nextjs");
  Sentry.init({ dsn, tracesSampleRate: 0 });
  const log = requestLogger("sentry-check");
  Sentry.captureException(new Error("axiom-sentry-check"));
  await Sentry.flush(2000);
  log.info("captured axiom-sentry-check");
}

void main();

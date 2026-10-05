import { Hono } from "hono";
import { z } from "zod";
import { getAuth } from "@/server/auth";
import { requestLogger } from "@/server/logger";
import {
  answerPlacement,
  applyResults,
  completeAttempt,
  currentPack,
  packByVersion,
  getLearner,
  getPath,
  profileSummary,
  reviewQueue,
  startAttempt,
  startPlacement,
  updateProfile,
} from "@/features/learning/service";

type Variables = { userId: string; role: string };

const buckets = new Map<string, { tokens: number; reset: number }>();

function allow(key: string) {
  const now = Date.now();
  const bucket = buckets.get(key);
  if (!bucket || bucket.reset < now) {
    buckets.set(key, { tokens: 29, reset: now + 60_000 });
    return true;
  }
  if (bucket.tokens <= 0) return false;
  bucket.tokens -= 1;
  return true;
}

function fail(code: string, message: string) {
  return { error: { code, message } };
}

const patchMeSchema = z.object({
  displayName: z.string().optional(),
  dailyGoalMinutes: z.union([z.literal(5), z.literal(10), z.literal(15)]).optional(),
  timezone: z.string().optional(),
  onboardingCompletedAt: z.string().datetime().nullable().optional(),
});

const attemptSchema = z.object({
  lessonId: z.string().uuid(),
  attemptId: z.string().uuid().optional(),
});

const resultsSchema = z.object({
  results: z.array(
    z.object({
      id: z.string().uuid(),
      screenId: z.string(),
      correct: z.boolean(),
      latencyMs: z.number().int(),
      errorCode: z.string().nullable().optional(),
      hadMiss: z.boolean().optional(),
    }),
  ),
});

export function createApi() {
  const app = new Hono<{ Variables: Variables }>().basePath("/api/v1");

  app.use("*", async (c, next) => {
    const requestId = crypto.randomUUID();
    c.header("x-request-id", requestId);
    const session = await getAuth().api.getSession({ headers: c.req.raw.headers });
    if (!session?.user) return c.json(fail("unauthorized", "Sign in required."), 401);
    c.set("userId", session.user.id);
    c.set("role", (session.user as { role?: string }).role ?? "learner");
    requestLogger(requestId, session.user.id).info({
      method: c.req.method,
      path: c.req.path,
    });
    await next();
  });

  app.get("/me", async (c) => c.json(await getLearner(c.get("userId"))));
  app.get("/profile/summary", async (c) => c.json(await profileSummary(c.get("userId"))));

  app.patch("/me", async (c) => {
    const parsed = patchMeSchema.safeParse(await c.req.json());
    if (!parsed.success) return c.json(fail("validation", "Check the profile fields."), 400);
    return c.json(await updateProfile(c.get("userId"), parsed.data));
  });

  app.get("/path", async (c) => c.json({ nodes: await getPath(c.get("userId")) }));

  app.get("/content/packs/current", async (c) => {
    const pack = await currentPack();
    if (!pack) return c.json(fail("pack_missing", "No pack is published."), 404);
    return c.json(pack.manifest);
  });

  app.get("/content/packs/:version", async (c) => {
    const pack = await packByVersion(c.req.param("version") ?? "");
    if (!pack) return c.json(fail("pack_missing", "That pack version is missing."), 404);
    return c.json(pack.body);
  });

  app.post("/attempts", async (c) => {
    const parsed = attemptSchema.safeParse(await c.req.json());
    if (!parsed.success) return c.json(fail("validation", "Lesson id is required."), 400);
    return c.json(await startAttempt(c.get("userId"), parsed.data.lessonId, parsed.data.attemptId));
  });

  app.post("/attempts/:id/results", async (c) => {
    if (!allow(c.get("userId"))) return c.json(fail("rate_limited", "Slow down a moment."), 429);
    const parsed = resultsSchema.safeParse(await c.req.json());
    if (!parsed.success) return c.json(fail("validation", "Results are invalid."), 400);
    const outcome = await applyResults(c.get("userId"), c.req.param("id") ?? "", parsed.data.results);
    if ("error" in outcome) return c.json(fail(outcome.error ?? "attempt_not_found", "Attempt not found."), 404);
    return c.json(outcome);
  });

  app.post("/attempts/:id/complete", async (c) => {
    const outcome = await completeAttempt(c.get("userId"), c.req.param("id") ?? "");
    if ("error" in outcome) return c.json(fail(outcome.error ?? "attempt_not_found", "Attempt not found."), 404);
    return c.json(outcome);
  });

  app.get("/review/queue", async (c) => c.json(await reviewQueue(c.get("userId"))));

  app.post("/placement/sessions", async (c) => c.json(await startPlacement(c.get("userId"))));

  app.post("/placement/sessions/:id/answers", async (c) => {
    const body = z.object({ correct: z.boolean() }).safeParse(await c.req.json());
    if (!body.success) return c.json(fail("validation", "Say whether the answer was correct."), 400);
    const outcome = await answerPlacement(c.get("userId"), c.req.param("id") ?? "", body.data.correct);
    if ("error" in outcome) return c.json(fail(outcome.error ?? "attempt_not_found", "Session not found."), 404);
    return c.json(outcome);
  });

  return app;
}

let apiSingleton: ReturnType<typeof createApi> | undefined;
export function getApi() {
  apiSingleton ??= createApi();
  return apiSingleton;
}

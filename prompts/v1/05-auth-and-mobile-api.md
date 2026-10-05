# 05 — Auth and mobile API

You are the API engineer. Prompts 00 through 04 are done. Add Better Auth and the versioned mobile API. Algorithms may be stubbed with pure functions that prompt 06 will replace, but idempotency and authorization must be real.

## Goal

A Flutter client can create an account, read the path, download a pack manifest, start an attempt, and submit results exactly once. An author cookie can open an admin health route. A learner cookie cannot.

## Auth

Install Better Auth and follow its current Next.js App Router guide for the mount path and database adapter. Use the Drizzle adapter against the schema from prompt 04.

Enable:

- Email and password
- Bearer plugin for mobile
- Cookie sessions for the website and admin

Add a `role` field on the user with values `learner`, `author`, `reviewer`, `admin`. Default is `learner`.

A script `pnpm admin:promote --email you@example.com --role author` updates the role. There is no public role-change endpoint.

After sign-up, create a `profiles` row and a `streaks` row in the same flow. Daily goal defaults to 5. Timezone defaults to UTC until the client patches it.

## HTTP API

Mount Hono with `@hono/zod-openapi` at `apps/web/src/app/api/v1/[[...route]]/route.ts`.

Serve Scalar API reference at `/api/v1/docs` only when `NODE_ENV !== 'production'`.

Every route declares path params, query, body, and response with Zod. Middleware:

- Request id on every response header `x-request-id`
- Bearer auth that sets `userId` and `role`, or returns 401 `{ error: { code: "unauthorized", message } }`
- In-process token bucket per user id on auth-adjacent and `results` posts. Capacity 30 per minute. The limiter is a class with `take(key): boolean` so Upstash can replace the body later without route edits.

Implement:

- Better Auth catch-all as the library requires, documented for Flutter as the sign-up, sign-in, and bearer endpoints
- `GET /api/v1/me` returns profile fields
- `PATCH /api/v1/me` accepts `displayName`, `dailyGoalMinutes`, `timezone`, `onboardingCompletedAt`
- `POST /api/v1/placement/sessions` creates a session. Until prompt 06, set `low` to 0 and `high` to the max published rank and return the first discriminative screen id if one exists, or a skill id only.
- `POST /api/v1/placement/sessions/:id/answers` records correct or wrong
- `GET /api/v1/path` returns published nodes from `topoOrder` with `rank`, `lane` from `zigzag`, `state` of `locked | available | mastered`, `title`, `promise`, `pipAbility`. Until mastery exists, state is `available` when every prerequisite is in the published set and the node has no mastery row, `locked` when a prerequisite is missing from the published set. Prompt 06 replaces the state rule.
- `GET /api/v1/content/packs/current` returns the latest manifest or 404 `pack_missing`
- `GET /api/v1/content/packs/:version` returns the pack body
- `POST /api/v1/attempts` body `{ lessonId }` returns `{ attemptId }`
- `POST /api/v1/attempts/:id/results` body `{ results: [{ id, screenId, correct, latencyMs, errorCode }] }`
- `POST /api/v1/attempts/:id/complete`
- `GET /api/v1/review/queue` returns `{ skillIds: string[] }` from due cards, empty array when none
- `GET /api/v1/profile/summary` returns streak, daily goal, and XP sum

`POST /results` rules:

- Verify the attempt belongs to the user. Otherwise 404 `attempt_not_found`.
- Insert item results with `onConflictDoNothing`.
- Write one `xp_events` row per new correct result. Amount 10. `idempotencyKey` equals the result id.
- Response includes `{ appliedIds, mastery, xpTotal }`. `mastery` may be a placeholder score until prompt 06, but `appliedIds` must list only rows inserted on this call.
- A second post of the same result id returns the same xp total and does not add a second event.

Admin health:

- `GET /api/admin/health` in a Route Handler or Server Action is unnecessary. Add `GET` page `/admin/health` that calls `auth()` on the server. Role `author` or higher sees `{ ok: true }`. Learners redirect to `/`.

## Logging and errors

Use `pino`. Each log line includes `requestId` and `userId` when known. Never log passwords, bearer tokens, or raw authorization headers.

Unexpected exceptions return 500 `{ error: { code: "internal" } }` and log the stack with the request id.

## Patterns

- Handlers call services in `src/features/*/service.ts`.
- Services call repositories with a transaction when more than one table changes.
- Services return `Result<T, ApiError>`. The Hono layer maps `Result` to status codes.
- Keep OpenAPI schemas in `src/features/*/contract.ts` and reuse them in handlers.

## Contract test

Against compose Postgres:

1. Sign up a learner through the HTTP API.
2. Insert a published lesson fixture directly through the repository.
3. Create an attempt.
4. Post one result.
5. Post the same result id again.
6. Assert one `item_results` row and one `xp_events` row.

A second test signs in as a learner and requests `/admin/health` and expects a redirect or 403. Promote the user with the script and expect success.

## Out of scope

FSRS scheduling math, the marketing pages, the full admin studio, and Flutter.

## Acceptance

- Scalar lists the mobile routes in development.
- The idempotency contract test passes.
- Role separation on `/admin/health` passes.
- Production does not expose `/api/v1/docs`.

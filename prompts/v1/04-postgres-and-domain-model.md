# 04 — Postgres and domain model

You are the backend engineer. Prompts 00 through 03 are done. Add Drizzle, migrations, repositories, and seed data. Do not add HTTP routes yet.

## Goal

A fresh database migrates and seeds the Space and Vectors worlds. Repositories are the only database gateway. A failed multi-table write rolls back.

## Libraries

Use `drizzle-orm`, `drizzle-kit`, and the `postgres` driver (postgres.js). Keep the connection string in `DATABASE_URL`.

Put the schema in `apps/web/src/server/db/schema.ts` and the client in `apps/web/src/server/db/client.ts`. Generate SQL migrations with Drizzle Kit into `apps/web/drizzle`. `pnpm db:migrate` applies them. `pnpm db:seed` runs the seed.

## Tables

Better Auth tables come in prompt 05. Leave a comment and an empty export site for them if the library is not installed yet. If you install Better Auth now, add only the tables it requires and stop before routes.

Product tables:

`profiles`

- `userId` uuid primary key
- `displayName` text
- `dailyGoalMinutes` integer, check constraint in `(5, 10, 15)`, default 5
- `timezone` text, default `UTC`
- `onboardingCompletedAt` timestamptz nullable
- `placementSkillId` uuid nullable

`worlds`

- `id` uuid primary key
- `slug` text unique
- `title` text
- `sortOrder` integer

`skill_nodes`

- `id` uuid primary key
- `worldId` uuid references worlds
- `slug` text
- `title` text
- `promise` text
- `prereqIds` uuid array, default empty
- `sortOrder` integer
- `pipAbility` text
- `status` text check in `draft`, `published`
- unique `(worldId, slug)`

`lessons`

- `id` uuid primary key
- `skillNodeId` uuid references skill_nodes
- `title` text
- `version` integer
- `status` text check in `draft`, `in_review`, `published`
- `definition` jsonb, the lesson body from the Zod schema without duplicating the id if you prefer storing the full lesson document
- unique `(skillNodeId, version)`

`content_packs`

- `id` uuid primary key
- `version` text unique
- `sha256` text
- `manifest` jsonb
- `body` jsonb, the canonical pack
- `publishedAt` timestamptz

`lesson_attempts`

- `id` uuid primary key
- `userId` uuid
- `lessonId` uuid
- `startedAt` timestamptz
- `completedAt` timestamptz nullable

`item_results`

- `id` uuid primary key, client-generated
- `attemptId` uuid references lesson_attempts
- `screenId` text
- `correct` boolean
- `latencyMs` integer
- `errorCode` text nullable
- `createdAt` timestamptz default now

`skill_mastery`

- primary key `(userId, skillNodeId)`
- `score` numeric(6, 5) default 0
- `attempts` integer default 0
- `correctCount` integer default 0
- `recent` jsonb, a two-item boolean array of the latest outcomes
- `updatedAt` timestamptz

`review_cards`

- primary key `(userId, skillNodeId)`
- `dueAt` timestamptz
- `stability` numeric
- `difficulty` numeric
- `reps` integer
- `lapses` integer
- `state` text
- `fsrs` jsonb

`streaks`

- `userId` uuid primary key
- `current` integer default 0
- `longest` integer default 0
- `lastActiveDate` date nullable
- `freezes` integer default 2

`xp_events`

- `id` uuid primary key
- `userId` uuid
- `amount` integer
- `reason` text
- `idempotencyKey` text unique
- `createdAt` timestamptz default now

`placement_sessions`

- `id` uuid primary key
- `userId` uuid
- `low` integer
- `high` integer
- `asked` integer default 0
- `recommendedSkillId` uuid nullable
- `completedAt` timestamptz nullable

`placement_answers`

- `id` uuid primary key
- `sessionId` uuid
- `skillNodeId` uuid
- `correct` boolean
- `createdAt` timestamptz

`waitlist_emails`

- `id` uuid primary key
- `email` text unique
- `createdAt` timestamptz

`audit_log`

- `id` uuid primary key
- `actorId` uuid
- `action` text
- `entity` text
- `entityId` text
- `createdAt` timestamptz

## Indexes

- `review_cards (user_id, due_at)`
- `item_results (attempt_id)`
- `xp_events (user_id, created_at)`
- `skill_nodes (world_id, sort_order)`
- `lessons (skill_node_id, status)`

## Repository pattern

Create `apps/web/src/features/<feature>/repository.ts` for content, progress, and packs.

Rules:

- Accept a Drizzle client or transaction as the first argument. Do not import the global client inside repository functions. The service layer opens the transaction and passes it in.
- Return plain domain objects, not Drizzle row types, once a mapper exists. A thin mapper in `mapper.ts` is enough.
- `insertItemResults` uses `onConflictDoNothing` on `item_results.id`.
- `insertXpEvent` uses `onConflictDoNothing` on `idempotencyKey`.
- No HTTP types, no Zod request objects inside repositories. Parse at the edge in prompt 05.

## Seed

Seed two worlds, `space` and `vectors`, with skill rows and no published lesson bodies yet. Prerequisites follow this order so prompt 13 can attach lessons:

Space: coordinate-plane, quadrants, axis-distance, closer-point, arrow-parts, equal-arrows, add-arrows, scale-arrow, arrow-length, pip-checkpoint.

Vectors: vector-pair, component-add, scalar-multiply, length-unit, dot-agreement, pattern-match, projection, matrix-numbers, matrix-vector, drawing-stretch, two-warps, eigen-direction, pip-capstone.

Each skill stores a one-sentence `promise` and a `pipAbility`. Status `published` for the nodes so the path can render titles before lessons exist. Lessons stay absent until prompt 13.

The seed is idempotent: upsert on slug.

## Test

Use a transaction that inserts an attempt and an item result, throws, and asserts the attempt is gone after rollback. Run it against the compose database. Skip cleanly with a clear message when `DATABASE_URL` is unset so default unit tests still pass on machines without Docker.

## Out of scope

Route handlers, Better Auth flows, mastery math, and admin UI.

## Acceptance

- `pnpm db:migrate` succeeds on a fresh volume.
- `pnpm db:seed` can run twice without duplicate worlds.
- The rollback test passes when Postgres is up.
- Feature code under `src/features` does not call `drizzle(` except in `src/server/db/client.ts`.

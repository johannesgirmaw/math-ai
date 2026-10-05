# 00 — How to implement Axiom

You are a staff engineer opening the Axiom repository. This file is the working agreement for every later prompt. Do not write product features in this step. Read it, then start at `01-monorepo-foundations.md`.

## Product context

Axiom trains the math that makes machine learning, robotics, and modern AI possible. The beachhead is teens and adults, roughly 14 to 35, who bounce off textbooks. Version 1 teaches Space (coordinates and arrows) and Vectors and matrices. A short adaptive placement drops a beginner at the on-ramp and a stronger learner nearer matrices.

The emotional hook is Pip, a small robot whose abilities are the skills the learner masters. Dot product lets Pip tell two patterns apart. Progress should feel like a machine getting smarter.

The habit loop is one mission of 5 to 8 screens, about 3 to 5 minutes, finishable with a thumb. Endowed progress lives on a vertical path. The learner picks a daily goal of 5, 10, or 15 minutes. A streak counts local days on which they finish a mission. Spaced review uses FSRS on the server. Weekly leagues, payments, kids accounts, and a chat tutor are out of version 1.

North star: concepts still recallable a week later. Streaks and XP support that. A feature that raises streaks while lowering delayed-quiz scores gets removed.

## Architecture you will keep

```text
prompts/                  implementation briefs
apps/web/                 Next.js: marketing, admin, API
apps/mobile/              Flutter iOS and Android
packages/content-schema/  Zod source of truth and JSON Schema
packages/algorithm-vectors/  shared fixtures for both languages
content/packs/            authored lesson JSON
design/tokens.json        color, type, space, motion
docker-compose.yml        local Postgres
```

One Next.js App Router application owns three surfaces:

- `(marketing)` public pages, Server Components
- `(admin)` authoring studio, cookie session, Server Actions for writes
- `api/v1` Hono plus `@hono/zod-openapi` for Flutter

Flutter never calls Server Actions. Admin never depends on the mobile bearer token.

Learning facts are append-only. Mastery, XP, and review dates are projections. A published content pack is immutable and addressed by sha256.

## Design patterns

Next.js:

- Feature modules at `apps/web/src/features/<feature>/{schema,repository,service}.ts`
- shadcn/ui is the only component system for the marketing site, the admin studio, and the design gallery. Import UI from `@/components/ui`. Do not add Material UI, Chakra, Mantine, or a parallel hand-rolled button kit.
- Server Components by default. Client components only for forms, tables, and previews. shadcn components that need state stay client components at the leaves. Pages that only compose them stay Server Components.
- Repositories are the only Drizzle callers.
- Domain services are pure or transactional use cases. Algorithms take data in and return data out.
- Zod at every boundary. Environment variables parsed with `@t3-oss/env-nextjs`.
- Expected business failures return a typed `Result`. Unexpected failures throw, get a request id, and go to logs and Sentry.
- API error body: `{ "error": { "code": string, "message": string, "details"?: unknown } }`

Flutter:

- Feature-first clean architecture. Dependency direction is `presentation → application → domain ← data`.
- Riverpod with code generation is the only dependency-injection and app-state system.
- The lesson player is a pure reducer: `LessonState reduce(LessonState state, LessonEvent event, Lesson lesson)`. No Flutter imports in that function.
- Interaction primitives use a strategy registry keyed by the JSON discriminant. The widget tree does not grow a switch on primitive type.
- DTOs map to domain entities at the data boundary. `freezed` and `json_serializable` for immutable values.
- `fpdart` `Either<Failure, T>` for expected failures.
- Drift plus an outbox for offline facts. The server unique-constraints the client UUID.

## Algorithms that have one specification

Implement these in TypeScript first (`06-learning-algorithms.md`). Implement grading again in Dart. Both run the same JSON fixtures.

- Skill graph as an adjacency list. Publish-time cycle detection with DFS three-coloring (white, gray, black).
- Display order with Kahn’s algorithm, tie-broken by `sortOrder`.
- Rank of a node is `1 + max(rank of prerequisites)`, or `0` when it has none.
- Zigzag lanes inside a rank: even index left, odd index right.
- Unlock when `masteryScore >= 0.8`, `attempts >= 5`, and the last two attempts are not both wrong.
- Mastery update: `score = score + 0.35 * (result - score)` with result `1` or `0`. The client sends facts. The server applies them in order.
- XP is `sum(amount)` over `xp_events`. `idempotencyKey` is unique.
- FSRS via `ts-fsrs` on the server. Auto-rate: wrong → Again, correct after a miss on that screen → Hard, correct under `easyWithinMs` → Easy, otherwise correct → Good.
- Placement is binary search on topological rank, six items maximum.
- Numeric grading uses absolute epsilon `max(1e-3, 0.02 * axisLength)` for coordinates. Dot-product answers use relative epsilon `1e-2`.

## Engineering bar

- TypeScript `strict` and Dart strict analysis. No implicit `any` on public APIs.
- No feature-flag service in version 1. Use a named constant if a behavior must be easy to find.
- Tests for every pure function against `packages/algorithm-vectors`.
- One widget test for the lesson feedback sheet.
- One API contract test that posts the same item result twice and writes one row.
- One Playwright test that publishes a pack.
- Copy is spoken English, second person, present tense. Celebrate on the mission-complete screen only.
- Secrets live in `.env` and `.env.example` documents the keys. Never commit real secrets.
- Pin libraries at the latest stable release when you implement. Do not invent a second state library, a second ORM, or a second HTTP stack.

## Out of scope for the whole v1 prompt pack

Calculus through robotics worlds, proofs, leagues, friends, payments, kids accounts, parent dashboard, camera solver, live classes, a general chat tutor, Redis as a session store, and a second FSRS implementation on the phone.

## Definition of done for this prompt

This file is present, and the implementer starts at prompt 01 with the rules above still in force.

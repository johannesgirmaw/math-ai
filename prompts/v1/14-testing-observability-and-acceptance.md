# 14 — Testing, observability, and acceptance

You are the tech lead closing version 1. Prompts 00 through 13 are done. Wire the release bar: automated tests, error reporting, product events, and a five-person playtest on the dot-product lesson.

## Goal

The team can point at CI and a playtest note and say whether version 1 is internally testable.

## Test pyramid

Keep the tests earlier prompts required, and add any that are missing.

Unit

- TypeScript pure functions and Dart graders both run `packages/algorithm-vectors` fixtures
- Cycle detection, zigzag, mastery replay, placement bounds, rating map, idempotent XP

Widget

- Feedback banner shows lesson copy
- Path renders left and right lane keys
- Mission complete shows `whyItMatters`

API

- Sign up, create attempt, post a result twice, assert one item row and one XP row
- Client-generated attempt id from prompt 12 inserts once

End to end

- Playwright admin publish from prompt 08
- Flutter integration test for onboarding, placement, path, and complete using fake repositories from prompt 11

CI from prompt 01 runs the automated list on every pull request. Playwright can be a separate job that starts Postgres and the web app. Flutter integration tests run on the CI agent without a device farm. Document any job that needs a secret and skip it when the secret is absent, with a yellow log line, except typecheck and unit tests, which always run.

## Observability

Sentry

- `@sentry/nextjs` on the server and the Next.js client
- `sentry_flutter` on the mobile app
- Release name is the git SHA injected at build time
- Send an event only when the DSN is non-empty
- A debug-only button or script can capture `Exception('axiom-sentry-check')`. Do not call it from production startup.

PostHog

- `posthog-node` for server events that matter: `pack_published`
- `posthog_flutter` for the phone
- Event names, identical spelling on both clients where both emit them:
  - `onboarding_completed`
  - `placement_completed`
  - `lesson_started`
  - `screen_checked`
  - `lesson_completed`
  - `lesson_quit`
  - `sync_failed`
- Properties: `lessonId`, `screenId`, `correct`, `latencyMs`, `skillId` where relevant
- Do not attach email, display name, or raw answers that contain free text. Version 1 answers are numeric or ids. Still avoid putting the whole answer payload on the event. `correct` and `errorCode` are enough.

Logs

- pino child loggers include `requestId` and `userId`
- Mobile logger uses the `logger` package at info in debug and warning in release
- Never log bearer tokens

## Product acceptance

All of these are true on a release build pointed at a migrated database with the version 1 pack:

- A new user signs up, sets a 5-minute goal, finishes placement, completes one on-ramp lesson and one dot-agreement lesson, and sees streak 1
- After the first sync, airplane mode opens a cached lesson and stores a result that appears once on the server after reconnect
- Publishing a pack whose skills contain a cycle fails and names the node ids
- Marketing and admin use paper, ink, and accent from `design/tokens.json`
- A Good rating produces a `dueAt` after the completion timestamp
- `/design` and `/api/v1/docs` are absent in production

## Playtest

Recruit five people from the beachhead, not from the implementation team. Each person thinks aloud on the first `dot-agreement` lesson on a phone build.

Watch for:

- They stall because the prompt is unclear
- They succeed by tapping randomly
- They cannot say, in one sentence afterward, what “agree” meant for the arrows

Write notes in `content/packs/v1/PLAYTEST.md` with one section per person: what they did, where they stalled, and the screen id. Rewrite any screen that needed a spoken paragraph, then bump the lesson version and publish a new pack. The prompt is done when the notes exist and the rewritten screens validate.

## Out of scope

Load testing for millions of users, a public app-store release, paid plans, and localized copy.

## Acceptance

- CI is green on the automated suites that do not need secrets.
- A configured non-production Sentry DSN receives the check exception when the debug action is invoked.
- `PLAYTEST.md` exists and names five sessions.
- The product acceptance list is checked off in `PLAYTEST.md` or in the pull request description that introduces this prompt.

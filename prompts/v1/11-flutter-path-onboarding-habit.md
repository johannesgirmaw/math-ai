# 11 — Flutter path, onboarding, and habit

You are the Flutter product engineer. Prompts 00 through 10 are done. Connect onboarding, placement, the vertical path, mission complete, streak, and profile to the API.

## Goal

A new account sets a daily goal, answers placement, lands on the path, finishes a lesson online, and sees Pip’s ability and streak 1.

## Flow

After sign-in, if `onboardingCompletedAt` is null, go to `/onboarding`.

Onboarding asks for a daily goal of 5, 10, or 15 minutes and a timezone. Send the device timezone from `DateTime.now().timeZoneName` only as a hint. Store an IANA name. Use the `flutter_timezone` package if you need a reliable IANA id. Patch `/api/v1/me` with the goal, timezone, and `onboardingCompletedAt`.

Then open `/placement` unless `placementSkillId` is already set.

Placement:

- `POST /api/v1/placement/sessions`
- Render the returned screen with the lesson player primitives
- `POST .../answers` with correct or wrong
- Stop when the server says `completed: true`
- Navigate to `/path`

Path `/path`:

- `GET /api/v1/path`
- Custom scroll view, one column, nodes in ascending rank
- `lane: left` offsets the node toward the left third. `lane: right` offsets toward the right third.
- A thin vertical line connects nodes in order
- States use `PathNode`: locked, available, mastered
- Only `available` nodes open a lesson. If several are available, the lowest rank opens. Others stay visible and tappable only when available.
- Mastered nodes show `PipMark` with mastered eyes and the `pipAbility` string under the title
- Locked nodes show the title at reduced emphasis and do not start an attempt

Lesson start:

- `POST /api/v1/attempts` with the lesson id from the path payload. Extend `GET /path` node JSON to include `lessonId` when a published lesson exists.
- Load the lesson body from `GET /api/v1/content/packs/current` then the pack version endpoint, and select the lesson. Cache the in-memory pack on the path controller for the session.
- Push `/lesson` with the player from prompt 10.

On finish:

- `POST /api/v1/attempts/:id/results` with the player’s per-screen facts, including client UUIDs and `hadMiss`
- `POST /api/v1/attempts/:id/complete`
- `/complete` shows `PipMark`, the lesson `whyItMatters`, the skill `pipAbility`, and the streak from the complete response. Add `streakCurrent` to the complete response in the API if it is missing.
- Primary button returns to `/path`, which refetches.

Profile `/profile`, linked from the path:

- `GET /api/v1/profile/summary`
- Shows streak, longest streak, XP total, daily goal
- Changing the daily goal patches `/me` and updates the summary

## API adjustments allowed in this prompt

Only fields the UI cannot function without:

- path node `lessonId` nullable
- placement response `{ completed, screen, skillId }`
- complete response `{ streakCurrent, xpTotal, pipAbility }`

Update the OpenAPI schemas and the contract tests so the old tests still pass.

## Patterns

- One repository per feature: `PathRepository`, `PlacementRepository`, `ProfileRepository`
- Pages watch providers. Pages do not construct Dio.
- Loading and error states use the paper theme. Error state has a retry button.
- Empty pack: path shows skill titles from `/path` and a sentence that lessons publish soon, for nodes with null `lessonId`.

## Tests

An integration-style widget test overrides repositories with fakes:

1. Goal page submits 5 minutes.
2. Placement returns one screen then completed.
3. Path returns two nodes, left and right.
4. Completing the lesson shows the Pip ability string from the fake complete response.

Assert both lanes exist by key: `path-lane-left` and `path-lane-right`.

## Out of scope

Drift, outbox, leagues, and push notifications.

## Acceptance

- The scripted widget test passes.
- Against the local API, a new user can finish onboarding, placement, and one seeded lesson and see a streak of 1 after complete.
- A locked node does not create an attempt.

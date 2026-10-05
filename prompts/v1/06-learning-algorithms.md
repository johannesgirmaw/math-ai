# 06 — Learning algorithms

You are the algorithms engineer. Prompts 00 through 05 are done. Replace placeholder mastery and placement with pure functions, projections, and shared fixtures.

## Goal

One TypeScript implementation decides mastery, review dates, placement, and mission composition. Replaying the item log reproduces the mastery snapshot. Dart will grade with the same numeric fixtures in prompt 10. This prompt does not port Dart yet. It does write the fixtures Dart will load.

## Where the code lives

Pure functions in `apps/web/src/features/learning/domain/`. No Drizzle imports in that folder.

Services in `apps/web/src/features/learning/service.ts` open transactions and call repositories.

Fixtures in `packages/algorithm-vectors/fixtures/*.json`. A Vitest runner loads every file.

## Mastery

```text
score' = score + 0.35 * (result - score)
attempts' = attempts + 1
correctCount' = correctCount + result
recent' = last two outcomes, newest at the end
```

`result` is `1` when `correct` is true, otherwise `0`. Start from score `0`, attempts `0`, recent `[]`.

`isMastered` is true when score is at least `0.8`, attempts is at least `5`, and the two values in `recent` are not `[false, false]`. If `recent` has fewer than two items, the last-two rule passes.

`applyMastery(snapshot, fact)` returns a new snapshot. It does not mutate the input.

## Review scheduling

Wrap `ts-fsrs` default parameters in `scheduleReview(card, rating, now)`.

`rateAttempt({ correct, hadMiss, latencyMs, easyWithinMs })`:

- `correct` false → `Again`
- `correct` true and `hadMiss` true → `Hard`
- `correct` true and `latencyMs <= easyWithinMs` → `Easy`
- otherwise → `Good`

`hadMiss` means the learner already received a wrong feedback on that same screen inside the attempt. The client sends it as a boolean on the result. Add the field to the API schema and `item_results` if it is missing. Default false for old rows.

The UI never shows the words Again, Hard, Good, Easy, or FSRS.

`GET /api/v1/review/queue` returns due skill ids ordered by `dueAt`, limited by the daily budget: 5-minute goal → 2 reviews, 10-minute → 4, 15-minute → 6.

On `POST /results`, after inserting new facts, update `skill_mastery` incrementally and schedule the skill’s review card from the final rating of that screen. Call `scheduleReview` only for newly inserted results.

## Placement

Published nodes have ranks from `topoRank`.

`nextPlacement({ low, high, correct })`:

- correct → next low is `mid + 1`
- wrong → next high is `mid - 1`
- `mid` is `floor((low + high) / 2)`

Stop when `asked >= 6` or `low >= high`. Recommended skill is the first node in topo order at the clamped final rank whose mastery is not mastered. If every node at that rank is mastered, walk upward to the next available node. If none exist, recommend the last node.

`POST /placement/sessions` stores `low = 0` and `high = maxRank`, returns the discriminative screen for `mid`. A discriminative screen is the last screen of the first published lesson of the skill at that rank. If the lesson is missing, return the skill id and `screen: null`.

`POST /placement/sessions/:id/answers` applies `nextPlacement`, increments `asked`, and on completion writes `profiles.placementSkillId`.

## Mission composition

`selectMission({ dueSkillIds, nextLessonScreens, budget })`:

- Budget is 5, 6, or 8 for daily goals 5, 10, and 15. Cap at 8.
- Take up to 2 due review screens first when the queue is non-empty.
- Fill the rest with `nextLessonScreens` in order.
- A learner with an empty queue receives only the path lesson screens, truncated to budget.

Expose this through `POST /attempts` by choosing the lesson for the next available path node unless the body includes `lessonId`.

## Path state

Replace the prompt 05 placeholder:

- `mastered` when `isMastered`
- `available` when not mastered and every prerequisite is mastered, or the node has no prerequisites
- `locked` otherwise

The first node a brand-new learner sees is `available`.

## Projection replay

`projectLearner(userId, tx)` loads `item_results` for that user in `createdAt`, `id` order and folds `applyMastery` per skill. A test seeds five facts, runs the incremental API path, runs `projectLearner`, and expects equal scores.

Add an admin-only function `rebuildMastery(userId)` that the later studio can call. For this prompt a unit test calling the function is enough. No admin button yet.

## XP

Keep amount 10 per newly applied correct result. `profile/summary` sums `xp_events`. Replayed idempotency keys do not change the sum.

## Streak

On attempt complete, compute the local date from `profiles.timezone` using `date-fns-tz` or an equivalent maintained library. If `lastActiveDate` is yesterday in that zone, increment `current`. If it is today, leave `current`. If it is older, set `current` to 1. Update `longest` when `current` exceeds it. Freezes stay at 2 in version 1 and are not consumed yet.

## Fixtures

Write JSON files with inputs and expected outputs for:

- a five-fact mastery sequence that crosses 0.8
- a snapshot with recent `[false, false]` that is not mastered despite a high score
- placement steps from low 0 high 7
- one example of each rating
- a two-node cycle rejected by `assertAcyclic`
- zigzag lanes for a rank of three nodes
- a mission with two due ids and six lesson screens at budget 8

Commit the fixtures. Vitest fails if an expected value drifts.

## Wire-up

`POST /results` and `GET /path` and placement routes call these functions. Delete the placeholder mastery score from prompt 05.

## Out of scope

Item-response theory, league scoring, client-side FSRS, and hand-written lesson curriculum.

## Acceptance

- Every fixture passes.
- Replay matches incremental mastery on the seeded attempt.
- A Good rating moves `dueAt` after `now`. An Again rating keeps the next due on the same local day or earlier than a Good rating from the same `now`.
- Path JSON marks a node locked when its prerequisite snapshot is not mastered.
- Posting the same result twice still yields one XP event.

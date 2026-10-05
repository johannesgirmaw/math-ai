# 12 — Offline sync and content packs

You are the mobile platform engineer. Prompts 00 through 11 are done. Lessons downloaded once play with the network off. Results reach the server once.

## Goal

After a successful online session, airplane mode still opens the cached lesson and queues the next result. Reconnecting applies that result a single time.

## Local database

Use Drift in `features/content_sync/data/local_database.dart`.

Tables:

`pack_cache`

- `version` text primary key
- `sha256` text
- `body` text, the pack JSON
- `downloadedAt` datetime

`outbox`

- `id` text primary key, the client result UUID or a UUID for other kinds
- `kind` text, version 1 uses `item_results` and `attempt_complete`
- `payload` text JSON
- `createdAt` datetime

`attempt_local`

- `id` text primary key
- `lessonId` text
- `startedAt` datetime
- `completedAt` datetime nullable

Keep the bearer token out of Drift.

## Sync worker

`SyncWorker.run()` is the only object that talks to the pack and result endpoints for background work.

Order inside one run:

1. If there is no connectivity from `connectivity_plus`, return `SyncStatus.offline`.
2. `GET /content/packs/current`.
3. If the sha256 differs from the cached row for that version, `GET /content/packs/:version` and replace the cache row.
4. Read outbox rows in `createdAt` order.
5. Post item results in batches grouped by `attemptId`.
6. Delete an outbox row only after HTTP 2xx.
7. Post attempt complete events the same way.
8. Refresh path, review queue, and profile summary into memory providers.

On timeout or 5xx, leave the row and stop the queue so order is preserved. On 4xx other than 409, log the payload id and drop the row so a poison message cannot block the queue forever. Treat 409 as success and drop the row, because the server already has the fact.

The server remains idempotent. A flaky 2xx that the client missed still converges on retry.

## Lesson start

`LessonLauncher`:

- If memory or Drift has the lesson, start it and write `attempt_local`.
- If the attempt API is reachable, also `POST /attempts` and store the server attempt id.
- If the attempt API is not reachable and a pack cache exists, create a local attempt id and queue the results against that id. Extend the API to accept a client-generated attempt id on `POST /attempts` with `onConflictDoNothing`, so the offline id becomes the server id at sync time. Update OpenAPI and the contract test.
- If there is no cache and no network, show: “The first download needs a connection.”

Do not compute the next FSRS due date on the device. Offline profile shows the last fetched streak and a note that review dates update after sync.

## UI

Path app bar shows a quiet sync glyph while `SyncWorker` runs. Failures surface a dismissible banner with retry. They do not block opening a cached lesson.

Call `SyncWorker.run()` on app start, when connectivity returns, and after a lesson complete.

## Tests

1. Insert one outbox row. Fake client fails the first post with a timeout and succeeds the second. After two `run()` calls the outbox is empty and the fake saw two attempts. Then run again and assert the fake saw no third post.
2. Seed `pack_cache` with the vector-arrow lesson. Make Dio throw on every call. Opening the lesson returns the parsed `Lesson` from Drift.
3. A 409 from the server deletes the outbox row.

## Patterns

- The player still grades on device and still emits facts. It does not know about Drift.
- `LessonLauncher` and `SyncWorker` sit in the data and application layers.
- Repositories return `Either`. The worker logs `Failure` and continues or stops according to the rules above.

## Out of scope

Background OS tasks via Workmanager. A foreground sync on launch and resume is enough for version 1.
Partial pack downloads and binary assets.

## Acceptance

- The three tests pass.
- Manual check: complete one online lesson, enable airplane mode, complete another cached lesson, disable airplane mode, and observe one new set of item results on the server.

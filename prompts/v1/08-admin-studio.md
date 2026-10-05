# 08 — Admin studio

You are the internal-tools engineer. Prompts 00 through 07 are done. Authors draft lessons. Reviewers publish an immutable pack.

## Goal

A reviewer can publish a content pack without opening the database. A published pack’s bytes stay fixed when someone later edits a draft.

## Access

The `(admin)` layout calls Better Auth on the server. Allowed roles: `author`, `reviewer`, `admin`. Everyone else redirects to `/`.

Navigation: Skills, Lessons, Publish.

## Skills

`/admin/skills` uses TanStack Table. Filter by world slug stored in the query string with `nuqs`.

`/admin/skills/[id]` edits title, promise, prerequisites, sort order, and Pip ability. React Hook Form plus the Zod `SkillNode` schema. Authors save. Show Zod issues next to fields.

Prerequisite choices are a multi-select of other skills. Saving runs `assertAcyclic` on the full node list with the pending edit applied. A cycle returns the node ids in the form error and writes nothing.

## Lessons

`/admin/lessons/new` and `/admin/lessons/[id]`.

Structured editor for the five primitives. Fields match the Zod payloads from prompt 03. A JSON pane shows `canonicalJson` of the current form state. Editing the JSON pane parses with Zod and, on success, updates the form. On failure, show the issue path and leave the last valid form state in place.

Include `whyItMatters`, screen prompts, feedback per required error code, and `easyWithinMs`.

Statuses:

- Author save keeps `draft`.
- Author action “Submit for review” sets `in_review`.
- Reviewer action “Publish” is on the publish screen, not a silent save.

Preview column: prompt text, KaTeX for substrings delimited by `$`, and the correct answer for the primitive (correct option label, slider value, target tip, target matrix, or pairs). This preview is read-only. It does not need the Flutter painter.

## Publish

`/admin/publish` is visible to `reviewer` and `admin` only. Authors see the page with an explanation that a reviewer publishes.

The action, in one database transaction:

1. Load skills and lessons in `in_review` or already `published` that the reviewer selected. Default selection is every `in_review` lesson plus currently published lessons so the pack stays complete.
2. Parse each lesson with Zod.
3. Run `assertAcyclic` on the included skills.
4. Build a pack body `{ version, skills, lessons }` using `canonicalJson`.
5. `sha256` that string.
6. Insert `content_packs` with a new version string `v` plus a monotonic integer or timestamp.
7. Set included draft and in-review lessons to `published`.
8. Insert `audit_log` with actor, action `publish_pack`, entity id of the pack.

Do not update `content_packs.body` of an existing version. Edits after publish create a new draft lesson version row. The previous pack still serves the old body.

If validation fails, return the Zod issues or the cycle ids and commit nothing.

## Patterns

- Server Actions for all writes, each calling `schema.safeParse` before the service.
- Services own the transaction.
- Client components only for the table, the form, and the JSON pane.
- Sonner toast on success: “Saved” or “Published”.
- Every control is a shadcn component from `@/components/ui`: `Button`, `Input`, `Label`, `Card`, `Sheet`, `Badge`, and `Sonner`. Add shadcn `select`, `textarea`, `dropdown-menu`, `tabs`, and `table` if the screens need them. TanStack Table renders inside the shadcn table markup. Do not style a second set of form controls.

## Playwright test

Seed or sign in through the UI as an author using a test-only password from env `E2E_AUTHOR_EMAIL` and `E2E_AUTHOR_PASSWORD`. The test setup promotes that user to author, creates a reviewer, and runs against a migrated database.

1. Author creates a valid `dragArrow` lesson and sees Saved.
2. Reviewer opens Publish and publishes.
3. Read the pack body through `GET /api/v1/content/packs/current` using a learner token or a direct repository read in the test.
4. Change the lesson draft’s target tip and publish again.
5. Assert the new manifest sha256 differs and the previous version route still returns the original target tip.

## Out of scope

A full visual lesson player in admin, collaborative editing, and asset uploads.

## Acceptance

- The Playwright test passes.
- A cyclic prerequisite edit does not persist.
- A learner visiting `/admin/skills` is redirected.
- An author visiting publish cannot complete the publish action.

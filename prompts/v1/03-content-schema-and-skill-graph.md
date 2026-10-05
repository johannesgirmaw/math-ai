# 03 — Content schema and skill graph

You are the learning-platform engineer. Prompts 00 through 02 are done. Define the lesson JSON model and the skill-graph algorithms the rest of the system will trust.

## Goal

`@axiom/content-schema` is the source of truth for worlds, skills, lessons, primitives, and pack manifests. Publish-time graph checks live here as pure functions. An example lesson parses in CI.

## Zod models

Export both the Zod objects and inferred TypeScript types. Also export JSON Schema for each top-level object so admin and future tools can validate without importing Zod.

`World`

- `id` uuid
- `slug` kebab-case
- `title`
- `sortOrder` integer

`SkillNode`

- `id` uuid
- `worldId` uuid
- `slug`
- `title`
- `promise` string, max 80 characters
- `prereqIds` uuid array
- `sortOrder` integer
- `pipAbility` string, max 80 characters
- `status` enum `draft | published`

`Screen`

- `id` string, unique inside the lesson
- `prompt` string, max 120 characters
- `primitive` discriminated union listed below
- `feedback` record of error-code string to message string, max 160 characters each
- `easyWithinMs` positive integer
- `correctMessage` string, max 160 characters

`Lesson`

- `id` uuid
- `skillNodeId` uuid
- `title`
- `version` positive integer
- `screens` array, length 5 to 8
- `capstone` boolean
- `whyItMatters` string, max 140 characters

`ContentPackManifest`

- `version` string
- `sha256` hex
- `publishedAt` ISO datetime
- `skillIds` uuid array
- `lessonIds` uuid array

## Primitives allowed in version 1

Use a Zod discriminated union on `type`.

`choice`

- `options`: `{ id, label }[]` length 2 to 4
- `correctOptionId`

`slider`

- `min`, `max`, `step` numbers, `step > 0`, `min < max`
- `correctValue` inside the range
- `tolerance` `>= 0`

`dragArrow`

- `planeWidth`, `planeHeight` positive numbers
- `start` `{ x, y }`
- `targetTip` `{ x, y }`
- `tolerance` positive number

`matrixWarp`

- `target` four numbers `a, b, c, d` for the matrix `[[a, b], [c, d]]`
- `tolerance` positive number per cell
- `initial` four numbers the learner starts from

`match`

- `left`: `{ id, label }[]`
- `right`: `{ id, label }[]`
- `pairs`: `{ leftId, rightId }[]` covering every left id once

Reject unknown primitive types. Expression entry, free drawing, and marble-on-a-curve are future primitives. Do not add them.

Every screen’s `feedback` map must include a key for each error code that primitive can return:

- choice: `wrong_option`
- slider: `too_low`, `too_high`
- dragArrow: `wrong_direction`, `wrong_length`
- matrixWarp: `wrong_cell`
- match: `incomplete`, `wrong_pair`

Add a Zod superRefine for that requirement.

## Graph algorithms

Implement these as pure functions in the schema package. No I/O.

`assertAcyclic(nodes: SkillNode[]): void`

DFS three-coloring. White means unvisited, gray means on the current stack, black means finished. A gray back-edge throws `CycleError` whose `nodeIds` lists the cycle in order. Prerequisites point at dependencies. An edge `node → prereq` is the direction you traverse for cycle detection. Self-prerequisites are cycles.

`topoOrder(nodes: SkillNode[]): SkillNode[]`

Kahn’s algorithm. Ready set is nodes with indegree zero, sorted by `sortOrder` then `id` so the result is stable. If the output length differs from the input length, throw `CycleError`.

`topoRank(nodes: SkillNode[]): Map<string, number>`

Rank is `0` when `prereqIds` is empty. Otherwise rank is `1 + max(rank of prerequisites)`. Compute ranks from the topological order so each prerequisite is already ranked.

`zigzag(nodesInRank: SkillNode[]): { nodeId: string; lane: 'left' | 'right' }[]`

Sort by `sortOrder` then `id`. Even indexes are `left`. Odd indexes are `right`.

`canonicalJson(value: unknown): string`

Stable JSON with sorted keys and no insignificant whitespace. Pack hashing in later prompts uses this function so sha256 does not depend on key order.

## Example and CI

Write `content/packs/examples/vector-arrow.json` as one valid lesson plus a tiny `nodes` array of two skills where the second depends on the first. The lesson uses `dragArrow`.

Add a test script that:

- parses every `content/packs/**/*.json` file that declares a lesson
- runs `assertAcyclic` on any sibling node list in the example
- fails CI on a schema error

Unit tests:

- two nodes that point at each other throw `CycleError` with both ids
- a chain of three nodes ranks `0`, `1`, `2`
- zigzag of four nodes alternates left, right, left, right
- a choice screen missing `wrong_option` fails validation
- a lesson with 4 screens fails validation
- `canonicalJson` emits the same string for objects constructed with different key insertion orders

## Patterns

- This package has zero dependencies on Next.js, Drizzle, or Flutter.
- Export a single public entry `src/index.ts`.
- Keep error types serializable: `name`, `message`, `nodeIds`.

## Out of scope

Database tables, HTTP, admin UI, and the full curriculum. Those are prompts 04, 05, 08, and 13.

## Acceptance

- The example file parses.
- The unit tests above pass.
- JSON Schema files are emitted into `packages/content-schema/dist/json-schema` or an equivalent committed export the admin app can import.

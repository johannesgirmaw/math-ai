# 13 — Version 1 lesson content

You are the learning designer writing JSON. Prompts 00 through 12 are done. Author the curriculum the app actually teaches.

## Goal

`content/packs/v1` contains the Space on-ramp and the Vectors and matrices lessons. The pack validates, publishes, and plays on a phone. A stranger with the prerequisite can finish screen one of the dot-product lesson without a spoken explanation.

## Voice and pedagogy

Follow `design/voice.md`.

- One new idea per screen. Prompt at most 120 characters.
- Hands first. The payload is the explanation. The prompt names what to do.
- Each lesson has 5 to 8 screens and fades support: the first screens make the correct move obvious, the last screen asks for the move with less scaffolding.
- Every screen sets `easyWithinMs`: choice 8000, slider 10000, drag 12000, matrix 12000, match 10000, unless a slower interaction needs more.
- Every required error code for that primitive has specific copy. Name the direction, the cell, or the pair that went wrong.
- The lesson `whyItMatters` is one concrete AI sentence, maximum 140 characters.
- `pipAbility` on the skill is a short capability, maximum 80 characters. Example: “Pip can tell which pattern is closer.”
- No paragraphs, no “Incorrect”, no exclamation marks in feedback.

## Files

One JSON file per skill under `content/packs/v1/<slug>.json` containing the skill metadata and its lessons array. A build script `pnpm content:validate` loads all files, checks unique ids, runs Zod, and runs `assertAcyclic` on the combined graph.

Prerequisites follow the order below. A skill depends on the skill directly before it in its world, except the first skill in the world, which has no prerequisites. `vector-pair` depends on `pip-checkpoint`.

## Space world

Minimum lesson counts:

1. `coordinate-plane` — plot a point (2 lessons)
2. `quadrants` — axes and quadrants (1)
3. `axis-distance` — distance along one axis (1)
4. `closer-point` — which point is closer to a target (2)
5. `arrow-parts` — tail and tip (2)
6. `equal-arrows` — same displacement (1)
7. `add-arrows` — tip to tail (2)
8. `scale-arrow` — make an arrow twice as long or half as long (2)
9. `arrow-length` — which arrow is longer (1)
10. `pip-checkpoint` — guide Pip to a point (1 capstone)

Use `choice`, `slider`, and `dragArrow` in this world. Include at least four `dragArrow` screens in the world.

## Vectors and matrices world

1. `vector-pair` — arrow and number pair (3)
2. `component-add` — add components (3)
3. `scalar-multiply` — scale components (3)
4. `length-unit` — length and unit direction intuition (3)
5. `dot-agreement` — dot product as how much two arrows agree (4)
6. `pattern-match` — Pip matches the closer of two simple patterns (3)
7. `projection` — shadow of one arrow on another (4)
8. `matrix-numbers` — a matrix as four numbers (2)
9. `matrix-vector` — matrix times vector warps a point (4)
10. `drawing-stretch` — a small drawing stretches with the matrix (3)
11. `two-warps` — apply one matrix, then another (3)
12. `eigen-direction` — a direction that stretches and does not turn (3)
13. `pip-capstone` — teach Pip to match patterns using dot products (1 lesson, 8 screens, `capstone: true`)

Use `matrixWarp` for matrix skills and `match` at least twice in the world. The dot-product lessons must include a screen where two arrows point the same way, a screen where they point opposite ways, and a screen where they are perpendicular.

`whyItMatters` examples you should match in specificity, while writing original sentences for each lesson:

- Dot product: a neuron’s first step is this agreement score.
- Matrix warp: a layer can stretch the input this way.
- Eigen direction: some directions only scale, and those directions structure a transformation.

## Publish

Run the admin publish flow or a seed script that calls the same Zod parser, `canonicalJson`, and pack insert used by prompt 08. The script may be `pnpm content:publish` and it must refuse a cycle.

Bundle nothing into Flutter by hand beyond the debug example from prompt 10. The app downloads the published pack.

## Review pass

Before marking done, read every prompt aloud. Split any screen that introduces two ideas. Confirm each feedback line is true for that error code.

## Acceptance

- `pnpm content:validate` passes.
- A pack version exists with a sha256.
- The Flutter app, after sync, opens the first Space lesson and the dot-agreement lesson from the downloaded pack.
- Screen one of the first dot-agreement lesson is solvable from the picture and the prompt alone.
- Lesson counts meet the minimums above.

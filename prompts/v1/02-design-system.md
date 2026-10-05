# 02 — Design system

You are the product designer and UI engineer for Axiom. Prompts 00 and 01 are done. Build one visual system for the marketing site, the admin studio, and the Flutter app.

## Goal

Paper and ink, one electric accent, type that can hold a short sentence and a piece of math, and a geometric Pip. Motion explains state changes. Reduced motion still communicates success and miss.

## Tokens

Write `design/tokens.json` as the source of hex values and numbers:

- paper `#F6F1E7`
- ink `#1C1915`
- accent `#2454FF`
- success `#1F7A4D`
- miss `#8C3A32`
- surface `#FFFCF7`
- line `#E4DCCF`
- space: 4, 8, 12, 16, 24, 32, 48
- radii: 12, 20, 28
- motion milliseconds: 120, 220, 400
- tap target minimum: 44

Headings use Fraunces. Interface text uses Outfit. Math uses a real math renderer, not a monospaced approximation.

## Web

- Load Fraunces and Outfit with `next/font`.
- Map tokens into the Tailwind v4 theme and into the shadcn CSS variables (`background`, `foreground`, `primary`, `card`, `border`, `ring`, and the rest of the shadcn token set) so every shadcn component picks up paper, ink, and accent without one-off color classes.
- shadcn is already initialized in prompt 01. Add the primitives this product needs: `button`, `input`, `label`, `card`, `sheet`, `badge`, `progress`, `separator`, `sonner`. Style them through those CSS variables and `components.json`, not by rewriting the components into a second library. The primary button variant is height 56 and radius 28. On viewports under 768px the primary button is full width.
- Marketing pages and admin screens import these files from `@/components/ui`. Feature code does not paste its own button, input, or card markup.
- Focus rings use the accent and stay visible against paper and surface.
- Add a Server Component gallery at `/design` that shows the primary and secondary buttons, a miss banner, a success banner, progress dots for step 3 of 7, and Pip in resting and mastered states. This route is for development. Block it in production by returning 404 when `NODE_ENV === 'production'`.

## Flutter

Create `apps/mobile/lib/core/ui/`:

- `AppTheme.light()` with `ColorScheme` built from the same hex values, Fraunces for headlines and Outfit for body via `google_fonts`.
- `AxiomButton` with a minimum size of 44 by 56 logical pixels, radius 28, and a loading state that disables the tap.
- `PromptText` that renders plain text and, when given a math span, renders it with `flutter_math_fork`.
- `ProgressDots` for the current screen index.
- `FeedbackBanner` with success and miss variants. The miss variant uses the miss color as a side bar and an icon, plus text. Color is never the only signal.
- `PathNode` circular marker with locked, available, and mastered visuals.
- `PipMark` drawn with `CustomPainter` or a small widget tree of rounded rectangles and two eyes. Size 64. Eye scale 0.6 at rest and 1.0 when `mastered` is true. No raster image and no Rive file in version 1.

Wrap the hello screen in `AppTheme` so the existing Axiom word uses ink on paper.

Honor `MediaQuery.disableAnimationsOf`. When animations are disabled, banners and Pip swap state immediately and still show the correct variant.

Every control exposes a `Semantics` label. Support text scale 1.6 without overflow on the gallery widgets. Use `Flexible` or wrapping text. Do not clip prompts with an ellipsis on the gallery samples.

## Voice

Write `design/voice.md`:

- Second person, present tense.
- One idea per sentence.
- Feedback names the mistake. Example: “The arrow points up. The target sits to the right.”
- No exclamation marks in feedback copy.
- Celebration copy is allowed only on the mission-complete screen.
- `whyItMatters` lines mention a concrete AI idea, such as “A neuron’s first step is this dot product.”

## Motion

- 120ms for color and press.
- 220ms for the feedback banner.
- 400ms for Pip’s eye scale.
- Use ease-out. Do not bounce wrong answers.

## Out of scope

Dark theme, Explorer (kids) tone, illustration packs, sound design files, and the lesson player itself.

## Acceptance

- `/design` and a Flutter gallery route or widget test render button, feedback banners, progress dots, and both Pip states.
- A widget test at text scale 1.6 lays out the banner without an overflow exception.
- A widget test with animations disabled still shows the miss label.
- Token hex values in Flutter and Tailwind match `design/tokens.json`.
- Production build does not serve `/design`.

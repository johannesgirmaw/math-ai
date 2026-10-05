# 10 — Flutter lesson player

You are the Flutter engineer building the core learning surface. Prompts 00 through 09 are done. The player runs from local lesson JSON. It does not need the path screen yet.

## Goal

A pure state machine drives 5 to 8 screens. Five primitive strategies grade answers on the device. Feedback copy comes from the lesson, not from hardcoded widget strings.

## Domain model

Place this in `features/lesson_player/domain/` with no Flutter imports. Use Dart 3 sealed classes and `freezed` where it reduces boilerplate.

```dart
sealed class LessonState {}

class LessonPresenting extends LessonState {
  // screenIndex, draft answer, needsAnswer
}

class LessonFeedback extends LessonState {
  // screenIndex, correct, errorCode, message
}

class LessonComplete extends LessonState {
  // correctCount, screenCount
}

sealed class LessonEvent {}

class AnswerChanged extends LessonEvent {}
class CheckPressed extends LessonEvent {}
class ContinuePressed extends LessonEvent {}
```

`LessonState reduce(LessonState state, LessonEvent event, Lesson lesson)` is a top-level pure function.

Behavior:

- `AnswerChanged` updates the draft on `LessonPresenting` and clears `needsAnswer`.
- `CheckPressed` with an empty draft sets `needsAnswer` and stays on `LessonPresenting`.
- `CheckPressed` with a draft grades the screen. A correct grade yields `LessonFeedback` with `correctMessage`. A wrong grade yields `LessonFeedback` with `feedback[errorCode]`.
- `ContinuePressed` from feedback moves to the next screen as `LessonPresenting`, or to `LessonComplete` when the graded screen was the last one.
- `correctCount` increments only when the first check on that screen is correct. A later success after a miss does not increment. Track `hadMiss` per screen index inside the state.

Grade result:

```dart
class Grade {
  final bool correct;
  final String? errorCode;
}
```

## Graders

Each primitive implements:

```dart
abstract class Grader {
  Grade grade(Primitive payload, Object? answer);
}
```

`PrimitiveRegistry` maps the JSON `type` string to a `Grader` and, in the presentation layer, to a widget builder. The reducer calls the registry. Widgets do not contain grading formulas.

Rules and epsilon values match prompt 00:

- choice: exact option id, else `wrong_option`
- slider: answer `< correct - tolerance` → `too_low`; answer `> correct + tolerance` → `too_high`; otherwise correct
- dragArrow: if the angle between the submitted vector and the target vector is greater than 25 degrees, `wrong_direction`; else if the tip distance exceeds tolerance, `wrong_length`; else correct. A zero-length answer is `wrong_length`.
- matrixWarp: any cell outside tolerance → `wrong_cell`
- match: fewer pairs than required → `incomplete`; any wrong pair → `wrong_pair`; otherwise correct

Coordinate epsilon is `max(0.001, 0.02 * max(planeWidth, planeHeight))` when the primitive does not set a tighter tolerance. Use the payload tolerance when it is present.

## JSON

Parse lesson documents with `json_serializable` DTOs that map into domain `Lesson` and `Screen` entities. Reject unknown primitive types with `Failure.validation`.

Add `whyItMatters` on the lesson entity.

## Presentation

`LessonPage` receives a `Lesson`.

Layout:

- `ProgressDots` bound to `screenIndex`
- `PromptText` for the prompt, including math spans
- The primitive widget expands in the remaining space
- `FeedbackBanner` visible only in `LessonFeedback`
- `AxiomButton` labeled Check or Continue, pinned to the bottom safe area, height 56

`dragArrow` is a `CustomPainter` plane with a draggable tip. The tail stays fixed at `start`. `matrixWarp` is a 2 by 2 grid of numeric steppers or draggable cell values. `choice` is large tap targets. `slider` shows the current value. `match` is two columns.

On first transition to a correct feedback, trigger `HapticFeedback.lightImpact` unless the user has disabled haptics in a simple boolean on the page for now. A settings screen can own that flag later.

Reduced motion: the banner appears without a slide.

The complete state is a simple callback `onFinished(LessonResult)` with per-screen `{ screenId, correct, latencyMs, errorCode, hadMiss, clientResultId }`. Generate `clientResultId` with `uuid` when the screen is first shown. Latency is the time from screen show to first `CheckPressed`.

## State management

A Riverpod notifier holds `LessonState` and delegates every change to `reduce`. The notifier may read a clock for latency. `reduce` itself takes no clock and no UUID generator. Pass those values in the event if the next state needs them, or compute latency in the notifier and store it beside the pure state. Keep `reduce` deterministic.

## Fixtures

Copy or parse the grading cases into `apps/mobile/test/fixtures/grading.json`. Include at least:

- choice correct and wrong
- slider too low, too high, and within tolerance
- drag arrow wrong direction, wrong length, and on target
- matrix one bad cell
- match incomplete and wrong pair

If `packages/algorithm-vectors` already contains these cases from prompt 06, load that JSON. If prompt 06 fixtures omit grading, add `packages/algorithm-vectors/fixtures/grading.json` now and consume it from both a tiny Dart test and the existing Vitest suite with a one-line expected grade. Do not fork two expected values.

## Tests

- Reducer: empty check, correct check, wrong check, continue, continue on the last screen, correctCount ignores a success after a miss.
- Each grader against the fixtures.
- Widget test pumps a one-screen lesson, enters a wrong choice, taps Check, and finds the lesson’s `wrong_option` string.

## Out of scope

Path scroll view, network submit, and offline cache. The page is callable with an in-memory lesson.

## Acceptance

- Analyzer is clean.
- Reducer, grader, and widget tests pass.
- A demo button on home, behind `kDebugMode`, opens the example `vector-arrow` lesson parsed from a bundled asset copied from `content/packs/examples/vector-arrow.json`.

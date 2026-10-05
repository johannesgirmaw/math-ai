import 'package:axiom/features/lesson_player/domain/lesson.dart';

/// The player is showing a screen and waiting for Check.
class LessonPresenting extends LessonState {
  const LessonPresenting({
    required this.screenIndex,
    required this.draft,
    required this.needsAnswer,
    required this.hadMiss,
    required this.correctCount,
  });

  final int screenIndex;
  final Object? draft;
  final bool needsAnswer;
  final Map<int, bool> hadMiss;
  final int correctCount;
}

/// The player is showing the lesson's feedback copy.
class LessonFeedback extends LessonState {
  const LessonFeedback({
    required this.screenIndex,
    required this.correct,
    required this.errorCode,
    required this.message,
    required this.hadMiss,
    required this.correctCount,
  });

  final int screenIndex;
  final bool correct;
  final String? errorCode;
  final String message;
  final Map<int, bool> hadMiss;
  final int correctCount;
}

/// Every screen has been checked.
class LessonComplete extends LessonState {
  const LessonComplete({
    required this.correctCount,
    required this.screenCount,
  });

  final int correctCount;
  final int screenCount;
}

/// Player state. The reducer is the only writer.
sealed class LessonState {
  const LessonState();
}

/// The draft answer changed.
class AnswerChanged extends LessonEvent {
  const AnswerChanged(this.answer);

  final Object? answer;
}

/// The learner pressed Check.
class CheckPressed extends LessonEvent {
  const CheckPressed();
}

/// The learner pressed Continue.
class ContinuePressed extends LessonEvent {
  const ContinuePressed();
}

/// An input to [reduce].
sealed class LessonEvent {
  const LessonEvent();
}

const _registry = PrimitiveRegistry();

/// Starting state for screen 0.
LessonState initialLessonState() {
  return const LessonPresenting(
    screenIndex: 0,
    draft: null,
    needsAnswer: false,
    hadMiss: <int, bool>{},
    correctCount: 0,
  );
}

bool _isEmpty(Object? draft) {
  if (draft == null) return true;
  if (draft is String && draft.isEmpty) return true;
  if (draft is List && draft.isEmpty) return true;
  return false;
}

/// Pure lesson transition. No clock and no Flutter imports.
LessonState reduce(LessonState state, LessonEvent event, Lesson lesson) {
  switch (state) {
    case LessonComplete():
      return state;
    case LessonPresenting():
      return _presenting(state, event, lesson);
    case LessonFeedback():
      return _feedback(state, event, lesson);
  }
}

LessonState _presenting(
  LessonPresenting state,
  LessonEvent event,
  Lesson lesson,
) {
  switch (event) {
    case AnswerChanged(:final answer):
      return LessonPresenting(
        screenIndex: state.screenIndex,
        draft: answer,
        needsAnswer: false,
        hadMiss: state.hadMiss,
        correctCount: state.correctCount,
      );
    case CheckPressed():
      if (_isEmpty(state.draft)) {
        return LessonPresenting(
          screenIndex: state.screenIndex,
          draft: state.draft,
          needsAnswer: true,
          hadMiss: state.hadMiss,
          correctCount: state.correctCount,
        );
      }
      final screen = lesson.screens[state.screenIndex];
      final grade = _registry.grade(screen.primitive, state.draft);
      final missed = Map<int, bool>.from(state.hadMiss);
      if (!grade.correct) missed[state.screenIndex] = true;
      final alreadyMissed = state.hadMiss[state.screenIndex] ?? false;
      final correctCount = grade.correct && !alreadyMissed
          ? state.correctCount + 1
          : state.correctCount;
      final message = grade.correct
          ? screen.correctMessage
          : screen.feedback[grade.errorCode] ?? screen.correctMessage;
      return LessonFeedback(
        screenIndex: state.screenIndex,
        correct: grade.correct,
        errorCode: grade.errorCode,
        message: message,
        hadMiss: missed,
        correctCount: correctCount,
      );
    case ContinuePressed():
      return state;
  }
}

LessonState _feedback(
  LessonFeedback state,
  LessonEvent event,
  Lesson lesson,
) {
  switch (event) {
    case ContinuePressed():
      final next = state.screenIndex + 1;
      if (next >= lesson.screens.length) {
        return LessonComplete(
          correctCount: state.correctCount,
          screenCount: lesson.screens.length,
        );
      }
      return LessonPresenting(
        screenIndex: next,
        draft: null,
        needsAnswer: false,
        hadMiss: state.hadMiss,
        correctCount: state.correctCount,
      );
    case AnswerChanged():
    case CheckPressed():
      return state;
  }
}

import 'package:axiom/features/lesson_player/domain/lesson.dart';
import 'package:axiom/features/lesson_player/domain/reducer.dart';
import 'package:flutter_test/flutter_test.dart';

Lesson _lesson() {
  return const Lesson(
    id: 'lesson',
    skillNodeId: 'skill',
    title: 'Arrows',
    version: 1,
    capstone: false,
    whyItMatters: 'An arrow is a move.',
    screens: [
      Screen(
        id: 'one',
        prompt: 'Pick the arrow.',
        primitive: ChoicePrimitive(
          options: [
            ChoiceOption(id: 'a', label: 'Right'),
            ChoiceOption(id: 'b', label: 'Left'),
          ],
          correctOptionId: 'a',
        ),
        feedback: {'wrong_option': 'The arrow points right.'},
        easyWithinMs: 8000,
        correctMessage: 'That is the arrow.',
      ),
      Screen(
        id: 'two',
        prompt: 'Pick again.',
        primitive: ChoicePrimitive(
          options: [
            ChoiceOption(id: 'a', label: 'Yes'),
            ChoiceOption(id: 'b', label: 'No'),
          ],
          correctOptionId: 'a',
        ),
        feedback: {'wrong_option': 'Try the other one.'},
        easyWithinMs: 8000,
        correctMessage: 'Yes.',
      ),
    ],
  );
}

void main() {
  final lesson = _lesson();

  test('empty check stays on the screen', () {
    final next = reduce(initialLessonState(), const CheckPressed(), lesson);
    expect(next, isA<LessonPresenting>());
    expect((next as LessonPresenting).needsAnswer, isTrue);
  });

  test('correct check shows the lesson message', () {
    final drafting = reduce(
      initialLessonState(),
      const AnswerChanged('a'),
      lesson,
    );
    final next = reduce(drafting, const CheckPressed(), lesson);
    expect(next, isA<LessonFeedback>());
    final feedback = next as LessonFeedback;
    expect(feedback.correct, isTrue);
    expect(feedback.message, 'That is the arrow.');
    expect(feedback.correctCount, 1);
  });

  test('wrong check uses the lesson feedback', () {
    final drafting = reduce(
      initialLessonState(),
      const AnswerChanged('b'),
      lesson,
    );
    final next =
        reduce(drafting, const CheckPressed(), lesson) as LessonFeedback;
    expect(next.correct, isFalse);
    expect(next.message, 'The arrow points right.');
    expect(next.correctCount, 0);
    expect(next.hadMiss[0], isTrue);
  });

  test('continue moves to the next screen', () {
    final feedback = reduce(
      reduce(initialLessonState(), const AnswerChanged('a'), lesson),
      const CheckPressed(),
      lesson,
    );
    final next = reduce(feedback, const ContinuePressed(), lesson);
    expect(next, isA<LessonPresenting>());
    expect((next as LessonPresenting).screenIndex, 1);
  });

  test('continue on the last screen completes', () {
    const onSecond = LessonPresenting(
      screenIndex: 1,
      draft: 'a',
      needsAnswer: false,
      hadMiss: {},
      correctCount: 1,
    );
    final feedback = reduce(onSecond, const CheckPressed(), lesson);
    final next = reduce(feedback, const ContinuePressed(), lesson);
    expect(next, isA<LessonComplete>());
    expect((next as LessonComplete).screenCount, 2);
  });

  test('a success after a miss does not raise correctCount', () {
    final missed = reduce(
      reduce(initialLessonState(), const AnswerChanged('b'), lesson),
      const CheckPressed(),
      lesson,
    ) as LessonFeedback;
    final retry = LessonPresenting(
      screenIndex: 0,
      draft: 'a',
      needsAnswer: false,
      hadMiss: missed.hadMiss,
      correctCount: missed.correctCount,
    );
    final next = reduce(retry, const CheckPressed(), lesson) as LessonFeedback;
    expect(next.correct, isTrue);
    expect(next.correctCount, 0);
  });
}

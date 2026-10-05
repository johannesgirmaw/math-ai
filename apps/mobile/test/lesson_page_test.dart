import 'package:axiom/features/lesson_player/domain/lesson.dart';
import 'package:axiom/features/lesson_player/presentation/lesson_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wrong choice shows the lesson feedback', (tester) async {
    const lesson = Lesson(
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
      ],
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LessonPage(lesson: lesson)),
      ),
    );
    await tester.tap(find.byKey(const Key('choice-b')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('lesson-action')));
    await tester.pump();

    expect(find.text('The arrow points right.'), findsOneWidget);
    expect(find.byKey(const Key('feedback-banner')), findsOneWidget);
  });
}

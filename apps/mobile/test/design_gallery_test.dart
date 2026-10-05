import 'package:axiom/core/ui/pip_mark.dart';
import 'package:axiom/features/lesson_player/presentation/primitive_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _miss = 'The arrow points up. The target sits to the right.';

void main() {
  testWidgets('text scale 1.6 lays out the miss banner', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Scaffold(
            body: FeedbackBanner(message: _miss, correct: false),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(_miss), findsOneWidget);
  });

  testWidgets('reduced motion still shows the miss label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Column(
              children: [
                FeedbackBanner(message: _miss, correct: false),
                PipMark(),
                PipMark(mastered: true),
                ProgressDots(count: 7, index: 2),
                AxiomButton(label: 'Check', onPressed: null),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(_miss), findsOneWidget);
    expect(find.byKey(const Key('pip-mark')), findsNWidgets(2));
    expect(find.text('Check'), findsOneWidget);
  });
}

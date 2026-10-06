import 'package:axiom/features/lesson_player/domain/lesson.dart';
import 'package:axiom/features/lesson_player/presentation/primitive_view.dart';
import 'package:axiom/features/path/domain/path_models.dart';
import 'package:axiom/features/path/presentation/complete_page.dart';
import 'package:axiom/features/path/presentation/path_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a lane change leaves the center line', (tester) async {
    const painter = PathBridgePainter(fromLeft: true, toLeft: false);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CustomPaint(painter: painter, size: Size(200, 176)),
      ),
    );
    const size = Size(200, 176);
    final path = painter.pathFor(size);
    final metric = path.computeMetrics().first;
    final start = metric.getTangentForOffset(0)!.position;
    final end = metric.getTangentForOffset(metric.length)!.position;
    expect(start.dx, lessThan(size.width / 2));
    expect(end.dx, greaterThan(size.width / 2));

    final sameLane = const PathBridgePainter(
      fromLeft: true,
      toLeft: true,
    ).pathFor(size);
    expect(sameLane.getBounds().center.dx, lessThan(size.width / 2));
  });

  testWidgets('complete screen shows the ability and XP just earned', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CompletePage(
          mission: MissionComplete(
            streakCurrent: 3,
            xpTotal: 40,
            xpAwarded: 40,
            pipAbility: 'Pip can land on a point.',
            whyItMatters: 'A point is a place a model can store.',
            skillMastered: true,
          ),
        ),
      ),
    );
    expect(find.text('Pip can land on a point.'), findsOneWidget);
    expect(find.text('+40 XP'), findsOneWidget);
    expect(find.text('Streak 3'), findsOneWidget);
    expect(
      find.text('A point is a place a model can store.'),
      findsOneWidget,
    );
  });

  testWidgets('a match pair exposes a connection', (tester) async {
    Object? draft;
    const match = MatchPrimitive(
      left: [
        ChoiceOption(id: 'l', label: 'Right 2'),
        ChoiceOption(id: 'm', label: 'Up 1'),
      ],
      right: [
        ChoiceOption(id: 'r', label: '(2, 0)'),
        ChoiceOption(id: 's', label: '(0, 1)'),
      ],
      pairs: [MatchPair(leftId: 'l', rightId: 'r')],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return buildPrimitive(
                primitive: match,
                draft: draft,
                enabled: true,
                onChanged: (value) => setState(() => draft = value),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Right 2'));
    await tester.pump();
    await tester.tap(find.text('(2, 0)'));
    await tester.pump();
    expect(
      find.bySemanticsLabel('Connected Right 2 to (2, 0)'),
      findsOneWidget,
    );
  });

  testWidgets('a vertical drag changes a matrix cell', (tester) async {
    Object? draft;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildPrimitive(
            primitive: const MatrixWarpPrimitive(
              target: [2, 0, 0, 1],
              initial: [1, 0, 0, 1],
              tolerance: 0.5,
            ),
            draft: null,
            enabled: true,
            onChanged: (value) => draft = value,
          ),
        ),
      ),
    );
    await tester.drag(
      find.byKey(const Key('matrix-cell-0')),
      const Offset(0, -48),
    );
    await tester.pump();
    expect(draft, isA<List<dynamic>>());
    expect((draft! as List<dynamic>).first, isNot(1));
  });
}

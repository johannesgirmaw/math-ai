import 'package:axiom/core/ui/app_theme.dart';
import 'package:axiom/features/lesson_player/domain/lesson.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Large bottom action used by the lesson player.
class AxiomButton extends StatelessWidget {
  const AxiomButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: FilledButton(
        key: const Key('lesson-action'),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}

/// Dots for the current screen.
class ProgressDots extends StatelessWidget {
  const ProgressDots({
    required this.count,
    required this.index,
    super.key,
  });

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${index + 1} of $count',
      child: Row(
        children: [
          for (var dot = 0; dot < count; dot++)
            Container(
              width: dot == index ? 22 : 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: dot <= index ? AxiomColors.accent : AxiomColors.line,
              ),
            ),
        ],
      ),
    );
  }
}

/// Prompt copy. Spans wrapped in `$` render as math.
class PromptText extends StatelessWidget {
  const PromptText({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineSmall;
    if (!text.contains(r'$')) {
      return Semantics(label: text, child: Text(text, style: style));
    }
    final parts = text.split(RegExp(r'(\$[^$]+\$)'));
    return Semantics(
      label: text.replaceAll(r'$', ''),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final part in parts)
            if (part.startsWith(r'$') && part.endsWith(r'$') && part.length > 2)
              Math.tex(
                part.substring(1, part.length - 1),
                textStyle: style,
              )
            else
              Text(part, style: style),
        ],
      ),
    );
  }
}

/// Feedback from the lesson document. It appears in place, without a slide.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    required this.message,
    required this.correct,
    super.key,
  });

  final String message;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final color = correct ? AxiomColors.success : AxiomColors.miss;
    return Semantics(
      label: message,
      child: Container(
        key: const Key('feedback-banner'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AxiomColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Row(
          children: [
            Icon(
              correct ? Icons.check_circle_outline : Icons.highlight_off,
              color: color,
              semanticLabel: correct ? 'Correct' : 'Miss',
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

/// Builds the primitive widget registered for this interaction.
Widget buildPrimitive({
  required Primitive primitive,
  required Object? draft,
  required ValueChanged<Object?> onChanged,
  required bool enabled,
}) {
  final builder = primitiveBuilders[primitive.type];
  if (builder == null) {
    return const Text('This interaction is not ready.');
  }
  return builder(
    primitive: primitive,
    draft: draft,
    onChanged: onChanged,
    enabled: enabled,
  );
}

typedef PrimitiveWidgetBuilder =
    Widget Function({
      required Primitive primitive,
      required Object? draft,
      required ValueChanged<Object?> onChanged,
      required bool enabled,
    });

final primitiveBuilders = <String, PrimitiveWidgetBuilder>{
  'choice': _choice,
  'slider': _slider,
  'dragArrow': _arrow,
  'matrixWarp': _matrix,
  'match': _match,
};

Widget _choice({
  required Primitive primitive,
  required Object? draft,
  required ValueChanged<Object?> onChanged,
  required bool enabled,
}) {
  final choice = primitive as ChoicePrimitive;
  return Column(
    children: [
      for (final option in choice.options)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              key: Key('choice-${option.id}'),
              onPressed: enabled ? () => onChanged(option.id) : null,
              style: OutlinedButton.styleFrom(
                backgroundColor: draft == option.id
                    ? AxiomColors.accent.withValues(alpha: 0.12)
                    : AxiomColors.surface,
                side: BorderSide(
                  color: draft == option.id
                      ? AxiomColors.accent
                      : AxiomColors.line,
                ),
              ),
              child: Text(option.label),
            ),
          ),
        ),
    ],
  );
}

Widget _slider({
  required Primitive primitive,
  required Object? draft,
  required ValueChanged<Object?> onChanged,
  required bool enabled,
}) {
  final slider = primitive as SliderPrimitive;
  final value = draft is num ? draft.toDouble() : slider.min;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value.toStringAsFixed(1)),
      Slider(
        min: slider.min,
        max: slider.max,
        divisions: ((slider.max - slider.min) / slider.step).round(),
        value: value.clamp(slider.min, slider.max),
        onChanged: enabled ? onChanged : null,
      ),
    ],
  );
}

Widget _arrow({
  required Primitive primitive,
  required Object? draft,
  required ValueChanged<Object?> onChanged,
  required bool enabled,
}) {
  final arrow = primitive as DragArrowPrimitive;
  return LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final tip = _tip(draft) ?? arrow.start;
      return GestureDetector(
        onPanUpdate: enabled
            ? (details) {
                final object = context.findRenderObject();
                if (object is! RenderBox || size.height == 0) return;
                final local = object.globalToLocal(details.globalPosition);
                onChanged({
                  'x': (local.dx / size.width) * arrow.planeWidth,
                  'y': (1 - local.dy / size.height) * arrow.planeHeight,
                });
              }
            : null,
        child: CustomPaint(
          size: size,
          painter: _ArrowPainter(arrow: arrow, tip: tip),
        ),
      );
    },
  );
}

PlanePoint? _tip(Object? draft) {
  if (draft is! Map) return null;
  final x = draft['x'];
  final y = draft['y'];
  if (x is! num || y is! num) return null;
  return PlanePoint(x: x.toDouble(), y: y.toDouble());
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.arrow, required this.tip});

  final DragArrowPrimitive arrow;
  final PlanePoint tip;

  Offset _pixel(PlanePoint point, Size size) {
    return Offset(
      point.x / arrow.planeWidth * size.width,
      size.height - point.y / arrow.planeHeight * size.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final tail = _pixel(arrow.start, size);
    final head = _pixel(tip, size);
    final target = _pixel(arrow.targetTip, size);
    final guideStart = arrow.guideStart;
    final guideTip = arrow.guideTip;
    if (guideStart != null && guideTip != null) {
      final guideTail = _pixel(guideStart, size);
      final guideHead = _pixel(guideTip, size);
      canvas
        ..drawLine(
          guideTail,
          guideHead,
          Paint()
            ..color = AxiomColors.ink.withValues(alpha: 0.35)
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        )
        ..drawCircle(
          guideHead,
          6,
          Paint()..color = AxiomColors.ink.withValues(alpha: 0.45),
        );
    }
    canvas
      ..drawCircle(target, 8, Paint()..color = AxiomColors.line)
      ..drawLine(
        tail,
        head,
        Paint()
          ..color = AxiomColors.accent
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(head, 10, Paint()..color = AxiomColors.ink);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.tip.x != tip.x || oldDelegate.tip.y != tip.y;
  }
}

Widget _matrix({
  required Primitive primitive,
  required Object? draft,
  required ValueChanged<Object?> onChanged,
  required bool enabled,
}) {
  final matrix = primitive as MatrixWarpPrimitive;
  final cells = draft is List
      ? draft.map((cell) => cell is num ? cell.toDouble() : 0.0).toList()
      : List<double>.from(matrix.initial);
  return Column(
    children: [
      if (matrix.showTarget)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Target ${matrix.target[0].toStringAsFixed(0)}, ${matrix.target[1].toStringAsFixed(0)} / ${matrix.target[2].toStringAsFixed(0)}, ${matrix.target[3].toStringAsFixed(0)}',
          ),
        ),
      for (var row = 0; row < 2; row++)
        Row(
          children: [
            for (var column = 0; column < 2; column++)
              _cell(
                cells: cells,
                index: row * 2 + column,
                enabled: enabled,
                onChanged: onChanged,
              ),
          ],
        ),
    ],
  );
}

Widget _cell({
  required List<double> cells,
  required int index,
  required bool enabled,
  required ValueChanged<Object?> onChanged,
}) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(cells[index].toStringAsFixed(1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: enabled
                    ? () {
                        final next = List<double>.from(cells);
                        next[index] = next[index] - 1;
                        onChanged(next);
                      }
                    : null,
                icon: const Icon(Icons.remove),
              ),
              IconButton(
                onPressed: enabled
                    ? () {
                        final next = List<double>.from(cells);
                        next[index] = next[index] + 1;
                        onChanged(next);
                      }
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _match({
  required Primitive primitive,
  required Object? draft,
  required ValueChanged<Object?> onChanged,
  required bool enabled,
}) {
  final match = primitive as MatchPrimitive;
  final pairs = _pairs(draft);
  final pending = draft is Map ? draft['pendingLeft'] : null;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _column(match.left, enabled, (id) {
        onChanged({'pendingLeft': id, 'pairs': _encode(pairs)});
      })),
      Expanded(child: _column(match.right, enabled, (id) {
        if (pending is! String) return;
        final next = [...pairs, MatchPair(leftId: pending, rightId: id)];
        onChanged({'pairs': _encode(next)});
      })),
    ],
  );
}

Widget _column(
  List<ChoiceOption> options,
  bool enabled,
  ValueChanged<String> onTap,
) {
  return Column(
    children: [
      for (final option in options)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            onPressed: enabled ? () => onTap(option.id) : null,
            child: Text(option.label),
          ),
        ),
    ],
  );
}

List<MatchPair> _pairs(Object? draft) {
  final raw = draft is Map ? draft['pairs'] : draft;
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map && item['leftId'] is String && item['rightId'] is String)
        MatchPair(
          leftId: item['leftId'] as String,
          rightId: item['rightId'] as String,
        ),
  ];
}

List<Map<String, String>> _encode(List<MatchPair> pairs) {
  return [
    for (final pair in pairs) {'leftId': pair.leftId, 'rightId': pair.rightId},
  ];
}

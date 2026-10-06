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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: count == 0 ? 0 : (index + 1) / count,
          minHeight: 12,
          backgroundColor: AxiomColors.line,
          color: AxiomColors.accent,
        ),
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
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? 1 : 0, end: 1),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Semantics(
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
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (choice.arrows.isNotEmpty || choice.score != null)
        SizedBox(
          height: 160,
          child: CustomPaint(
            painter: _ScenePainter(arrows: choice.arrows, score: choice.score),
            child: const SizedBox.expand(),
          ),
        ),
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
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: 72,
        child: CustomPaint(
          painter: _NumberLinePainter(
            min: slider.min,
            max: slider.max,
            value: value,
          ),
          child: const SizedBox.expand(),
        ),
      ),
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
    _paintPlane(canvas, size);
    final tail = _pixel(arrow.start, size);
    final head = _pixel(tip, size);
    final target = _pixel(arrow.targetTip, size);
    final guideStart = arrow.guideStart;
    final guideTip = arrow.guideTip;
    if (guideStart != null && guideTip != null) {
      _paintArrow(
        canvas,
        _pixel(guideStart, size),
        _pixel(guideTip, size),
        AxiomColors.ink.withValues(alpha: 0.35),
      );
    }
    canvas.drawCircle(
      target,
      10,
      Paint()
        ..color = AxiomColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    _paintArrow(canvas, tail, head, AxiomColors.accent);
    canvas.drawCircle(head, 10, Paint()..color = AxiomColors.ink);
    _paintScore(canvas, size, arrow.score);
  }

  void _paintPlane(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AxiomColors.line
      ..strokeWidth = 1;
    const lines = 10;
    for (var i = 0; i <= lines; i++) {
      final x = size.width * i / lines;
      final y = size.height * i / lines;
      canvas
        ..drawLine(Offset(x, 0), Offset(x, size.height), grid)
        ..drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final origin = Offset(0, size.height);
    final axis = Paint()
      ..color = AxiomColors.ink.withValues(alpha: 0.45)
      ..strokeWidth = 2;
    canvas
      ..drawLine(Offset(0, origin.dy), Offset(size.width, origin.dy), axis)
      ..drawLine(Offset(origin.dx, 0), Offset(origin.dx, size.height), axis);
  }

  void _paintArrow(Canvas canvas, Offset tail, Offset head, Color color) {
    canvas.drawLine(
      tail,
      head,
      Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    final angle = (head - tail).direction;
    const wing = 12.0;
    canvas
      ..drawLine(
        head,
        head + Offset.fromDirection(angle + 2.6, wing),
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      )
      ..drawLine(
        head,
        head + Offset.fromDirection(angle - 2.6, wing),
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
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
      SizedBox(
        height: 140,
        width: double.infinity,
        child: CustomPaint(
          painter: _WarpPainter(
            cells: cells.length == 4 ? cells : matrix.initial,
            target: matrix.showTarget ? matrix.target : null,
          ),
          child: const SizedBox.expand(),
        ),
      ),
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
  String? partner(String leftId) {
    for (final pair in pairs) {
      if (pair.leftId == leftId) return pair.rightId;
    }
    return null;
  }

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          children: [
            for (final option in match.left)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: pending == option.id
                          ? AxiomColors.accent
                          : AxiomColors.line,
                      width: pending == option.id ? 2 : 1,
                    ),
                  ),
                  onPressed: enabled
                      ? () => onChanged({
                          'pendingLeft': option.id,
                          'pairs': _encode(pairs),
                        })
                      : null,
                  child: Text(_pairLabel(option, partner(option.id), match)),
                ),
              ),
          ],
        ),
      ),
      Expanded(
        child: Column(
          children: [
            for (final option in match.right)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor:
                        pairs.any((pair) => pair.rightId == option.id)
                        ? AxiomColors.line
                        : null,
                  ),
                  onPressed: enabled
                      ? () {
                          if (pending is! String) return;
                          final next = [
                            ...pairs.where((pair) => pair.leftId != pending),
                            MatchPair(leftId: pending, rightId: option.id),
                          ];
                          onChanged({'pairs': _encode(next)});
                        }
                      : null,
                  child: Text(option.label),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

String _pairLabel(ChoiceOption option, String? rightId, MatchPrimitive match) {
  if (rightId == null) return option.label;
  final right = match.right.where((item) => item.id == rightId);
  final label = right.isEmpty ? option.label : right.first.label;
  return '${option.label} → $label';
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

void _paintScore(Canvas canvas, Size size, String? score) {
  if (score == null) return;
  final label = score == 'positive'
      ? '+'
      : score == 'negative'
      ? '−'
      : '0';
  final color = score == 'positive'
      ? AxiomColors.success
      : score == 'negative'
      ? AxiomColors.miss
      : AxiomColors.ink;
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: color,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, Offset(size.width - painter.width - 8, 8));
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter({required this.arrows, required this.score});

  final List<SceneArrow> arrows;
  final String? score;

  Offset _pixel(PlanePoint point, Size size) {
    return Offset(
      point.x / 10 * size.width,
      size.height - point.y / 10 * size.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AxiomColors.line
      ..strokeWidth = 1;
    for (var i = 0; i <= 10; i++) {
      canvas
        ..drawLine(
          Offset(size.width * i / 10, 0),
          Offset(size.width * i / 10, size.height),
          grid,
        )
        ..drawLine(
          Offset(0, size.height * i / 10),
          Offset(size.width, size.height * i / 10),
          grid,
        );
    }
    for (final arrow in arrows) {
      final color = arrow.guide
          ? AxiomColors.ink.withValues(alpha: 0.35)
          : AxiomColors.accent;
      final tail = _pixel(arrow.start, size);
      final head = _pixel(arrow.tip, size);
      canvas
        ..drawLine(
          tail,
          head,
          Paint()
            ..color = color
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        )
        ..drawCircle(head, 6, Paint()..color = color);
    }
    _paintScore(canvas, size, score);
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) => false;
}

class _NumberLinePainter extends CustomPainter {
  const _NumberLinePainter({
    required this.min,
    required this.max,
    required this.value,
  });

  final double min;
  final double max;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final line = Paint()
      ..color = AxiomColors.ink
      ..strokeWidth = 2;
    canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), line);
    final span = max - min;
    final t = span == 0 ? 0.5 : ((value - min) / span).clamp(0.0, 1.0);
    final x = 12 + t * (size.width - 24);
    canvas.drawCircle(Offset(x, y), 8, Paint()..color = AxiomColors.accent);
  }

  @override
  bool shouldRepaint(covariant _NumberLinePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _WarpPainter extends CustomPainter {
  const _WarpPainter({required this.cells, this.target});

  final List<double> cells;
  final List<double>? target;

  Offset _map(double x, double y, List<double> matrix, Size size) {
    final nx = matrix[0] * x + matrix[1] * y;
    final ny = matrix[2] * x + matrix[3] * y;
    return Offset(
      size.width / 2 + nx * size.width * 0.18,
      size.height / 2 - ny * size.height * 0.28,
    );
  }

  void _square(Canvas canvas, List<double> matrix, Size size, Color color) {
    const corners = [(-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0)];
    final path = Path()
      ..moveTo(
        _map(corners[0].$1, corners[0].$2, matrix, size).dx,
        _map(corners[0].$1, corners[0].$2, matrix, size).dy,
      );
    for (final corner in corners.skip(1)) {
      final point = _map(corner.$1, corner.$2, matrix, size);
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _square(canvas, const [1, 0, 0, 1], size, AxiomColors.line);
    final shown = target;
    if (shown != null && shown.length == 4) {
      _square(canvas, shown, size, AxiomColors.ink.withValues(alpha: 0.35));
    }
    if (cells.length == 4) {
      _square(canvas, cells, size, AxiomColors.accent);
    }
  }

  @override
  bool shouldRepaint(covariant _WarpPainter oldDelegate) {
    return oldDelegate.cells != cells;
  }
}

import 'dart:async';

import 'package:axiom/core/ui/app_theme.dart';
import 'package:axiom/features/lesson_player/domain/lesson.dart';
import 'package:axiom/features/lesson_player/presentation/toy_widgets.dart';
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
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
          color: AxiomColors.gold,
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
      return Semantics(
        label: text,
        child: Text(text, style: style),
      );
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
  bool settle = false,
  bool miss = false,
}) {
  if (primitive.type == 'dragArrow') {
    return _arrow(
      primitive: primitive,
      draft: draft,
      onChanged: onChanged,
      enabled: enabled,
      settle: settle,
      miss: miss,
    );
  }
  final builder = primitiveBuilders[primitive.type];
  if (builder == null) {
    return const Text('This interaction is not ready.');
  }
  return builder(
    primitive: primitive,
    draft: draft,
    onChanged: onChanged,
    enabled: enabled,
    settle: settle,
  );
}

typedef PrimitiveWidgetBuilder =
    Widget Function({
      required Primitive primitive,
      required Object? draft,
      required ValueChanged<Object?> onChanged,
      required bool enabled,
      bool settle,
    });

final primitiveBuilders = <String, PrimitiveWidgetBuilder>{
  'choice': _choice,
  'slider': _slider,
  'matrixWarp': _matrix,
  'match': _match,
  'meter': buildMeter,
  'sheet': buildSheet,
  'hill': buildHill,
  'bag': buildBag,
  'beam': buildBeam,
};

Widget _choice({
  required Primitive primitive,
  required Object? draft,
  required ValueChanged<Object?> onChanged,
  required bool enabled,
  bool settle = false,
}) {
  final choice = primitive as ChoicePrimitive;
  final scene = choice.arrows.isNotEmpty || choice.score != null;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (scene)
        Expanded(
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
  bool settle = false,
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
  bool settle = false,
  bool miss = false,
}) {
  return _ArrowSurface(
    arrow: primitive as DragArrowPrimitive,
    draft: draft,
    onChanged: onChanged,
    enabled: enabled,
    settle: settle,
    miss: miss,
  );
}

class _ArrowSurface extends StatefulWidget {
  const _ArrowSurface({
    required this.arrow,
    required this.draft,
    required this.onChanged,
    required this.enabled,
    required this.settle,
    required this.miss,
  });

  final DragArrowPrimitive arrow;
  final Object? draft;
  final ValueChanged<Object?> onChanged;
  final bool enabled;
  final bool settle;
  final bool miss;

  @override
  State<_ArrowSurface> createState() => _ArrowSurfaceState();
}

class _ArrowSurfaceState extends State<_ArrowSurface>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _bounce;
  PlanePoint? _from;
  bool _home = false;
  final List<PlanePoint> _trail = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(covariant _ArrowSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settle && !oldWidget.settle) {
      _from = _tip(oldWidget.draft) ?? _tip(widget.draft) ?? widget.arrow.start;
      _home = false;
      final reduce = MediaQuery.disableAnimationsOf(context);
      if (reduce) {
        _controller.value = 1;
        _bounce.value = 1;
      } else {
        unawaited(_controller.forward(from: 0));
        unawaited(_bounce.forward(from: 0));
      }
    }
    if (widget.miss && !oldWidget.miss) {
      _from = _tip(oldWidget.draft) ?? _tip(widget.draft) ?? widget.arrow.start;
      _home = true;
      final reduce = MediaQuery.disableAnimationsOf(context);
      if (reduce) {
        _controller.value = 1;
      } else {
        unawaited(_controller.forward(from: 0));
      }
    }
    if (!widget.settle && !widget.miss) {
      _from = null;
      _home = false;
      _controller.value = 0;
      _bounce.value = 0;
      if (widget.draft == null) _trail.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _bounce.dispose();
    super.dispose();
  }

  PlanePoint _shown(double t) {
    final live = _tip(widget.draft) ?? widget.arrow.start;
    final from = _from;
    if ((!widget.settle && !_home) || from == null) return live;
    final eased = Curves.easeOutBack.transform(t.clamp(0, 1));
    final target = _home ? widget.arrow.start : widget.arrow.targetTip;
    return PlanePoint(
      x: from.x + (target.x - from.x) * eased,
      y: from.y + (target.y - from.y) * eased,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _bounce]),
      builder: (context, _) {
        final tip = _shown(_controller.value);
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final label =
                'Arrow tip ${tip.x.toStringAsFixed(1)}, '
                '${tip.y.toStringAsFixed(1)}';
            return Semantics(
              label: label,
              child: GestureDetector(
                onPanUpdate: widget.enabled
                    ? (details) {
                        final object = context.findRenderObject();
                        if (object is! RenderBox || size.height == 0) return;
                        final local = object.globalToLocal(
                          details.globalPosition,
                        );
                        final width = widget.arrow.planeWidth;
                        final height = widget.arrow.planeHeight;
                        final next = PlanePoint(
                          x: (local.dx / size.width) * width,
                          y: (1 - local.dy / size.height) * height,
                        );
                        _trail.add(next);
                        if (_trail.length > 18) _trail.removeAt(0);
                        widget.onChanged({'x': next.x, 'y': next.y});
                      }
                    : null,
                child: CustomPaint(
                  size: size,
                  painter: _ArrowPainter(
                    arrow: widget.arrow,
                    tip: tip,
                    trail: List<PlanePoint>.from(_trail),
                    miss: widget.miss,
                    bounce: widget.settle ? _bounce.value : 0,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

PlanePoint? _tip(Object? draft) {
  if (draft is! Map) return null;
  final x = draft['x'];
  final y = draft['y'];
  if (x is! num || y is! num) return null;
  return PlanePoint(x: x.toDouble(), y: y.toDouble());
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({
    required this.arrow,
    required this.tip,
    required this.trail,
    required this.miss,
    required this.bounce,
  });

  final DragArrowPrimitive arrow;
  final PlanePoint tip;
  final List<PlanePoint> trail;
  final bool miss;
  final double bounce;

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
    for (var index = 0; index < trail.length; index++) {
      final fade = (index + 1) / trail.length;
      canvas.drawCircle(
        _pixel(trail[index], size),
        3 + bounce * 4,
        Paint()
          ..color = (miss ? AxiomColors.miss : AxiomColors.accent).withValues(
            alpha: 0.15 + 0.35 * fade,
          ),
      );
    }
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
    if (arrow.showTarget) {
      canvas.drawCircle(
        target,
        10,
        Paint()
          ..color = AxiomColors.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    _paintArrow(canvas, tail, head, AxiomColors.accent);
    canvas.drawCircle(head, 10 + bounce * 6, Paint()..color = AxiomColors.ink);
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
    return oldDelegate.tip.x != tip.x ||
        oldDelegate.tip.y != tip.y ||
        oldDelegate.bounce != bounce ||
        oldDelegate.trail.length != trail.length;
  }
}

Widget _matrix({
  required Primitive primitive,
  required Object? draft,
  required ValueChanged<Object?> onChanged,
  required bool enabled,
  bool settle = false,
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
          GestureDetector(
            key: Key('matrix-cell-$index'),
            onVerticalDragUpdate: enabled
                ? (details) {
                    final next = List<double>.from(cells);
                    next[index] = next[index] - details.delta.dy / 24;
                    onChanged(next);
                  }
                : null,
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: Center(child: Text(cells[index].toStringAsFixed(1))),
            ),
          ),
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
  bool settle = false,
}) {
  return _MatchBoard(
    match: primitive as MatchPrimitive,
    draft: draft,
    onChanged: onChanged,
    enabled: enabled,
  );
}

class _MatchBoard extends StatefulWidget {
  const _MatchBoard({
    required this.match,
    required this.draft,
    required this.onChanged,
    required this.enabled,
  });

  final MatchPrimitive match;
  final Object? draft;
  final ValueChanged<Object?> onChanged;
  final bool enabled;

  @override
  State<_MatchBoard> createState() => _MatchBoardState();
}

class _MatchBoardState extends State<_MatchBoard> {
  final GlobalKey _boardKey = GlobalKey();
  late final List<GlobalKey> _leftKeys = [
    for (final _ in widget.match.left) GlobalKey(),
  ];
  late final List<GlobalKey> _rightKeys = [
    for (final _ in widget.match.right) GlobalKey(),
  ];

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final pairs = _pairs(draft);
    final pending = draft is Map ? draft['pendingLeft'] : null;
    return Stack(
      key: _boardKey,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _PairLinkPainter(
                pairs: pairs,
                left: widget.match.left,
                right: widget.match.right,
                leftKeys: _leftKeys,
                rightKeys: _rightKeys,
                boardKey: _boardKey,
              ),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (var index = 0; index < widget.match.left.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton(
                        key: _leftKeys[index],
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: pending == widget.match.left[index].id
                                ? AxiomColors.accent
                                : AxiomColors.line,
                            width: pending == widget.match.left[index].id
                                ? 2
                                : 1,
                          ),
                        ),
                        onPressed: widget.enabled
                            ? () => widget.onChanged({
                                'pendingLeft': widget.match.left[index].id,
                                'pairs': _encode(pairs),
                              })
                            : null,
                        child: Text(widget.match.left[index].label),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < widget.match.right.length;
                    index++
                  )
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton(
                        key: _rightKeys[index],
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              _paired(
                                pairs,
                                widget.match.right[index].id,
                              )
                              ? AxiomColors.line
                              : null,
                        ),
                        onPressed: widget.enabled
                            ? () {
                                if (pending is! String) return;
                                final next = [
                                  ...pairs.where(
                                    (pair) => pair.leftId != pending,
                                  ),
                                  MatchPair(
                                    leftId: pending,
                                    rightId: widget.match.right[index].id,
                                  ),
                                ];
                                widget.onChanged({'pairs': _encode(next)});
                              }
                            : null,
                        child: Text(widget.match.right[index].label),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        for (final pair in pairs)
          Semantics(
            label: _connectionLabel(pair, widget.match),
            container: true,
            child: const SizedBox.shrink(),
          ),
      ],
    );
  }
}

bool _paired(List<MatchPair> pairs, String rightId) {
  return pairs.any((pair) => pair.rightId == rightId);
}

String _connectionLabel(MatchPair pair, MatchPrimitive match) {
  final left = match.left.where((item) => item.id == pair.leftId);
  final right = match.right.where((item) => item.id == pair.rightId);
  final leftLabel = left.isEmpty ? pair.leftId : left.first.label;
  final rightLabel = right.isEmpty ? pair.rightId : right.first.label;
  return 'Connected $leftLabel to $rightLabel';
}

class _PairLinkPainter extends CustomPainter {
  const _PairLinkPainter({
    required this.pairs,
    required this.left,
    required this.right,
    required this.leftKeys,
    required this.rightKeys,
    required this.boardKey,
  });

  final List<MatchPair> pairs;
  final List<ChoiceOption> left;
  final List<ChoiceOption> right;
  final List<GlobalKey> leftKeys;
  final List<GlobalKey> rightKeys;
  final GlobalKey boardKey;

  @override
  void paint(Canvas canvas, Size size) {
    final board = boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (board == null || !board.hasSize) return;
    final paint = Paint()
      ..color = AxiomColors.ink
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final pair in pairs) {
      final leftIndex = left.indexWhere((item) => item.id == pair.leftId);
      final rightIndex = right.indexWhere((item) => item.id == pair.rightId);
      if (leftIndex < 0 || rightIndex < 0) continue;
      final leftBox =
          leftKeys[leftIndex].currentContext?.findRenderObject() as RenderBox?;
      final rightBox =
          rightKeys[rightIndex].currentContext?.findRenderObject()
              as RenderBox?;
      if (leftBox == null ||
          rightBox == null ||
          !leftBox.hasSize ||
          !rightBox.hasSize) {
        continue;
      }
      final start = board.globalToLocal(
        leftBox.localToGlobal(
          Offset(leftBox.size.width, leftBox.size.height / 2),
        ),
      );
      final end = board.globalToLocal(
        rightBox.localToGlobal(Offset(0, rightBox.size.height / 2)),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PairLinkPainter oldDelegate) => true;
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

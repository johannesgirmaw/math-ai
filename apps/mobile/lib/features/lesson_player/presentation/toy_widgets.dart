import 'dart:math' as math;

import 'package:axiom/core/ui/app_theme.dart';
import 'package:axiom/features/lesson_player/domain/lesson.dart';
import 'package:flutter/material.dart';

Widget buildMeter({
  required Primitive primitive,
  required Object? draft,
  required ValueChanged<Object?> onChanged,
  required bool enabled,
  bool settle = false,
}) {
  return _MeterToy(meter: primitive as MeterPrimitive, draft: draft, onChanged: onChanged, enabled: enabled, settle: settle);
}

Widget buildSheet({
  required Primitive primitive,
  required Object? draft,
  required ValueChanged<Object?> onChanged,
  required bool enabled,
  bool settle = false,
}) {
  return _SheetToy(sheet: primitive as SheetPrimitive, draft: draft, onChanged: onChanged, enabled: enabled, settle: settle);
}

Widget buildHill({
  required Primitive primitive,
  required Object? draft,
  required ValueChanged<Object?> onChanged,
  required bool enabled,
  bool settle = false,
}) {
  return _HillToy(hill: primitive as HillPrimitive, draft: draft, onChanged: onChanged, enabled: enabled, settle: settle);
}

Widget buildBag({
  required Primitive primitive,
  required Object? draft,
  required ValueChanged<Object?> onChanged,
  required bool enabled,
  bool settle = false,
}) {
  return _BagToy(bag: primitive as BagPrimitive, draft: draft, onChanged: onChanged, enabled: enabled, settle: settle);
}

Widget buildBeam({
  required Primitive primitive,
  required Object? draft,
  required ValueChanged<Object?> onChanged,
  required bool enabled,
  bool settle = false,
}) {
  return _BeamToy(beam: primitive as BeamPrimitive, draft: draft, onChanged: onChanged, enabled: enabled, settle: settle);
}

class _MeterToy extends StatelessWidget {
  const _MeterToy({
    required this.meter,
    required this.draft,
    required this.onChanged,
    required this.enabled,
    required this.settle,
  });

  final MeterPrimitive meter;
  final Object? draft;
  final ValueChanged<Object?> onChanged;
  final bool enabled;
  final bool settle;

  @override
  Widget build(BuildContext context) {
    final tip = _point(draft) ?? meter.start;
    final gx = meter.guideTip.x - meter.guideStart.x;
    final gy = meter.guideTip.y - meter.guideStart.y;
    final dx = tip.x - meter.start.x;
    final dy = tip.y - meter.start.y;
    final scale = math.sqrt(gx * gx + gy * gy) * math.sqrt(dx * dx + dy * dy);
    final agree = scale == 0 ? 0.0 : ((gx * dx + gy * dy) / scale).clamp(-1.0, 1.0);
    final glow = agree > 0.35
        ? AxiomColors.success
        : agree < -0.35
        ? AxiomColors.miss
        : AxiomColors.line;
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onPanUpdate: enabled
                    ? (details) {
                        final box = context.findRenderObject();
                        if (box is! RenderBox) return;
                        final local = box.globalToLocal(details.globalPosition);
                        onChanged({
                          'x': (local.dx / size.width) * 10,
                          'y': (1 - local.dy / size.height) * 10,
                        });
                      }
                    : null,
                child: CustomPaint(
                  size: size,
                  painter: _MeterPainter(meter: meter, tip: settle ? meter.targetTip : tip, glow: glow),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (agree + 1) / 2,
            minHeight: 14,
            backgroundColor: AxiomColors.line,
            color: glow,
          ),
        ),
        const SizedBox(height: 6),
        Text(agree > 0.35 ? 'They agree' : agree < -0.35 ? 'They oppose' : 'No shared aim'),
      ],
    );
  }
}

class _MeterPainter extends CustomPainter {
  const _MeterPainter({required this.meter, required this.tip, required this.glow});

  final MeterPrimitive meter;
  final PlanePoint tip;
  final Color glow;

  Offset _px(PlanePoint point, Size size) =>
      Offset(point.x / 10 * size.width, size.height - point.y / 10 * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AxiomColors.line
      ..strokeWidth = 1;
    for (var i = 0; i <= 10; i++) {
      final x = size.width * i / 10;
      final y = size.height * i / 10;
      canvas
        ..drawLine(Offset(x, 0), Offset(x, size.height), grid)
        ..drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    _arrow(canvas, _px(meter.guideStart, size), _px(meter.guideTip, size), AxiomColors.ink.withValues(alpha: 0.35));
    _arrow(canvas, _px(meter.start, size), _px(tip, size), glow);
  }

  void _arrow(Canvas canvas, Offset tail, Offset head, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tail, head, paint);
    canvas.drawCircle(head, 8, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MeterPainter oldDelegate) => oldDelegate.tip != tip || oldDelegate.glow != glow;
}

class _SheetToy extends StatefulWidget {
  const _SheetToy({
    required this.sheet,
    required this.draft,
    required this.onChanged,
    required this.enabled,
    required this.settle,
  });

  final SheetPrimitive sheet;
  final Object? draft;
  final ValueChanged<Object?> onChanged;
  final bool enabled;
  final bool settle;

  @override
  State<_SheetToy> createState() => _SheetToyState();
}

class _SheetToyState extends State<_SheetToy> {
  int? _handle;

  List<double> get _cells {
    final draft = widget.draft;
    if (draft is List && draft.length == 4) {
      return [for (final cell in draft) cell is num ? cell.toDouble() : 0];
    }
    if (widget.settle) return widget.sheet.target;
    return widget.sheet.initial;
  }

  void _drag(Offset delta) {
    if (_handle == null || !widget.enabled) return;
    final cells = List<double>.from(_cells);
    final dx = delta.dx / 42;
    final dy = -delta.dy / 42;
    if (_handle == 0) {
      cells[0] = (cells[0] + dx).clamp(-1, 3);
      cells[2] = (cells[2] + dy).clamp(-1, 3);
    } else {
      cells[1] = (cells[1] + dx).clamp(-1, 3);
      cells[3] = (cells[3] + dy).clamp(-1, 3);
    }
    widget.onChanged(cells);
  }

  @override
  Widget build(BuildContext context) {
    final cells = _cells;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final origin = Offset(size.width / 2, size.height / 2);
        Offset map(double x, double y) => origin + Offset(x * 42, -y * 42);
        final right = map(cells[0], cells[2]);
        final up = map(cells[1], cells[3]);
        return GestureDetector(
          onPanStart: (details) {
            final local = details.localPosition;
            _handle = (local - right).distance <= (local - up).distance ? 0 : 1;
          },
          onPanUpdate: (details) => _drag(details.delta),
          onPanEnd: (_) => _handle = null,
          child: CustomPaint(
            size: size,
            painter: _SheetPainter(
              cells: cells,
              ghost: widget.sheet.showGhost ? widget.sheet.target : null,
              origin: origin,
            ),
          ),
        );
      },
    );
  }
}

class _SheetPainter extends CustomPainter {
  const _SheetPainter({required this.cells, required this.ghost, required this.origin});

  final List<double> cells;
  final List<double>? ghost;
  final Offset origin;

  Offset _map(double x, double y, List<double> m) {
    final px = m[0] * x + m[1] * y;
    final py = m[2] * x + m[3] * y;
    return origin + Offset(px * 42, -py * 42);
  }

  Path _quad(List<double> m) {
    final path = Path()
      ..moveTo(_map(-0.8, -0.8, m).dx, _map(-0.8, -0.8, m).dy)
      ..lineTo(_map(0.8, -0.8, m).dx, _map(0.8, -0.8, m).dy)
      ..lineTo(_map(0.8, 0.8, m).dx, _map(0.8, 0.8, m).dy)
      ..lineTo(_map(-0.8, 0.8, m).dx, _map(-0.8, 0.8, m).dy)
      ..close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (ghost != null) {
      canvas.drawPath(
        _quad(ghost!),
        Paint()
          ..color = AxiomColors.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.drawPath(
      _quad(cells),
      Paint()
        ..color = AxiomColors.accent.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      _quad(cells),
      Paint()
        ..color = AxiomColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final face = _map(0, 0, cells);
    canvas.drawCircle(face, 10, Paint()..color = AxiomColors.accent);
    canvas.drawCircle(_map(cells[0], cells[2], [1, 0, 0, 1]), 8, Paint()..color = AxiomColors.ink);
    canvas.drawCircle(_map(cells[1], cells[3], [1, 0, 0, 1]), 8, Paint()..color = AxiomColors.success);
  }

  @override
  bool shouldRepaint(covariant _SheetPainter oldDelegate) => oldDelegate.cells != cells;
}

class _HillToy extends StatelessWidget {
  const _HillToy({
    required this.hill,
    required this.draft,
    required this.onChanged,
    required this.enabled,
    required this.settle,
  });

  final HillPrimitive hill;
  final Object? draft;
  final ValueChanged<Object?> onChanged;
  final bool enabled;
  final bool settle;

  @override
  Widget build(BuildContext context) {
    final tip = _point(draft) ?? hill.start;
    final shown = settle
        ? PlanePoint(x: hill.start.x + hill.correctRun, y: hill.start.y + hill.correctRise)
        : tip;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanUpdate: enabled
              ? (details) {
                  final box = context.findRenderObject();
                  if (box is! RenderBox) return;
                  final local = box.globalToLocal(details.globalPosition);
                  onChanged({
                    'x': (local.dx / size.width) * 10,
                    'y': (1 - local.dy / size.height) * 10,
                  });
                }
              : null,
          child: CustomPaint(
            size: size,
            painter: _HillPainter(hill: hill, tip: shown),
          ),
        );
      },
    );
  }
}

class _HillPainter extends CustomPainter {
  const _HillPainter({required this.hill, required this.tip});

  final HillPrimitive hill;
  final PlanePoint tip;

  Offset _px(double x, double y, Size size) => Offset(x / 10 * size.width, size.height - y / 10 * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var step = 0; step <= 20; step++) {
      final x = step / 2;
      final y = hill.start.y + hill.slope * (x - hill.start.x);
      final point = _px(x, y.clamp(0, 10), size);
      if (step == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AxiomColors.ink.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    final start = _px(hill.start.x, hill.start.y, size);
    final head = _px(tip.x, tip.y, size);
    canvas.drawLine(
      start,
      head,
      Paint()
        ..color = AxiomColors.accent
        ..strokeWidth = 4,
    );
    canvas.drawCircle(head, 12, Paint()..color = AxiomColors.accent);
    canvas.drawCircle(start, 6, Paint()..color = AxiomColors.ink);
  }

  @override
  bool shouldRepaint(covariant _HillPainter oldDelegate) => oldDelegate.tip != tip;
}

class _BagToy extends StatelessWidget {
  const _BagToy({
    required this.bag,
    required this.draft,
    required this.onChanged,
    required this.enabled,
    required this.settle,
  });

  final BagPrimitive bag;
  final Object? draft;
  final ValueChanged<Object?> onChanged;
  final bool enabled;
  final bool settle;

  @override
  Widget build(BuildContext context) {
    if (bag.task == 'pick') return _pick(context);
    if (bag.task == 'count') return _count(context);
    return _select(context);
  }

  Widget _pick(BuildContext context) {
    final chosen = draft is String ? draft : null;
    return Row(
      children: [
        for (final side in bag.bags)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _Jar(
                label: side.id.toUpperCase(),
                chips: side.chips,
                selected: chosen == side.id || (settle && side.id == bag.correctBagId),
                onTap: enabled ? () => onChanged(side.id) : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _count(BuildContext context) {
    final chips = bag.bags.isEmpty ? const <String>[] : bag.bags.first.chips;
    final answer = draft;
    var count = 0;
    if (answer is num) count = answer.round();
    final face = bag.face ?? '';
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chip in chips) _Chip(label: chip, hot: chip == face),
          ],
        ),
        const Spacer(),
        Text('How many $face?'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: enabled && count > 0 ? () => onChanged(count - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            Text('$count', style: Theme.of(context).textTheme.headlineSmall),
            IconButton(
              onPressed: enabled ? () => onChanged(count + 1) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  Widget _select(BuildContext context) {
    final picked = _ids(draft);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in bag.options)
          FilterChip(
            label: Text(option.label),
            selected: picked.contains(option.id) || (settle && bag.correctIds.contains(option.id)),
            onSelected: enabled
                ? (selected) {
                    final next = [...picked];
                    if (selected) {
                      next.add(option.id);
                    } else {
                      next.remove(option.id);
                    }
                    onChanged({'ids': next});
                  }
                : null,
          ),
      ],
    );
  }
}

class _Jar extends StatelessWidget {
  const _Jar({required this.label, required this.chips, required this.selected, required this.onTap});

  final String label;
  final List<String> chips;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AxiomColors.accent : AxiomColors.line, width: selected ? 3 : 1),
          color: selected ? AxiomColors.accent.withValues(alpha: 0.08) : AxiomColors.surface,
        ),
        child: Column(
          children: [
            Text(label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [for (final chip in chips) _Chip(label: chip, hot: chip == 'R' || chip == 'H')],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.hot});

  final String label;
  final bool hot;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hot ? AxiomColors.accent : AxiomColors.line,
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: AxiomColors.surface)),
    );
  }
}

class _BeamToy extends StatelessWidget {
  const _BeamToy({
    required this.beam,
    required this.draft,
    required this.onChanged,
    required this.enabled,
    required this.settle,
  });

  final BeamPrimitive beam;
  final Object? draft;
  final ValueChanged<Object?> onChanged;
  final bool enabled;
  final bool settle;

  @override
  Widget build(BuildContext context) {
    if (beam.task == 'pick') {
      final chosen = draft is String ? draft : null;
      return Row(
        children: [
          for (final side in beam.beams)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: InkWell(
                  onTap: enabled ? () => onChanged(side.id) : null,
                  child: Column(
                    children: [
                      Text(side.id == beam.correctId && settle ? 'This one' : 'Beam'),
                      const SizedBox(height: 12),
                      _BeamFace(
                        blocks: side.blocks,
                        fulcrum: _mean(side.blocks),
                        tilt: chosen == side.id ? 0.08 : 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    }
    final blocks = beam.blocks;
    final mean = _mean(blocks);
    final answer = draft;
    var fulcrum = mean;
    if (settle) {
      fulcrum = beam.correctFulcrum ?? mean;
    } else if (answer is num) {
      fulcrum = answer.toDouble();
    }
    final tilt = ((mean - fulcrum) / 6).clamp(-0.35, 0.35);
    return Column(
      children: [
        Expanded(child: _BeamFace(blocks: blocks, fulcrum: fulcrum, tilt: tilt)),
        Slider(
          value: fulcrum.clamp(0, 12),
          min: 0,
          max: 12,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}

class _BeamFace extends StatelessWidget {
  const _BeamFace({required this.blocks, required this.fulcrum, required this.tilt});

  final List<double> blocks;
  final double fulcrum;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: tilt),
      duration: const Duration(milliseconds: 220),
      builder: (context, angle, child) {
        return Transform.rotate(angle: angle, child: child);
      },
      child: CustomPaint(
        painter: _BeamPainter(blocks: blocks, fulcrum: fulcrum),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BeamPainter extends CustomPainter {
  const _BeamPainter({required this.blocks, required this.fulcrum});

  final List<double> blocks;
  final double fulcrum;

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.height * 0.72;
    final left = 24.0;
    final width = size.width - 48;
    canvas.drawLine(
      Offset(left, base),
      Offset(left + width, base),
      Paint()
        ..color = AxiomColors.ink
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    final fx = left + (fulcrum.clamp(0, 12) / 12) * width;
    final triangle = Path()
      ..moveTo(fx, base)
      ..lineTo(fx - 12, base + 18)
      ..lineTo(fx + 12, base + 18)
      ..close();
    canvas.drawPath(triangle, Paint()..color = AxiomColors.accent);
    if (blocks.isEmpty) return;
    final slot = width / (blocks.length + 1);
    for (var index = 0; index < blocks.length; index++) {
      final height = 10.0 + blocks[index].abs() * 6;
      final rect = Rect.fromLTWH(left + slot * (index + 1) - 10, base - height, 20, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = index == blocks.length ~/ 2 ? AxiomColors.success : AxiomColors.accent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BeamPainter oldDelegate) => oldDelegate.fulcrum != fulcrum;
}

PlanePoint? _point(Object? draft) {
  if (draft is! Map) return null;
  final x = draft['x'];
  final y = draft['y'];
  if (x is! num || y is! num) return null;
  return PlanePoint(x: x.toDouble(), y: y.toDouble());
}

List<String> _ids(Object? draft) {
  final raw = draft is Map ? draft['ids'] : null;
  if (raw is! List) return const [];
  return [for (final item in raw) if (item is String) item];
}

double _mean(List<double> blocks) {
  if (blocks.isEmpty) return 0;
  return blocks.reduce((a, b) => a + b) / blocks.length;
}

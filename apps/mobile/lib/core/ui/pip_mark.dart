import 'package:axiom/core/ui/app_theme.dart';
import 'package:flutter/material.dart';

/// Geometric robot. Eyes grow when a skill is mastered.
class PipMark extends StatelessWidget {
  const PipMark({this.mastered = false, super.key});

  final bool mastered;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final scale = mastered ? 1.0 : 0.6;
    return Semantics(
      label: mastered ? 'Pip mastered' : 'Pip resting',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: scale),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, _) {
          return CustomPaint(
            key: const Key('pip-mark'),
            size: const Size(64, 64),
            painter: _PipPainter(eyeScale: value),
          );
        },
      ),
    );
  }
}

class _PipPainter extends CustomPainter {
  const _PipPainter({required this.eyeScale});

  final double eyeScale;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = AxiomColors.accent;
    final eye = Paint()..color = AxiomColors.paper;
    final radius = size.shortestSide * 0.07 * eyeScale;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.16,
            size.height * 0.22,
            size.width * 0.68,
            size.height * 0.62,
          ),
          Radius.circular(size.shortestSide * 0.18),
        ),
        body,
      )
      ..drawCircle(Offset(size.width * 0.38, size.height * 0.48), radius, eye)
      ..drawCircle(Offset(size.width * 0.62, size.height * 0.48), radius, eye);
  }

  @override
  bool shouldRepaint(covariant _PipPainter oldDelegate) {
    return oldDelegate.eyeScale != eyeScale;
  }
}

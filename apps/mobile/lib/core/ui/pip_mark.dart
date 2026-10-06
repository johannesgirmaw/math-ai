import 'package:axiom/core/ui/app_theme.dart';
import 'package:flutter/material.dart';

/// Geometric robot. Eyes grow when a skill is mastered.
class PipMark extends StatelessWidget {
  const PipMark({this.mastered = false, this.size = 64, super.key});

  final bool mastered;
  final double size;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final scale = mastered ? 1.0 : 0.6;
    return Semantics(
      label: mastered ? 'Pip mastered' : 'Pip resting',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: mastered ? 0.6 : scale, end: scale),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, _) {
          return CustomPaint(
            key: const Key('pip-mark'),
            size: Size(size, size),
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
    final fill = Paint()..color = AxiomColors.accent;
    final eye = Paint()..color = AxiomColors.surface;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.22,
            size.height * 0.5,
            size.width * 0.56,
            size.height * 0.38,
          ),
          Radius.circular(size.shortestSide * 0.14),
        ),
        fill,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.16,
            size.height * 0.1,
            size.width * 0.68,
            size.height * 0.42,
          ),
          Radius.circular(size.shortestSide * 0.18),
        ),
        fill,
      );
    final radius = size.shortestSide * 0.08 * eyeScale;
    canvas
      ..drawCircle(Offset(size.width * 0.38, size.height * 0.3), radius, eye)
      ..drawCircle(Offset(size.width * 0.62, size.height * 0.3), radius, eye);
  }

  @override
  bool shouldRepaint(covariant _PipPainter oldDelegate) {
    return oldDelegate.eyeScale != eyeScale;
  }
}

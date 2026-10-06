import 'package:axiom/core/ui/app_theme.dart';
import 'package:flutter/material.dart';

/// The f(brain) mark in Analytical Teal.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 36, this.onDark = false, super.key});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/math-si-mark.png',
      key: ValueKey(onDark),
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
  }
}

/// Stacked symbol over MATH SI, or the symbol alone where height is tight.
class BrandLockup extends StatelessWidget {
  const BrandLockup({
    this.stacked = true,
    this.symbolSize = 88,
    this.onDark = false,
    super.key,
  });

  final bool stacked;
  final double symbolSize;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final mark = BrandMark(size: symbolSize, onDark: onDark);
    return Semantics(
      label: 'MATH SI',
      excludeSemantics: true,
      child: stacked
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                mark,
                SizedBox(height: symbolSize * 0.16),
                Text(
                  'MATH SI',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: symbolSize * 0.2,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: symbolSize * 0.055,
                    color: onDark ? Colors.white : AxiomColors.ink,
                  ),
                ),
              ],
            )
          : mark,
    );
  }
}

/// Page bar with the symbol only. The name is reserved for stacked lockups.
AppBar brandAppBar({
  Widget? leading,
  List<Widget>? actions,
  bool automaticallyImplyLeading = true,
}) {
  return AppBar(
    automaticallyImplyLeading: automaticallyImplyLeading,
    leading: leading,
    titleSpacing: 8,
    title: const BrandLockup(stacked: false, symbolSize: 36),
    actions: actions,
  );
}

/// Symbol and gold rule for screens that do not use an app bar.
class BrandStrip extends StatelessWidget {
  const BrandStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandLockup(stacked: false, symbolSize: 36),
        SizedBox(height: 10),
        SizedBox(
          height: 2,
          width: double.infinity,
          child: ColoredBox(color: AxiomColors.gold),
        ),
      ],
    );
  }
}

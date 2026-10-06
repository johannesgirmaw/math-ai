import 'package:axiom/core/ui/app_theme.dart';
import 'package:flutter/material.dart';

/// MATH SI lockup. Full plaque at header size, or the mark plus wordmark.
class BrandLockup extends StatelessWidget {
  const BrandLockup({this.height = 120, this.compact = false, super.key});

  /// Logical height of the full plaque. Headers stay at or above 120.
  final double height;

  /// Mark plus Montserrat wordmark for bars, at least 32px tall.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!compact) {
      return Image.asset(
        'assets/brand/math-si-logo.png',
        height: height,
        fit: BoxFit.contain,
        semanticLabel: 'MATH SI',
      );
    }
    final wordmark = Theme.of(context).textTheme.titleLarge;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/brand/math-si-mark.png',
          height: 40,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: 10),
        Text('MATH SI', style: wordmark),
      ],
    );
  }
}

/// Page bar with the compact lockup and the theme's gold rule.
AppBar brandAppBar({
  Widget? leading,
  List<Widget>? actions,
  bool automaticallyImplyLeading = true,
}) {
  return AppBar(
    automaticallyImplyLeading: automaticallyImplyLeading,
    leading: leading,
    titleSpacing: 8,
    title: const FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: BrandLockup(compact: true),
    ),
    actions: actions,
  );
}

/// Compact lockup and gold rule for screens that do not use an app bar.
class BrandStrip extends StatelessWidget {
  const BrandStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandLockup(compact: true),
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

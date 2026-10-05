import 'package:axiom/core/ui/app_theme.dart';
import 'package:axiom/core/ui/pip_mark.dart';
import 'package:axiom/features/path/domain/path_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Mission complete: Pip, the idea, and the streak.
class CompletePage extends StatelessWidget {
  const CompletePage({required this.mission, super.key});

  final MissionComplete mission;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const PipMark(mastered: true),
              const SizedBox(height: 24),
              Text(
                mission.whyItMatters,
                key: const Key('why-it-matters'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AxiomColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AxiomColors.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        mission.pipAbility,
                        key: const Key('pip-ability'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text('Streak ${mission.streakCurrent}'),
                    ],
                  ),
                ),
              ),
              if (mission.offlineNote != null) ...[
                const SizedBox(height: 12),
                Text(
                  mission.offlineNote!,
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/path'),
                  child: const Text('Back to the path'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

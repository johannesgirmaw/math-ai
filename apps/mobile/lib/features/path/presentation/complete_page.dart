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
      appBar: AppBar(
        leading: IconButton(
          key: const Key('complete-back'),
          tooltip: 'Back',
          onPressed: () => context.go('/path'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              PipMark(mastered: mission.skillMastered),
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
                mission.skillMastered
                    ? 'Pip can do this now.'
                    : 'Pip is still learning this.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                mission.pipAbility,
                key: const Key('pip-ability'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('Streak ${mission.streakCurrent}'),
              if (mission.nextLessonTitle case final lesson?
                  when lesson.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Next lesson: $lesson',
                  key: const Key('next-lesson'),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_unlockLine(mission) case final line?) ...[
                const SizedBox(height: 8),
                Text(line, textAlign: TextAlign.center),
              ],
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

String? _unlockLine(MissionComplete mission) {
  final next = mission.nextTitle;
  if (next == null || next.isEmpty) return null;
  if (mission.skillMastered) return 'Next node: $next.';
  final lesson = mission.nextLessonTitle;
  if (lesson != null && lesson.isNotEmpty) return null;
  if (mission.misses == 1) return 'One miss keeps $next locked.';
  if (mission.misses > 1) {
    return '${mission.misses} misses keep $next locked.';
  }
  return '$next stays locked for now.';
}

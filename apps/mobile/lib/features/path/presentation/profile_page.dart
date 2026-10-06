import 'dart:async';

import 'package:axiom/core/ui/app_theme.dart';
import 'package:axiom/core/ui/brand_lockup.dart';
import 'package:axiom/core/ui/pip_mark.dart';
import 'package:axiom/features/auth/application/auth_providers.dart';
import 'package:axiom/features/path/application/learning_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Streak, XP, and the daily goal.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(profileSummaryProvider);
    return Scaffold(
      appBar: brandAppBar(
        leading: IconButton(
          key: const Key('profile-back'),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/path');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: FilledButton(
            key: const Key('error-retry'),
            onPressed: () => ref.invalidate(profileSummaryProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (profile) {
          final nodes = ref.watch(pathNodesProvider).asData?.value ?? const [];
          final abilities = [
            for (final node in nodes)
              if (node.state == 'mastered' && node.pipAbility.isNotEmpty)
                node.pipAbility,
          ];
          final haptics = ref.watch(hapticsEnabledProvider);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'Profile',
                      style: Theme.of(context).textTheme.headlineMedium,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const PipMark(mastered: true),
                            const SizedBox(height: 12),
                            Text(
                              'Streak ${profile.streakCurrent}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text('Longest ${profile.streakLongest}'),
                            Text('XP ${profile.xpTotal}'),
                            Text('Goal ${profile.dailyGoalMinutes} minutes'),
                            const SizedBox(height: 12),
                            Text(
                              abilities.isEmpty
                                  ? 'Pip has no abilities yet.'
                                  : abilities.join('\n'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    for (final minutes in const [5, 10, 15])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            key: Key('profile-goal-$minutes'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  profile.dailyGoalMinutes == minutes
                                  ? AxiomColors.accent
                                  : AxiomColors.surface,
                              foregroundColor:
                                  profile.dailyGoalMinutes == minutes
                                  ? AxiomColors.surface
                                  : AxiomColors.ink,
                            ),
                            onPressed: () => unawaited(_goal(ref, minutes)),
                            child: Text('$minutes minutes'),
                          ),
                        ),
                      ),
                    SwitchListTile(
                      key: const Key('haptics-toggle'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Haptics'),
                      value: haptics,
                      onChanged: (value) {
                        ref
                            .read(hapticsEnabledProvider.notifier)
                            .setEnabled(enabled: value);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      unawaited(
                        ref.read(sessionControllerProvider.notifier).signOut(),
                      );
                    },
                    child: const Text('Sign out'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _goal(WidgetRef ref, int minutes) async {
    final result = await ref
        .read(profileRepositoryProvider)
        .patch(
          dailyGoalMinutes: minutes,
        );
    result.fold((_) {}, (_) {
      ref.invalidate(profileSummaryProvider);
    });
  }
}

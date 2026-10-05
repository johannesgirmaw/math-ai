import 'dart:async';

import 'package:axiom/core/ui/app_theme.dart';
import 'package:axiom/features/auth/application/auth_providers.dart';
import 'package:axiom/features/path/application/learning_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streak, XP, and the daily goal.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(profileSummaryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: FilledButton(
            key: const Key('error-retry'),
            onPressed: () => ref.invalidate(profileSummaryProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (profile) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      Text(
                        'Streak ${profile.streakCurrent}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text('Longest ${profile.streakLongest}'),
                      Text('XP ${profile.xpTotal}'),
                      Text('Goal ${profile.dailyGoalMinutes} minutes'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Review dates update after sync.'),
              const SizedBox(height: 24),
              for (final minutes in const [5, 10, 15])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    key: Key('profile-goal-$minutes'),
                    onPressed: () => unawaited(_goal(ref, minutes)),
                    child: Text('$minutes minutes'),
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  unawaited(
                    ref.read(sessionControllerProvider.notifier).signOut(),
                  );
                },
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _goal(WidgetRef ref, int minutes) async {
    final result = await ref.read(profileRepositoryProvider).patch(
      dailyGoalMinutes: minutes,
    );
    result.fold((_) {}, (_) {
      ref.invalidate(profileSummaryProvider);
    });
  }
}

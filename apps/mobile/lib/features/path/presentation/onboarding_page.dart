import 'dart:async';

import 'package:axiom/core/ui/app_theme.dart';
import 'package:axiom/core/ui/pip_mark.dart';
import 'package:axiom/features/auth/application/auth_providers.dart';
import 'package:axiom/features/path/application/learning_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Daily goal and timezone, then placement.
class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = ref.watch(goalDraftProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PipMark(),
              const SizedBox(height: 24),
              Text(
                'How many minutes a day?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'A short session is enough.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              for (final option in const [5, 10, 15])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      key: Key('goal-$option'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: minutes == option
                            ? AxiomColors.accent
                            : AxiomColors.surface,
                        foregroundColor: minutes == option
                            ? AxiomColors.surface
                            : AxiomColors.ink,
                        side: BorderSide(
                          color: minutes == option
                              ? AxiomColors.accent
                              : AxiomColors.line,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () {
                        ref.read(goalDraftProvider.notifier).select(option);
                      },
                      child: Text('$option minutes'),
                    ),
                  ),
                ),
              const Spacer(),
              FilledButton(
                key: const Key('onboarding-continue'),
                onPressed: minutes == null
                    ? null
                    : () => unawaited(_submit(context, ref, minutes)),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref, int minutes) async {
    final timezone = await ref.read(timezoneSourceProvider).iana();
    final result = await ref.read(profileRepositoryProvider).patch(
      dailyGoalMinutes: minutes,
      timezone: timezone,
      onboardingCompletedAt: DateTime.now().toUtc().toIso8601String(),
    );
    if (!context.mounted) return;
    result.fold((failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    }, (summary) {
      final learner = ref.read(sessionControllerProvider).asData?.value;
      if (learner != null) {
        ref.read(sessionControllerProvider.notifier).replace(
          learner.copyWith(
            dailyGoalMinutes: summary.dailyGoalMinutes,
            timezone: summary.timezone,
            onboardingCompletedAt:
                summary.onboardingCompletedAt ??
                DateTime.now().toUtc().toIso8601String(),
          ),
        );
      }
      unawaited(ref.read(telemetryProvider).capture('onboarding_completed'));
      context.go('/placement');
    });
  }
}

/// Selected daily goal before it is saved.
class GoalDraft extends Notifier<int?> {
  @override
  int? build() => null;

  // select is a method so the page can pass the tapped minutes.
  // ignore: use_setters_to_change_properties
  void select(int minutes) => state = minutes;
}

/// The goal the learner tapped.
final goalDraftProvider = NotifierProvider<GoalDraft, int?>(GoalDraft.new);

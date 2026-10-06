import 'dart:async';

import 'package:axiom/core/ui/brand_lockup.dart';
import 'package:axiom/features/lesson_player/application/lesson_player.dart';
import 'package:axiom/features/lesson_player/domain/lesson.dart';
import 'package:axiom/features/lesson_player/domain/reducer.dart';
import 'package:axiom/features/lesson_player/presentation/primitive_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One lesson, one idea per screen.
class LessonPage extends ConsumerWidget {
  const LessonPage({
    required this.lesson,
    this.hapticsEnabled = true,
    this.onFinished,
    this.onChecked,
    this.onQuit,
    this.banner,
    super.key,
  });

  final Lesson lesson;
  final bool hapticsEnabled;
  final ValueChanged<LessonResult>? onFinished;
  final ValueChanged<ScreenFact>? onChecked;
  final VoidCallback? onQuit;
  final String? banner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lessonPlayerProvider(lesson));
    final index = switch (state) {
      LessonPresenting(:final screenIndex) => screenIndex,
      LessonFeedback(:final screenIndex) => screenIndex,
      LessonComplete() => lesson.screens.length - 1,
    };
    final screen = lesson.screens[index];
    final drafting = state is LessonPresenting;
    final hasAnswer = state is LessonPresenting && _hasAnswer(state.draft);
    final draft = switch (state) {
      LessonPresenting(:final draft) => draft,
      LessonFeedback(:final answer) => answer,
      LessonComplete() => null,
    };
    final settle = state is LessonFeedback && state.correct;
    final miss = state is LessonFeedback && !state.correct;
    return PopScope(
      canPop: state is LessonComplete,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmQuit(context));
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandStrip(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      IconButton(
                        key: const Key('lesson-back'),
                        tooltip: 'Back',
                        onPressed: state is LessonComplete
                            ? () => Navigator.of(context).pop()
                            : () => _confirmQuit(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    Expanded(
                      child: ProgressDots(
                        count: lesson.screens.length,
                        index: index,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (banner != null) ...[
                  Text(banner!),
                  const SizedBox(height: 12),
                ],
                PromptText(text: screen.prompt),
                const SizedBox(height: 24),
                Expanded(
                  child: state is LessonComplete
                      ? const Text('Lesson complete.')
                      : buildPrimitive(
                          primitive: screen.primitive,
                          draft: draft,
                          enabled: drafting,
                          settle: settle,
                          miss: miss,
                          onChanged: (answer) {
                            ref
                                .read(lessonPlayerProvider(lesson).notifier)
                                .change(answer);
                          },
                        ),
                ),
                if (state is LessonFeedback)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FeedbackBanner(
                      message: state.message,
                      correct: state.correct,
                    ),
                  ),
                AxiomButton(
                  label: state is LessonFeedback ? 'Continue' : 'Check',
                  onPressed:
                      state is LessonComplete ||
                          (state is LessonPresenting && !hasAnswer)
                      ? null
                      : () => _act(ref, state),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmQuit(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave this mission?'),
          content: const Text('This mission will start over next time.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay'),
            ),
            TextButton(
              key: const Key('leave-mission'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
    if (leave == true && context.mounted) {
      onQuit?.call();
      Navigator.of(context).pop();
    }
  }

  void _act(WidgetRef ref, LessonState state) {
    final player = ref.read(lessonPlayerProvider(lesson).notifier);
    if (state is LessonPresenting) {
      player.check();
      final next = ref.read(lessonPlayerProvider(lesson));
      if (next is LessonFeedback && next.correct && hapticsEnabled) {
        unawaited(HapticFeedback.lightImpact());
      }
      final facts = player.facts;
      if (next is LessonFeedback && facts.isNotEmpty) {
        onChecked?.call(facts.last);
      }
      return;
    }
    if (state is LessonFeedback) {
      player.continueLesson((result) {
        onFinished?.call(result);
      });
    }
  }
}

bool _hasAnswer(Object? draft) {
  if (draft == null || draft == '') return false;
  if (draft is List && draft.isEmpty) return false;
  return true;
}

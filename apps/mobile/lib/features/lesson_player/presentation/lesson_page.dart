import 'dart:async';

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
    super.key,
  });

  final Lesson lesson;
  final bool hapticsEnabled;
  final ValueChanged<LessonResult>? onFinished;
  final ValueChanged<ScreenFact>? onChecked;
  final VoidCallback? onQuit;

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
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && state is! LessonComplete) onQuit?.call();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProgressDots(count: lesson.screens.length, index: index),
                const SizedBox(height: 24),
                PromptText(text: screen.prompt),
                const SizedBox(height: 24),
                Expanded(
                  child: state is LessonComplete
                      ? const Text('Lesson complete.')
                      : buildPrimitive(
                          primitive: screen.primitive,
                          draft: state is LessonPresenting ? state.draft : null,
                          enabled: drafting,
                          onChanged: (answer) {
                            ref
                                .read(lessonPlayerProvider(lesson).notifier)
                                .change(answer);
                          },
                        ),
                ),
                if (state is LessonPresenting && state.needsAnswer)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('Answer first.'),
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
                  onPressed: state is LessonComplete
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

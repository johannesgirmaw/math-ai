import 'dart:async';

import 'package:axiom/core/error/failure.dart';
import 'package:axiom/features/auth/application/auth_providers.dart';
import 'package:axiom/features/lesson_player/data/lesson_parser.dart';
import 'package:axiom/features/lesson_player/domain/lesson.dart';
import 'package:axiom/features/lesson_player/presentation/lesson_page.dart';
import 'package:axiom/features/path/application/learning_providers.dart';
import 'package:axiom/features/path/domain/path_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A few screens that choose a starting skill.
class PlacementPage extends ConsumerStatefulWidget {
  const PlacementPage({super.key});

  @override
  ConsumerState<PlacementPage> createState() => _PlacementPageState();
}

class _PlacementPageState extends ConsumerState<PlacementPage> {
  PlacementStep? _step;
  Lesson? _lesson;
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final result = await ref.read(placementRepositoryProvider).start();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _loading = false;
      }),
      _apply,
    );
  }

  void _apply(PlacementStep step) {
    if (step.completed || step.screen == null) {
      _finish(step);
      return;
    }
    final parsed = parseScreen(step.screen!);
    final failure = parsed.fold<Failure?>(
      (error) => error,
      (_) => null,
    );
    if (failure != null) {
      setState(() {
        _error = failure.message;
        _loading = false;
      });
      return;
    }
    final screen = parsed.getOrElse(
      (_) => throw StateError('screen'),
    );
    setState(() {
      _step = step;
      _lesson = _wrap(screen, step.skillId);
      _error = null;
      _loading = false;
    });
  }

  Lesson _wrap(Screen screen, String? skillId) {
    return Lesson(
      id: screen.id,
      skillNodeId: skillId ?? screen.id,
      title: 'Placement',
      version: 1,
      screens: [screen],
      capstone: false,
      whyItMatters: 'This finds where you start.',
    );
  }

  Future<void> _answered(LessonResult result) async {
    final step = _step;
    if (step == null) return;
    final correct = result.facts.isNotEmpty && result.facts.first.correct;
    final next = await ref.read(placementRepositoryProvider).answer(
      sessionId: step.sessionId,
      correct: correct,
    );
    if (!mounted) return;
    next.fold(
      (failure) => setState(() => _error = failure.message),
      _apply,
    );
  }

  void _finish(PlacementStep step) {
    final learner = ref.read(sessionControllerProvider).asData?.value;
    if (learner != null) {
      ref.read(sessionControllerProvider.notifier).replace(
        learner.copyWith(placementSkillId: step.skillId ?? learner.id),
      );
    }
    unawaited(ref.read(telemetryProvider).capture('placement_completed'));
    context.go('/path');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('error-retry'),
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  unawaited(_load());
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    final lesson = _lesson;
    if (lesson == null) {
      return const Scaffold(body: Center(child: Text('Placement is ready.')));
    }
    return LessonPage(
      key: ValueKey(lesson.id),
      lesson: lesson,
      onFinished: (result) => unawaited(_answered(result)),
    );
  }
}

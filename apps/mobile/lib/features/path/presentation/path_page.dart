import 'dart:async';
import 'dart:convert';

import 'package:axiom/core/telemetry.dart';
import 'package:axiom/core/ui/app_theme.dart';
import 'package:axiom/core/ui/pip_mark.dart';
import 'package:axiom/features/lesson_player/data/lesson_parser.dart';
import 'package:axiom/features/lesson_player/domain/lesson.dart';
import 'package:axiom/features/lesson_player/presentation/lesson_page.dart';
import 'package:axiom/features/path/application/learning_providers.dart';
import 'package:axiom/features/path/domain/path_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Vertical skill path.
class PathPage extends ConsumerWidget {
  const PathPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.watch(pathNodesProvider);
    final sync = ref.watch(syncControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Axiom'),
        actions: [
          if (sync.running)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.sync, key: Key('sync-glyph')),
            ),
          IconButton(
            key: const Key('open-profile'),
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: nodes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$error'),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('error-retry'),
                onPressed: () => ref.invalidate(pathNodesProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (items) => _PathList(nodes: items),
      ),
    );
  }
}

class _PathList extends ConsumerWidget {
  const _PathList({required this.nodes});

  final List<PathNode> nodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncControllerProvider);
    final seen = <String>{};
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        if (sync.message != null)
          MaterialBanner(
            content: Text(sync.message!),
            actions: [
              TextButton(
                onPressed: () {
                  unawaited(ref.read(syncControllerProvider.notifier).run());
                },
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () {
                  ref.read(syncControllerProvider.notifier).dismiss();
                },
                child: const Text('Dismiss'),
              ),
            ],
          ),
        const _PathHeader(),
        for (final node in nodes)
          _Station(
            node: node,
            laneKey: _laneKey(node, seen),
            continues: node != nodes.last,
          ),
        if (kDebugMode) ...[
          TextButton(
            onPressed: () => unawaited(_demo(context)),
            child: const Text('Try a lesson'),
          ),
          TextButton(
            onPressed: () => unawaited(debugSentryCheck()),
            child: const Text('Sentry check'),
          ),
        ],
      ],
    );
  }

  Key _laneKey(PathNode node, Set<String> seen) {
    final base = 'path-lane-${node.lane}';
    if (seen.add(node.lane)) return Key(base);
    return Key('$base-${node.id}');
  }

  Future<void> _demo(BuildContext context) async {
    final raw = await rootBundle.loadString(
      'assets/lessons/vector-arrow.json',
    );
    final parsed = parseLesson(jsonDecode(raw) as Map<String, dynamic>);
    if (!context.mounted) return;
    parsed.fold((_) {}, (lesson) {
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LessonPage(lesson: lesson),
          ),
        ),
      );
    });
  }
}

class _PathHeader extends ConsumerWidget {
  const _PathHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.watch(pathNodesProvider).asData?.value ?? const [];
    PathNode? current;
    for (final node in nodes) {
      if (node.state == 'available' && node.lessonId != null) {
        current = node;
        break;
      }
    }
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 28),
      child: Row(
        children: [
          const PipMark(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your path', style: theme.headlineSmall),
                Text(
                  current?.promise ?? 'Skills unlock in order.',
                  style: theme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Station extends ConsumerWidget {
  const _Station({
    required this.node,
    required this.laneKey,
    required this.continues,
  });

  final PathNode node;
  final Key laneKey;
  final bool continues;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final left = node.lane != 'right';
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 2,
              height: continues ? 220 : 110,
              color: AxiomColors.line,
            ),
          ),
          Align(
            alignment: left
                ? const Alignment(-0.55, 0)
                : const Alignment(0.55, 0),
            child: _NodeButton(node: node, laneKey: laneKey),
          ),
        ],
      ),
    );
  }
}

class _NodeButton extends ConsumerWidget {
  const _NodeButton({required this.node, required this.laneKey});

  final PathNode node;
  final Key laneKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = node.state == 'locked' || node.lessonId == null;
    final mastered = node.state == 'mastered';
    final theme = Theme.of(context).textTheme;
    return SizedBox(
      key: laneKey,
      width: 148,
      child: TextButton(
        onPressed: locked ? null : () => unawaited(_open(context, ref)),
        style: TextButton.styleFrom(
          foregroundColor: AxiomColors.ink,
          disabledForegroundColor: AxiomColors.ink.withValues(alpha: 0.45),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        child: Column(
          children: [
            _Marker(node: node),
            const SizedBox(height: 8),
            Text(
              node.title,
              textAlign: TextAlign.center,
              style: theme.titleMedium,
            ),
            if (!locked && !mastered)
              Text(
                node.promise,
                textAlign: TextAlign.center,
                style: theme.bodyMedium,
              ),
            if (mastered)
              Text(
                node.pipAbility,
                textAlign: TextAlign.center,
                style: theme.bodyMedium,
              ),
            if (node.lessonId == null) const Text('Lessons publish soon.'),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final opened = await ref.read(lessonLauncherProvider).open(node);
    if (!context.mounted) return;
    opened.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (launch) {
        unawaited(
          ref.read(telemetryProvider).capture(
            'lesson_started',
            properties: {
              'lessonId': launch.lesson.id,
              'skillId': node.id,
            },
          ),
        );
        unawaited(
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LessonPage(
                lesson: launch.lesson,
                onQuit: () {
                  unawaited(
                    ref.read(telemetryProvider).capture(
                      'lesson_quit',
                      properties: {'lessonId': launch.lesson.id},
                    ),
                  );
                },
                onChecked: (fact) {
                  unawaited(
                    ref.read(telemetryProvider).capture(
                      'screen_checked',
                      properties: {
                        'lessonId': launch.lesson.id,
                        'screenId': fact.screenId,
                        'correct': fact.correct,
                        'latencyMs': fact.latencyMs,
                      },
                    ),
                  );
                },
                onFinished: (result) {
                  unawaited(_finish(context, ref, launch, result));
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _finish(
    BuildContext context,
    WidgetRef ref,
    LessonLaunch launch,
    LessonResult result,
  ) async {
    final mission = await ref.read(lessonSubmitterProvider).submit(
      launch: launch,
      result: result,
    );
    if (!context.mounted) return;
    unawaited(
      ref.read(telemetryProvider).capture(
        'lesson_completed',
        properties: {
          'lessonId': launch.lesson.id,
          'skillId': launch.lesson.skillNodeId,
        },
      ),
    );
    final complete = mission.fold(
      (failure) => MissionComplete(
        streakCurrent: 0,
        xpTotal: 0,
        pipAbility: launch.pipAbility,
        whyItMatters: launch.lesson.whyItMatters,
        offlineNote: failure.message,
      ),
      (value) => value,
    );
    context.go('/complete', extra: complete);
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.node});

  final PathNode node;

  @override
  Widget build(BuildContext context) {
    final mastered = node.state == 'mastered';
    final available = node.available;
    final ring = mastered
        ? AxiomColors.success
        : available
        ? AxiomColors.accent
        : AxiomColors.line;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: available ? AxiomColors.accent : AxiomColors.surface,
        border: Border.all(color: ring, width: 3),
      ),
      child: mastered
          ? const FittedBox(child: PipMark(mastered: true))
          : Icon(
              available ? Icons.north_east : Icons.lock_outline,
              color: available
                  ? AxiomColors.surface
                  : AxiomColors.ink.withValues(alpha: 0.45),
            ),
    );
  }
}

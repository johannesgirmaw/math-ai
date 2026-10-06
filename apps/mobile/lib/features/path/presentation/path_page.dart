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
            onPressed: () => context.push('/profile'),
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
    String? currentId;
    for (final node in nodes) {
      if (node.available) {
        currentId = node.id;
        break;
      }
    }
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
        for (var index = 0; index < nodes.length; index++)
          _Station(
            node: nodes[index],
            laneKey: _laneKey(nodes[index], seen),
            fromLeft: index == 0
                ? nodes[index].lane != 'right'
                : nodes[index - 1].lane != 'right',
            current: nodes[index].id == currentId,
            showWorld:
                index > 0 &&
                nodes[index].worldTitle != nodes[index - 1].worldTitle,
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
                Text(
                  current != null && current.worldTitle.isNotEmpty
                      ? current.worldTitle
                      : 'Your path',
                  style: theme.headlineSmall,
                ),
                Text(
                  current?.promise ?? 'Skills unlock in order.',
                  style: theme.bodyLarge,
                ),
                const _TodayGoal(),
                const _PathStreak(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayGoal extends ConsumerWidget {
  const _TodayGoal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(profileSummaryProvider).asData?.value;
    if (summary == null) return const SizedBox.shrink();
    final minutes = summary.dailyGoalMinutes;
    final text = summary.todayDone
        ? "Today's $minutes-minute mission is done."
        : "Today's goal is $minutes minutes.";
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text, key: const Key('today-goal')),
    );
  }
}

class _PathStreak extends ConsumerWidget {
  const _PathStreak();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(profileSummaryProvider).asData?.value;
    if (summary == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        'Streak ${summary.streakCurrent}',
        key: const Key('path-streak'),
      ),
    );
  }
}

class _Station extends ConsumerWidget {
  const _Station({
    required this.node,
    required this.laneKey,
    required this.fromLeft,
    required this.current,
    required this.showWorld,
  });

  final PathNode node;
  final Key laneKey;
  final bool fromLeft;
  final bool current;
  final bool showWorld;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final left = node.lane != 'right';
    return Column(
      children: [
        if (showWorld && node.worldTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                node.worldTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
        SizedBox(
          height: 176,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: PathBridgePainter(fromLeft: fromLeft, toLeft: left),
                ),
              ),
              Align(
                alignment: left
                    ? const Alignment(-0.62, 0.15)
                    : const Alignment(0.62, 0.15),
                child: _Reveal(
                  active: current,
                  child: _NodeButton(
                    node: node,
                    laneKey: laneKey,
                    current: current,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  @override
  void initState() {
    super.initState();
    _show();
  }

  void _show() {
    if (!widget.active) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        Scrollable.ensureVisible(context, alignment: 0.35),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Stroke from the previous lane to this node's lane.
class PathBridgePainter extends CustomPainter {
  const PathBridgePainter({required this.fromLeft, required this.toLeft});

  final bool fromLeft;
  final bool toLeft;

  double _laneX(Size size, bool left) {
    final align = left ? -0.62 : 0.62;
    return size.width * (0.5 + align / 2);
  }

  /// Curve used by the path. Tests read this instead of the pixels.
  Path pathFor(Size size) {
    final fromX = _laneX(size, fromLeft);
    final toX = _laneX(size, toLeft);
    return Path()
      ..moveTo(fromX, 0)
      ..cubicTo(
        fromX,
        size.height * 0.28,
        toX,
        size.height * 0.42,
        toX,
        size.height,
      );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AxiomColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(pathFor(size), paint);
  }

  @override
  bool shouldRepaint(covariant PathBridgePainter oldDelegate) {
    return oldDelegate.fromLeft != fromLeft || oldDelegate.toLeft != toLeft;
  }
}

class _NodeButton extends ConsumerWidget {
  const _NodeButton({
    required this.node,
    required this.laneKey,
    required this.current,
  });

  final PathNode node;
  final Key laneKey;
  final bool current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = node.state == 'locked' || node.lessonId == null;
    final theme = Theme.of(context).textTheme;
    return SizedBox(
      key: laneKey,
      width: 132,
      child: TextButton(
        onPressed: locked ? null : () => unawaited(_open(context, ref)),
        style: TextButton.styleFrom(
          foregroundColor: AxiomColors.ink,
          disabledForegroundColor: AxiomColors.ink.withValues(alpha: 0.45),
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (current)
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: AxiomColors.accent,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  child: Text(
                    'You are here',
                    style: TextStyle(color: AxiomColors.surface, fontSize: 12),
                  ),
                ),
              ),
            _CurrentHalo(
              active: current,
              child: _Marker(node: node, current: current),
            ),
            const SizedBox(height: 6),
            Text(
              node.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: theme.titleMedium,
            ),
            if (current && node.progress > 0 && node.progress < 0.8)
              Text(
                'Not solid yet.',
                textAlign: TextAlign.center,
                style: theme.bodyMedium,
              ),
            if (node.lessonId == null) const Text('Lessons publish soon.'),
            if (locked && node.waitsOn.isNotEmpty)
              Text(
                'After ${node.waitsOn}',
                textAlign: TextAlign.center,
                style: theme.bodyMedium,
              ),
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
                hapticsEnabled: ref.read(hapticsEnabledProvider),
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

class _CurrentHalo extends StatelessWidget {
  const _CurrentHalo({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      key: const Key('current-halo'),
      tween: Tween(begin: reduce ? 1 : 0.86, end: 1),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AxiomColors.accent.withValues(alpha: 0.35 * value),
                spreadRadius: 6 * value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.node, required this.current});

  final PathNode node;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final mastered = node.state == 'mastered';
    final available = node.available;
    final ring = mastered
        ? AxiomColors.success
        : available
        ? AxiomColors.accent
        : AxiomColors.line;
    final size = current ? 68.0 : 56.0;
    final face = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: available ? AxiomColors.accent : AxiomColors.surface,
        border: Border.all(color: ring, width: mastered ? 0 : 3),
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
    if (!available && !mastered) return face;
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: mastered ? 1 : node.progress.clamp(0, 1),
            strokeWidth: 4,
            backgroundColor: AxiomColors.line,
            color: mastered ? AxiomColors.success : AxiomColors.accent,
          ),
          face,
        ],
      ),
    );
  }
}

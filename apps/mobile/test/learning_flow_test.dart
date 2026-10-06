import 'package:axiom/app/app.dart';
import 'package:axiom/core/error/failure.dart';
import 'package:axiom/features/auth/application/auth_providers.dart';
import 'package:axiom/features/auth/domain/learner.dart';
import 'package:axiom/features/content_sync/application/lesson_launcher.dart';
import 'package:axiom/features/lesson_player/domain/lesson.dart';
import 'package:axiom/features/path/application/learning_providers.dart';
import 'package:axiom/features/path/data/path_repository.dart';
import 'package:axiom/features/path/data/placement_repository.dart';
import 'package:axiom/features/path/data/profile_repository.dart';
import 'package:axiom/features/path/domain/path_models.dart';
import 'package:axiom/features/path/presentation/path_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

const _learner = Learner(
  id: 'user-1',
  email: 'ada@axiom.app',
  displayName: 'Ada',
  dailyGoalMinutes: 5,
  role: 'learner',
  onboardingCompletedAt: null,
  placementSkillId: null,
  timezone: 'UTC',
);

const Map<String, Object> _screen = {
  'id': 'place',
  'prompt': 'Do these arrows agree?',
  'primitive': {
    'type': 'choice',
    'options': [
      {'id': 'a', 'label': 'Yes'},
      {'id': 'b', 'label': 'No'},
    ],
    'correctOptionId': 'a',
  },
  'feedback': {'wrong_option': 'Same direction means they agree.'},
  'easyWithinMs': 8000,
  'correctMessage': 'Same direction means a positive agreement.',
};

class _Session extends SessionController {
  @override
  Future<Learner?> build() async => _learner;
}

class _IdleSync extends SyncController {
  @override
  SyncSnapshot build() => const SyncSnapshot();
}

class _Clock implements TimezoneSource {
  @override
  Future<String> iana() async => 'UTC';
}

class _Profile implements ProfileRepository {
  int? minutes;

  ProfileSummary _summary({String? onboarding}) {
    return ProfileSummary(
      displayName: 'Ada',
      dailyGoalMinutes: minutes ?? 5,
      timezone: 'UTC',
      onboardingCompletedAt: onboarding,
      placementSkillId: null,
      streakCurrent: 0,
      streakLongest: 0,
      xpTotal: 0,
    );
  }

  @override
  Future<Either<Failure, ProfileSummary>> patch({
    int? dailyGoalMinutes,
    String? timezone,
    String? onboardingCompletedAt,
  }) async {
    minutes = dailyGoalMinutes;
    return right(_summary(onboarding: onboardingCompletedAt));
  }

  @override
  Future<Either<Failure, ProfileSummary>> summary() async => right(_summary());
}

class _Placement implements PlacementRepository {
  @override
  Future<Either<Failure, PlacementStep>> answer({
    required String sessionId,
    required bool correct,
  }) async {
    return right(
      const PlacementStep(
        sessionId: 'session-1',
        completed: true,
        skillId: 'skill-1',
        screen: null,
      ),
    );
  }

  @override
  Future<Either<Failure, PlacementStep>> start() async {
    return right(
      PlacementStep(
        sessionId: 'session-1',
        completed: false,
        skillId: 'skill-1',
        screen: Map<String, dynamic>.from(_screen),
      ),
    );
  }
}

class _Path implements PathRepository {
  _Path(this.nodes);

  final List<PathNode> nodes;
  @override
  Future<Either<Failure, List<PathNode>>> load() async => right(nodes);
}

class _Launcher implements LessonLauncher {
  int opens = 0;

  @override
  Future<Either<Failure, LessonLaunch>> open(PathNode node) async {
    opens += 1;
    return right(
      LessonLaunch(
        attemptId: 'attempt-1',
        pipAbility: node.pipAbility,
        lesson: const Lesson(
          id: '30000000-0000-4000-8000-000000000001',
          skillNodeId: 'skill',
          title: 'Arrow parts',
          version: 1,
          capstone: false,
          whyItMatters: 'A vector is an arrow a model can add and scale.',
          screens: [
            Screen(
              id: 'one',
              prompt: 'Pick the arrow.',
              primitive: ChoicePrimitive(
                options: [
                  ChoiceOption(id: 'a', label: 'Right'),
                  ChoiceOption(id: 'b', label: 'Left'),
                ],
                correctOptionId: 'a',
              ),
              feedback: {'wrong_option': 'The arrow points right.'},
              easyWithinMs: 8000,
              correctMessage: 'That is the arrow.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Submitter implements LessonSubmitter {
  @override
  Future<Either<Failure, MissionComplete>> submit({
    required LessonLaunch launch,
    required LessonResult result,
  }) async {
    return right(
      MissionComplete(
        streakCurrent: 1,
        xpTotal: 10,
        xpAwarded: 10,
        pipAbility: launch.pipAbility,
        whyItMatters: launch.lesson.whyItMatters,
      ),
    );
  }
}

const _nodes = [
  PathNode(
    id: 'left',
    title: 'Arrow parts',
    promise: 'You can point an arrow.',
    pipAbility: 'Pip can aim an arrow.',
    rank: 0,
    lane: 'left',
    state: 'available',
    lessonId: '30000000-0000-4000-8000-000000000001',
  ),
  PathNode(
    id: 'right',
    title: 'Equal arrows',
    promise: 'You can spot equal arrows.',
    pipAbility: 'Pip treats equal arrows as the same move.',
    rank: 1,
    lane: 'right',
    state: 'locked',
    lessonId: null,
  ),
];

void main() {
  testWidgets('goal, placement, both lanes, and mission complete', (
    tester,
  ) async {
    final profile = _Profile();
    final launcher = _Launcher();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_Session.new),
          timezoneSourceProvider.overrideWithValue(_Clock()),
          profileRepositoryProvider.overrideWithValue(profile),
          placementRepositoryProvider.overrideWithValue(_Placement()),
          pathRepositoryProvider.overrideWithValue(_Path(_nodes)),
          syncControllerProvider.overrideWith(_IdleSync.new),
          lessonLauncherProvider.overrideWithValue(launcher),
          lessonSubmitterProvider.overrideWithValue(_Submitter()),
        ],
        child: const AxiomApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('goal-5')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();
    expect(profile.minutes, 5);

    await tester.tap(find.byKey(const Key('choice-a')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('lesson-action')));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('path-lane-left')), findsOneWidget);
    expect(find.byKey(const Key('path-lane-right')), findsOneWidget);
    expect(find.byKey(const Key('path-streak')), findsOneWidget);
    expect(find.byKey(const Key('current-halo')), findsOneWidget);

    await tester.tap(find.text('Arrow parts'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('choice-a')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('lesson-action')));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pip-ability')), findsOneWidget);
    expect(find.text('Pip can aim an arrow.'), findsOneWidget);
    expect(find.text('+10 XP'), findsOneWidget);
    expect(
      find.text('A vector is an arrow a model can add and scale.'),
      findsOneWidget,
    );
    expect(launcher.opens, 1);
  });

  testWidgets('a locked node does not open a lesson', (tester) async {
    final launcher = _Launcher();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pathRepositoryProvider.overrideWithValue(_Path(_nodes)),
          syncControllerProvider.overrideWith(_IdleSync.new),
          lessonLauncherProvider.overrideWithValue(launcher),
          lessonSubmitterProvider.overrideWithValue(_Submitter()),
        ],
        child: const MaterialApp(home: PathPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Equal arrows'));
    await tester.pump();
    expect(launcher.opens, 0);
  });
}

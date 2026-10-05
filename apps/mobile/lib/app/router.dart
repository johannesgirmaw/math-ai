import 'package:axiom/features/auth/application/auth_providers.dart';
import 'package:axiom/features/auth/domain/learner.dart';
import 'package:axiom/features/auth/presentation/sign_in_page.dart';
import 'package:axiom/features/auth/presentation/sign_up_page.dart';
import 'package:axiom/features/path/domain/path_models.dart';
import 'package:axiom/features/path/presentation/complete_page.dart';
import 'package:axiom/features/path/presentation/onboarding_page.dart';
import 'package:axiom/features/path/presentation/path_page.dart';
import 'package:axiom/features/path/presentation/placement_page.dart';
import 'package:axiom/features/path/presentation/profile_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

/// Where a signed-in learner should be.
String? learningRedirect({
  required bool loading,
  required Learner? learner,
  required String location,
}) {
  if (loading) return null;
  const authRoutes = {'/sign-in', '/sign-up'};
  if (learner == null) {
    return authRoutes.contains(location) ? null : '/sign-in';
  }
  if (learner.onboardingCompletedAt == null) {
    return location == '/onboarding' ? null : '/onboarding';
  }
  if (learner.placementSkillId == null) {
    return location == '/placement' ? null : '/placement';
  }
  const study = {'/path', '/lesson', '/complete', '/profile'};
  if (study.contains(location)) return null;
  return '/path';
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(sessionControllerProvider, (_, _) {
      refresh.value++;
    })
    ..onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/sign-in',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      return learningRedirect(
        loading: session.isLoading,
        learner: session.asData?.value,
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInPage()),
      GoRoute(path: '/sign-up', builder: (_, _) => const SignUpPage()),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingPage(),
      ),
      GoRoute(path: '/placement', builder: (_, _) => const PlacementPage()),
      GoRoute(path: '/path', builder: (_, _) => const PathPage()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
      GoRoute(
        path: '/complete',
        builder: (_, state) {
          final extra = state.extra;
          final mission = extra is MissionComplete
              ? extra
              : const MissionComplete(
                  streakCurrent: 0,
                  xpTotal: 0,
                  pipAbility: '',
                  whyItMatters: '',
                );
          return CompletePage(mission: mission);
        },
      ),
    ],
  );
}

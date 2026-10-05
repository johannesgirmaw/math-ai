import 'package:axiom/features/lesson_player/domain/lesson.dart';

/// One node on the vertical path.
class PathNode {
  const PathNode({
    required this.id,
    required this.title,
    required this.promise,
    required this.pipAbility,
    required this.rank,
    required this.lane,
    required this.state,
    required this.lessonId,
  });

  final String id;
  final String title;
  final String promise;
  final String pipAbility;
  final int rank;
  final String lane;
  final String state;
  final String? lessonId;

  bool get available => state == 'available' && lessonId != null;
}

/// Streak, goal, and XP shown on the profile.
class ProfileSummary {
  const ProfileSummary({
    required this.displayName,
    required this.dailyGoalMinutes,
    required this.timezone,
    required this.onboardingCompletedAt,
    required this.placementSkillId,
    required this.streakCurrent,
    required this.streakLongest,
    required this.xpTotal,
  });

  final String displayName;
  final int dailyGoalMinutes;
  final String timezone;
  final String? onboardingCompletedAt;
  final String? placementSkillId;
  final int streakCurrent;
  final int streakLongest;
  final int xpTotal;
}

/// One placement step from the server.
class PlacementStep {
  const PlacementStep({
    required this.sessionId,
    required this.completed,
    required this.skillId,
    required this.screen,
  });

  final String sessionId;
  final bool completed;
  final String? skillId;
  final Map<String, dynamic>? screen;
}

/// What the learner sees after a mission.
class MissionComplete {
  const MissionComplete({
    required this.streakCurrent,
    required this.xpTotal,
    required this.pipAbility,
    required this.whyItMatters,
    this.offlineNote,
  });

  final int streakCurrent;
  final int xpTotal;
  final String pipAbility;
  final String whyItMatters;
  final String? offlineNote;
}

/// A lesson plus the attempt id that will receive its facts.
class LessonLaunch {
  const LessonLaunch({
    required this.lesson,
    required this.attemptId,
    required this.pipAbility,
  });

  final Lesson lesson;
  final String attemptId;
  final String pipAbility;
}

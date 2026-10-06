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
    this.progress = 0,
    this.worldTitle = '',
    this.waitsOn = '',
  });

  final String id;
  final String title;
  final String promise;
  final String pipAbility;
  final int rank;
  final String lane;
  final String state;
  final String? lessonId;
  final double progress;
  final String worldTitle;
  final String waitsOn;

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
    this.todayDone = false,
  });

  final String displayName;
  final int dailyGoalMinutes;
  final String timezone;
  final String? onboardingCompletedAt;
  final String? placementSkillId;
  final int streakCurrent;
  final int streakLongest;
  final int xpTotal;
  final bool todayDone;
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
    this.xpAwarded = 0,
    this.offlineNote,
    this.skillMastered = false,
    this.nextTitle,
    this.misses = 0,
    this.nextLessonTitle,
  });

  final int streakCurrent;
  final int xpTotal;
  final int xpAwarded;
  final String pipAbility;
  final String whyItMatters;
  final String? offlineNote;
  final bool skillMastered;
  final String? nextTitle;
  final String? nextLessonTitle;
  final int misses;
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

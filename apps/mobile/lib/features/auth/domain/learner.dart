/// The signed-in learner.
class Learner {
  const Learner({
    required this.id,
    required this.email,
    required this.displayName,
    required this.dailyGoalMinutes,
    required this.role,
    required this.onboardingCompletedAt,
    required this.placementSkillId,
    required this.timezone,
  });

  final String id;
  final String email;
  final String displayName;
  final int dailyGoalMinutes;
  final String role;
  final String? onboardingCompletedAt;
  final String? placementSkillId;
  final String timezone;

  Learner copyWith({
    String? onboardingCompletedAt,
    String? placementSkillId,
    int? dailyGoalMinutes,
    String? timezone,
  }) {
    return Learner(
      id: id,
      email: email,
      displayName: displayName,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      role: role,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
      placementSkillId: placementSkillId ?? this.placementSkillId,
      timezone: timezone ?? this.timezone,
    );
  }
}

import 'package:axiom/features/auth/domain/learner.dart';

/// Maps API JSON into a [Learner].
abstract final class AuthDto {
  static Learner fromMe(Map<String, dynamic> json) {
    return Learner(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      dailyGoalMinutes: json['dailyGoalMinutes'] as int? ?? 5,
      role: json['role'] as String? ?? 'learner',
      onboardingCompletedAt: json['onboardingCompletedAt'] as String?,
      placementSkillId: json['placementSkillId'] as String?,
      timezone: json['timezone'] as String? ?? 'UTC',
    );
  }
}

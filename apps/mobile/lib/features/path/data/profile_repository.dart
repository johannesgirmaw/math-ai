import 'package:axiom/core/error/failure.dart';
import 'package:axiom/core/network/dio_failure.dart';
import 'package:axiom/features/path/domain/path_models.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

/// Profile summary and daily-goal updates.
abstract class ProfileRepository {
  Future<Either<Failure, ProfileSummary>> summary();

  Future<Either<Failure, ProfileSummary>> patch({
    int? dailyGoalMinutes,
    String? timezone,
    String? onboardingCompletedAt,
  });
}

/// `/api/v1/profile/summary` and `PATCH /api/v1/me`.
class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, ProfileSummary>> summary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/profile/summary',
      );
      final data = response.data;
      if (data == null) return left(const UnexpectedFailure());
      return right(profileFromJson(data));
    } on DioException catch (error) {
      return left(failureFromDio(error));
    }
  }

  @override
  Future<Either<Failure, ProfileSummary>> patch({
    int? dailyGoalMinutes,
    String? timezone,
    String? onboardingCompletedAt,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/v1/me',
        data: {
          'dailyGoalMinutes': dailyGoalMinutes,
          'timezone': timezone,
          'onboardingCompletedAt': onboardingCompletedAt,
        },
      );
      final data = response.data;
      if (data == null) return left(const UnexpectedFailure());
      return right(profileFromJson(data));
    } on DioException catch (error) {
      return left(failureFromDio(error));
    }
  }
}

/// Maps the profile JSON.
ProfileSummary profileFromJson(Map<String, dynamic> json) {
  return ProfileSummary(
    displayName: json['displayName'] as String? ?? '',
    dailyGoalMinutes: json['dailyGoalMinutes'] as int? ?? 5,
    timezone: json['timezone'] as String? ?? 'UTC',
    onboardingCompletedAt: json['onboardingCompletedAt'] as String?,
    placementSkillId: json['placementSkillId'] as String?,
    streakCurrent: json['streakCurrent'] as int? ?? 0,
    streakLongest: json['streakLongest'] as int? ?? 0,
    xpTotal: (json['xpTotal'] as num?)?.toInt() ?? 0,
    todayDone: json['todayDone'] == true,
  );
}

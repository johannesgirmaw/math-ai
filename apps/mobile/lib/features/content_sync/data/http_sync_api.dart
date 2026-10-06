import 'dart:convert';

import 'package:axiom/core/error/failure.dart';
import 'package:axiom/core/network/dio_failure.dart';
import 'package:axiom/features/content_sync/application/sync_worker.dart';
import 'package:axiom/features/path/domain/path_models.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

/// Sync endpoints over Dio.
class HttpSyncApi implements SyncApi {
  HttpSyncApi(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, PackManifest>> currentManifest() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/content/packs/current',
      );
      final data = response.data;
      if (data == null) return left(const UnexpectedFailure());
      return right(
        PackManifest(
          version: data['version'] as String? ?? '',
          sha256: data['sha256'] as String? ?? '',
        ),
      );
    } on DioException catch (error) {
      return left(failureFromDio(error));
    }
  }

  @override
  Future<Either<Failure, String>> packBody(String version) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/content/packs/$version',
      );
      final data = response.data;
      if (data == null) return left(const UnexpectedFailure());
      return right(jsonEncode(data));
    } on DioException catch (error) {
      return left(failureFromDio(error));
    }
  }

  @override
  Future<Either<Failure, void>> postResults({
    required String attemptId,
    required List<Map<String, dynamic>> results,
  }) async {
    try {
      await _dio.post<void>(
        '/api/v1/attempts/$attemptId/results',
        data: {'results': results},
      );
      return right(null);
    } on DioException catch (error) {
      return left(failureFromDio(error));
    }
  }

  @override
  Future<Either<Failure, MissionComplete>> postComplete(
    String attemptId,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/attempts/$attemptId/complete',
      );
      final data = response.data;
      if (data == null) return left(const UnexpectedFailure());
      return right(
        MissionComplete(
          streakCurrent: data['streakCurrent'] as int? ?? 0,
          xpTotal: (data['xpTotal'] as num?)?.toInt() ?? 0,
          xpAwarded: (data['xpAwarded'] as num?)?.toInt() ?? 0,
          pipAbility: data['pipAbility'] as String? ?? '',
          whyItMatters: data['whyItMatters'] as String? ?? '',
          skillMastered: data['skillMastered'] as bool? ?? false,
          nextTitle: data['nextTitle'] as String?,
          nextLessonTitle: data['nextLessonTitle'] as String?,
          misses: (data['misses'] as num?)?.toInt() ?? 0,
        ),
      );
    } on DioException catch (error) {
      return left(failureFromDio(error));
    }
  }

  @override
  Future<Either<Failure, void>> startAttempt({
    required String lessonId,
    required String attemptId,
  }) async {
    try {
      await _dio.post<void>(
        '/api/v1/attempts',
        data: {'lessonId': lessonId, 'attemptId': attemptId},
      );
      return right(null);
    } on DioException catch (error) {
      return left(failureFromDio(error));
    }
  }
}

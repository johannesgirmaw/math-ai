import 'package:axiom/core/error/failure.dart';
import 'package:axiom/core/network/dio_failure.dart';
import 'package:axiom/features/path/domain/path_models.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

/// Adaptive placement.
abstract class PlacementRepository {
  Future<Either<Failure, PlacementStep>> start();

  Future<Either<Failure, PlacementStep>> answer({
    required String sessionId,
    required bool correct,
  });
}

/// Placement session routes.
class HttpPlacementRepository implements PlacementRepository {
  HttpPlacementRepository(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, PlacementStep>> start() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/placement/sessions',
      );
      final data = response.data;
      if (data == null) return left(const UnexpectedFailure());
      return right(placementFromJson(data));
    } on DioException catch (error) {
      return left(failureFromDio(error));
    }
  }

  @override
  Future<Either<Failure, PlacementStep>> answer({
    required String sessionId,
    required bool correct,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/placement/sessions/$sessionId/answers',
        data: {'correct': correct},
      );
      final data = response.data;
      if (data == null) return left(const UnexpectedFailure());
      return right(placementFromJson(data, sessionId: sessionId));
    } on DioException catch (error) {
      return left(failureFromDio(error));
    }
  }
}

/// Maps a placement response. [sessionId] fills the field when absent.
PlacementStep placementFromJson(
  Map<String, dynamic> json, {
  String? sessionId,
}) {
  final screen = json['screen'];
  return PlacementStep(
    sessionId: json['sessionId'] as String? ?? sessionId ?? '',
    completed: json['completed'] == true,
    skillId: json['skillId'] as String?,
    screen: screen is Map<String, dynamic> ? screen : null,
  );
}

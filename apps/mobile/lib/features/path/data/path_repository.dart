import 'package:axiom/core/error/failure.dart';
import 'package:axiom/core/network/dio_failure.dart';
import 'package:axiom/features/path/domain/path_models.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

/// The published skill path.
abstract class PathRepository {
  Future<Either<Failure, List<PathNode>>> load();
}

/// `GET /api/v1/path`.
class HttpPathRepository implements PathRepository {
  HttpPathRepository(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, List<PathNode>>> load() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/path');
      final nodes = response.data?['nodes'];
      if (nodes is! List) return left(const UnexpectedFailure());
      return right([
        for (final node in nodes)
          if (node is Map<String, dynamic>) pathNodeFromJson(node),
      ]);
    } on DioException catch (error) {
      return left(failureFromDio(error));
    }
  }
}

/// Maps one path node.
PathNode pathNodeFromJson(Map<String, dynamic> json) {
  return PathNode(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    promise: json['promise'] as String? ?? '',
    pipAbility: json['pipAbility'] as String? ?? '',
    rank: json['rank'] as int? ?? 0,
    lane: json['lane'] as String? ?? 'left',
    state: json['state'] as String? ?? 'locked',
    lessonId: json['lessonId'] as String?,
    progress: (json['progress'] as num?)?.toDouble() ?? 0,
  );
}

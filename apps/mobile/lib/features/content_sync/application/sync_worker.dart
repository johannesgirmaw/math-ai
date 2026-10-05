import 'dart:convert';

import 'package:axiom/core/error/failure.dart';
import 'package:axiom/features/content_sync/data/local_database.dart';
import 'package:axiom/features/path/domain/path_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';

/// Result of one sync pass.
enum SyncStatus { offline, ok, failed }

/// Pack and result calls used by [SyncWorker].
abstract class SyncApi {
  Future<Either<Failure, PackManifest>> currentManifest();

  Future<Either<Failure, String>> packBody(String version);

  Future<Either<Failure, void>> postResults({
    required String attemptId,
    required List<Map<String, dynamic>> results,
  });

  Future<Either<Failure, MissionComplete>> postComplete(String attemptId);

  Future<Either<Failure, void>> startAttempt({
    required String lessonId,
    required String attemptId,
  });
}

/// Published pack identity.
class PackManifest {
  const PackManifest({required this.version, required this.sha256});

  final String version;
  final String sha256;
}

/// Posts queued facts in order and refreshes the cached pack.
class SyncWorker {
  SyncWorker({
    required this.database,
    required this.api,
    required this.online,
    this.log,
    this.onRefreshed,
  });

  final AppDatabase database;
  final SyncApi api;
  final Future<bool> Function() online;
  final Logger? log;
  final Future<void> Function()? onRefreshed;
  MissionComplete? lastComplete;

  Future<SyncStatus> run() async {
    if (!await online()) return SyncStatus.offline;
    final manifest = await api.currentManifest();
    final manifestFailure = manifest.fold((failure) => failure, (_) => null);
    if (manifestFailure is NetworkFailure) return SyncStatus.offline;
    if (manifestFailure != null) return SyncStatus.failed;
    final current = manifest.getOrElse(
      (_) => const PackManifest(version: '', sha256: ''),
    );
    final cached = await database.pack(current.version);
    if (cached == null || cached.sha256 != current.sha256) {
      final body = await api.packBody(current.version);
      final bodyFailure = body.fold((failure) => failure, (_) => null);
      if (bodyFailure != null) return SyncStatus.failed;
      await database.upsertPack(
        version: current.version,
        sha256: current.sha256,
        body: body.getOrElse((_) => ''),
        downloadedAt: DateTime.now(),
      );
    }

    final rows = await database.outbox();
    final results = rows.where((row) => row.kind == 'item_results');
    final groups = <String, List<OutboxRow>>{};
    final order = <String>[];
    for (final row in results) {
      final attemptId = _attemptId(row);
      if (attemptId == null) {
        await _drop(row, 'missing attempt');
        continue;
      }
      if (!groups.containsKey(attemptId)) order.add(attemptId);
      groups.putIfAbsent(attemptId, () => []).add(row);
    }
    for (final attemptId in order) {
      final group = groups[attemptId] ?? const <OutboxRow>[];
      final posted = await api.postResults(
        attemptId: attemptId,
        results: group.map(_result).whereType<Map<String, dynamic>>().toList(),
      );
      final stop = await _settle(posted, group);
      if (stop) return SyncStatus.failed;
    }

    final completes = rows.where((row) => row.kind == 'attempt_complete');
    for (final row in completes) {
      final attemptId = _attemptId(row);
      if (attemptId == null) {
        await _drop(row, 'missing attempt');
        continue;
      }
      final posted = await api.postComplete(attemptId);
      posted.fold<void>(
        (_) {},
        (mission) {
          lastComplete = mission;
        },
      );
      final asVoid = posted.fold<Either<Failure, void>>(
        Left.new,
        (_) => const Right(null),
      );
      final stop = await _settle(asVoid, [row]);
      if (stop) return SyncStatus.failed;
    }

    if (onRefreshed != null) await onRefreshed!();
    return SyncStatus.ok;
  }

  Future<bool> _settle<T>(
    Either<Failure, T> posted,
    List<OutboxRow> rows,
  ) async {
    final failure = posted.fold((error) => error, (_) => null);
    if (failure == null) {
      for (final row in rows) {
        await database.deleteOutbox(row.id);
      }
      return false;
    }
    if (failure is NetworkFailure) return true;
    if (failure is HttpFailure && failure.statusCode >= 500) return true;
    if (failure is HttpFailure && failure.statusCode == 409) {
      for (final row in rows) {
        await database.deleteOutbox(row.id);
      }
      return false;
    }
    if (failure is HttpFailure) {
      for (final row in rows) {
        log?.w('Dropped outbox ${row.id}');
        await database.deleteOutbox(row.id);
      }
      return false;
    }
    return true;
  }

  Future<void> _drop(OutboxRow row, String reason) async {
    log?.w('Dropped outbox ${row.id}: $reason');
    await database.deleteOutbox(row.id);
  }

  String? _attemptId(OutboxRow row) {
    final json = jsonDecode(row.payload);
    if (json is! Map) return null;
    final attemptId = json['attemptId'];
    if (attemptId is! String) return null;
    return attemptId;
  }

  Map<String, dynamic>? _result(OutboxRow row) {
    final json = jsonDecode(row.payload);
    if (json is! Map) return null;
    final result = json['result'];
    if (result is! Map) return null;
    return Map<String, dynamic>.from(result);
  }
}

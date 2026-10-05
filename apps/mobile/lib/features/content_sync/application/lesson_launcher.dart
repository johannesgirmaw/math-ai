import 'dart:convert';

import 'package:axiom/core/error/failure.dart';
import 'package:axiom/features/content_sync/application/sync_worker.dart';
import 'package:axiom/features/content_sync/data/local_database.dart';
import 'package:axiom/features/lesson_player/data/lesson_parser.dart';
import 'package:axiom/features/lesson_player/domain/lesson.dart';
import 'package:axiom/features/path/domain/path_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

/// Opens a lesson from cache or the network.
abstract class LessonLauncher {
  Future<Either<Failure, LessonLaunch>> open(PathNode node);
}

/// Sends the player's facts once.
abstract class LessonSubmitter {
  Future<Either<Failure, MissionComplete>> submit({
    required LessonLaunch launch,
    required LessonResult result,
  });
}

/// Opens a cached or downloaded lesson and records a local attempt.
class DriftLessonLauncher implements LessonLauncher {
  DriftLessonLauncher({
    required this.database,
    required this.api,
    required this.online,
    this.memoryBody,
  });

  final AppDatabase database;
  final SyncApi api;
  final Future<bool> Function() online;
  final String? Function()? memoryBody;
  static const _uuid = Uuid();

  @override
  Future<Either<Failure, LessonLaunch>> open(PathNode node) async {
    final lessonId = node.lessonId;
    if (lessonId == null) {
      return left(const ValidationFailure('Lessons publish soon.'));
    }
    var lesson = _find(lessonId, memoryBody?.call());
    lesson ??= _find(lessonId, (await database.latestPack())?.body);
    if (lesson == null) {
      if (!await online()) {
        return left(
          const NetworkFailure('The first download needs a connection.'),
        );
      }
      lesson = _find(lessonId, await _download());
    }
    if (lesson == null) {
      return left(
        const NetworkFailure('The first download needs a connection.'),
      );
    }
    final attemptId = _uuid.v4();
    await database.insertAttempt(
      id: attemptId,
      lessonId: lesson.id,
      startedAt: DateTime.now(),
    );
    if (await online()) {
      try {
        await api.startAttempt(lessonId: lesson.id, attemptId: attemptId);
      } on Object {
        // The local attempt id is still valid offline.
      }
    }
    return right(
      LessonLaunch(
        lesson: lesson,
        attemptId: attemptId,
        pipAbility: node.pipAbility,
      ),
    );
  }

  Future<String?> _download() async {
    final manifest = await api.currentManifest();
    final current = manifest.fold<PackManifest?>(
      (_) => null,
      (value) => value,
    );
    if (current == null) return null;
    final body = await api.packBody(current.version);
    final raw = body.fold<String?>((_) => null, (value) => value);
    if (raw == null) return null;
    await database.upsertPack(
      version: current.version,
      sha256: current.sha256,
      body: raw,
      downloadedAt: DateTime.now(),
    );
    return raw;
  }

  Lesson? _find(String lessonId, String? body) {
    if (body == null) return null;
    final json = jsonDecode(body);
    if (json is! Map) return null;
    final lessons = json['lessons'];
    if (lessons is! List) return null;
    for (final item in lessons) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      if (map['id'] != lessonId) continue;
      return parseLesson(map).fold((_) => null, (lesson) => lesson);
    }
    return null;
  }
}

/// Writes facts to the outbox and asks [SyncWorker] to deliver them.
class OutboxLessonSubmitter implements LessonSubmitter {
  OutboxLessonSubmitter({
    required this.database,
    required this.worker,
    required this.cachedStreak,
  });

  final AppDatabase database;
  final SyncWorker worker;
  final int Function() cachedStreak;
  static const _uuid = Uuid();

  @override
  Future<Either<Failure, MissionComplete>> submit({
    required LessonLaunch launch,
    required LessonResult result,
  }) async {
    final now = DateTime.now();
    for (final fact in result.facts) {
      await database.insertOutbox(
        id: fact.clientResultId,
        kind: 'item_results',
        createdAt: now,
        payload: jsonEncode({
          'attemptId': launch.attemptId,
          'result': {
            'id': fact.clientResultId,
            'screenId': fact.screenId,
            'correct': fact.correct,
            'latencyMs': fact.latencyMs,
            'errorCode': fact.errorCode,
            'hadMiss': fact.hadMiss,
          },
        }),
      );
    }
    await database.insertOutbox(
      id: _uuid.v4(),
      kind: 'attempt_complete',
      createdAt: now.add(const Duration(milliseconds: 1)),
      payload: jsonEncode({'attemptId': launch.attemptId}),
    );
    final status = await worker.run();
    final synced = worker.lastComplete;
    if (synced != null) return right(synced);
    return right(
      MissionComplete(
        streakCurrent: cachedStreak(),
        xpTotal: 0,
        pipAbility: launch.pipAbility,
        whyItMatters: launch.lesson.whyItMatters,
        offlineNote: status == SyncStatus.offline
            ? 'Review dates update after sync.'
            : null,
      ),
    );
  }
}

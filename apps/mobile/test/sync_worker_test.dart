import 'dart:convert';

import 'package:axiom/core/error/failure.dart';
import 'package:axiom/features/content_sync/application/lesson_launcher.dart';
import 'package:axiom/features/content_sync/application/sync_worker.dart';
import 'package:axiom/features/content_sync/data/local_database.dart';
import 'package:axiom/features/path/domain/path_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _Api implements SyncApi {
  _Api(this.onResults, {this.pack = '{"lessons": []}'});

  final Future<Either<Failure, void>> Function() onResults;
  final String pack;
  int resultCalls = 0;

  @override
  Future<Either<Failure, PackManifest>> currentManifest() async {
    return right(const PackManifest(version: 'v1', sha256: 'abc'));
  }

  @override
  Future<Either<Failure, String>> packBody(String version) async {
    return right(pack);
  }

  @override
  Future<Either<Failure, MissionComplete>> postComplete(
    String attemptId,
  ) async {
    return right(
      const MissionComplete(
        streakCurrent: 1,
        xpTotal: 10,
        pipAbility: 'Pip can aim an arrow.',
        whyItMatters: 'A vector is a move.',
      ),
    );
  }

  @override
  Future<Either<Failure, void>> postResults({
    required String attemptId,
    required List<Map<String, dynamic>> results,
  }) {
    resultCalls += 1;
    return onResults();
  }

  @override
  Future<Either<Failure, void>> startAttempt({
    required String lessonId,
    required String attemptId,
  }) async {
    return right(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a timeout then a success posts twice and then stops', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    await database.upsertPack(
      version: 'v1',
      sha256: 'abc',
      body: '{"lessons": []}',
      downloadedAt: DateTime.utc(2026),
    );
    await database.insertOutbox(
      id: 'result-1',
      kind: 'item_results',
      createdAt: DateTime.utc(2026),
      payload: jsonEncode({
        'attemptId': 'attempt-1',
        'result': {
          'id': 'result-1',
          'screenId': 's',
          'correct': true,
          'latencyMs': 10,
          'errorCode': null,
          'hadMiss': false,
        },
      }),
    );
    var fail = true;
    final api = _Api(() async {
      if (fail) {
        fail = false;
        return left(const NetworkFailure('timeout'));
      }
      return right(null);
    });
    final worker = SyncWorker(
      database: database,
      api: api,
      online: () async => true,
    );

    await worker.run();
    await worker.run();
    expect(await database.outbox(), isEmpty);
    expect(api.resultCalls, 2);

    await worker.run();
    expect(api.resultCalls, 2);
  });

  test('a cached lesson opens when every request throws', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    const lessonId = '30000000-0000-4000-8000-0000000000aa';
    await database.upsertPack(
      version: 'v1',
      sha256: 'abc',
      body: jsonEncode({
        'lessons': [
          {
            'id': lessonId,
            'skillNodeId': '20000000-0000-4000-8000-0000000000aa',
            'title': 'Vector arrow',
            'version': 1,
            'capstone': false,
            'whyItMatters': 'A vector is a move.',
            'screens': [
              {
                'id': 'tail',
                'prompt': 'Where is the tail?',
                'primitive': {
                  'type': 'choice',
                  'options': [
                    {'id': 'a', 'label': 'Start'},
                    {'id': 'b', 'label': 'Tip'},
                  ],
                  'correctOptionId': 'a',
                },
                'feedback': {'wrong_option': 'The tail is the start.'},
                'easyWithinMs': 8000,
                'correctMessage': 'The tail stays put.',
              },
            ],
          },
        ],
      }),
      downloadedAt: DateTime.utc(2026),
    );
    final launcher = DriftLessonLauncher(
      database: database,
      api: _Api(() => throw StateError('offline')),
      online: () async => true,
    );
    final opened = await launcher.open(
      const PathNode(
        id: 'skill',
        title: 'Arrow',
        promise: 'Aim',
        pipAbility: 'Pip can aim an arrow.',
        rank: 0,
        lane: 'left',
        state: 'available',
        lessonId: lessonId,
      ),
    );
    final launch = opened.getOrElse(
      (failure) => throw StateError(failure.message),
    );
    expect(launch.lesson.title, 'Vector arrow');
  });

  test('an online miss downloads the current pack', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    const lessonId = '30000000-0000-4000-8000-0000000000aa';
    final api = _Api(
      () async => right(null),
      pack: jsonEncode({
        'lessons': [
          {
            'id': lessonId,
            'skillNodeId': '20000000-0000-4000-8000-0000000000aa',
            'title': 'Vector arrow',
            'version': 1,
            'capstone': false,
            'whyItMatters': 'A vector is a move.',
            'screens': [
              {
                'id': 'tail',
                'prompt': 'Where is the tail?',
                'primitive': {
                  'type': 'choice',
                  'options': [
                    {'id': 'a', 'label': 'Start'},
                    {'id': 'b', 'label': 'Tip'},
                  ],
                  'correctOptionId': 'a',
                },
                'feedback': {'wrong_option': 'The tail is the start.'},
                'easyWithinMs': 8000,
                'correctMessage': 'The tail stays put.',
              },
            ],
          },
        ],
      }),
    );
    final launcher = DriftLessonLauncher(
      database: database,
      api: api,
      online: () async => true,
    );
    final opened = await launcher.open(
      const PathNode(
        id: 'skill',
        title: 'Arrow',
        promise: 'Aim',
        pipAbility: 'Pip can aim an arrow.',
        rank: 0,
        lane: 'left',
        state: 'available',
        lessonId: lessonId,
      ),
    );
    final launch = opened.getOrElse(
      (failure) => throw StateError(failure.message),
    );
    expect(launch.lesson.title, 'Vector arrow');
    expect((await database.latestPack())?.sha256, 'abc');
  });

  test('a 409 drops the outbox row', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    await database.upsertPack(
      version: 'v1',
      sha256: 'abc',
      body: '{"lessons": []}',
      downloadedAt: DateTime.utc(2026),
    );
    await database.insertOutbox(
      id: 'result-1',
      kind: 'item_results',
      createdAt: DateTime.utc(2026),
      payload: jsonEncode({
        'attemptId': 'attempt-1',
        'result': {
          'id': 'result-1',
          'screenId': 's',
          'correct': true,
          'latencyMs': 10,
          'errorCode': null,
          'hadMiss': false,
        },
      }),
    );
    final api = _Api(
      () async => left(const HttpFailure(statusCode: 409, message: 'exists')),
    );
    final worker = SyncWorker(
      database: database,
      api: api,
      online: () async => true,
    );

    await worker.run();
    expect(await database.outbox(), isEmpty);
  });
}

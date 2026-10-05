import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Local pack cache, outbox, and attempt ids. The bearer token stays out.
class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.executor);

  /// In-memory database for tests.
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  /// File database used by the app.
  factory AppDatabase.file() {
    return AppDatabase(
      LazyDatabase(() async {
        final dir = await getApplicationDocumentsDirectory();
        final file = File(p.join(dir.path, 'axiom.sqlite'));
        return NativeDatabase(file);
      }),
    );
  }

  @override
  int get schemaVersion => 1;

  @override
  // Drift's base class exposes this getter without type arguments.
  // ignore: strict_raw_type
  Iterable<TableInfo> get allTables => <TableInfo>[];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      await customStatement(
        'CREATE TABLE pack_cache ('
        ' version TEXT PRIMARY KEY,'
        ' sha256 TEXT NOT NULL,'
        ' body TEXT NOT NULL,'
        ' downloaded_at INTEGER NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE outbox ('
        ' id TEXT PRIMARY KEY,'
        ' kind TEXT NOT NULL,'
        ' payload TEXT NOT NULL,'
        ' created_at INTEGER NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE attempt_local ('
        ' id TEXT PRIMARY KEY,'
        ' lesson_id TEXT NOT NULL,'
        ' started_at INTEGER NOT NULL,'
        ' completed_at INTEGER)',
      );
    },
  );

  Future<PackCacheRow?> pack(String version) async {
    final rows = await customSelect(
      'SELECT version, sha256, body, downloaded_at FROM pack_cache '
      'WHERE version = ?',
      variables: [Variable.withString(version)],
    ).get();
    if (rows.isEmpty) return null;
    return PackCacheRow.fromRow(rows.first);
  }

  Future<PackCacheRow?> latestPack() async {
    final rows = await customSelect(
      'SELECT version, sha256, body, downloaded_at FROM pack_cache '
      'ORDER BY downloaded_at DESC LIMIT 1',
    ).get();
    if (rows.isEmpty) return null;
    return PackCacheRow.fromRow(rows.first);
  }

  Future<void> upsertPack({
    required String version,
    required String sha256,
    required String body,
    required DateTime downloadedAt,
  }) {
    return customStatement(
      'INSERT INTO pack_cache (version, sha256, body, downloaded_at) '
      'VALUES (?, ?, ?, ?) '
      'ON CONFLICT(version) DO UPDATE SET '
      'sha256 = excluded.sha256, body = excluded.body, '
      'downloaded_at = excluded.downloaded_at',
      [
        version,
        sha256,
        body,
        downloadedAt.millisecondsSinceEpoch,
      ],
    );
  }

  Future<void> insertOutbox({
    required String id,
    required String kind,
    required String payload,
    required DateTime createdAt,
  }) {
    return customStatement(
      'INSERT OR REPLACE INTO outbox (id, kind, payload, created_at) '
      'VALUES (?, ?, ?, ?)',
      [id, kind, payload, createdAt.millisecondsSinceEpoch],
    );
  }

  Future<List<OutboxRow>> outbox() async {
    final rows = await customSelect(
      'SELECT id, kind, payload, created_at FROM outbox ORDER BY created_at',
    ).get();
    return rows.map(OutboxRow.fromRow).toList();
  }

  Future<void> deleteOutbox(String id) {
    return customStatement('DELETE FROM outbox WHERE id = ?', [id]);
  }

  Future<void> insertAttempt({
    required String id,
    required String lessonId,
    required DateTime startedAt,
  }) {
    return customStatement(
      'INSERT OR REPLACE INTO attempt_local '
      '(id, lesson_id, started_at, completed_at) VALUES (?, ?, ?, NULL)',
      [id, lessonId, startedAt.millisecondsSinceEpoch],
    );
  }
}

/// One cached content pack.
class PackCacheRow {
  const PackCacheRow({
    required this.version,
    required this.sha256,
    required this.body,
  });

  /// Reads a row from Drift.
  factory PackCacheRow.fromRow(QueryRow row) {
    return PackCacheRow(
      version: row.read<String>('version'),
      sha256: row.read<String>('sha256'),
      body: row.read<String>('body'),
    );
  }

  final String version;
  final String sha256;
  final String body;
}

/// One queued fact.
class OutboxRow {
  const OutboxRow({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAt,
  });

  /// Reads a row from Drift.
  factory OutboxRow.fromRow(QueryRow row) {
    return OutboxRow(
      id: row.read<String>('id'),
      kind: row.read<String>('kind'),
      payload: row.read<String>('payload'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('created_at'),
      ),
    );
  }

  final String id;
  final String kind;
  final String payload;
  final DateTime createdAt;
}

import 'dart:async';

import 'package:axiom/core/telemetry.dart';
import 'package:axiom/features/auth/application/auth_providers.dart';
import 'package:axiom/features/content_sync/application/lesson_launcher.dart';
import 'package:axiom/features/content_sync/application/sync_worker.dart';
import 'package:axiom/features/content_sync/data/http_sync_api.dart';
import 'package:axiom/features/content_sync/data/local_database.dart';
import 'package:axiom/features/path/data/path_repository.dart';
import 'package:axiom/features/path/data/placement_repository.dart';
import 'package:axiom/features/path/data/profile_repository.dart';
import 'package:axiom/features/path/domain/path_models.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:logger/logger.dart';

/// IANA timezone for the daily streak.
abstract class TimezoneSource {
  Future<String> iana();
}

/// Device timezone, stored as an IANA id.
class DeviceTimezoneSource implements TimezoneSource {
  @override
  Future<String> iana() async {
    final info = await FlutterTimezone.getLocalTimezone();
    return info.identifier;
  }
}

/// Whether the phone can reach the API.
abstract class NetworkStatus {
  Future<bool> online();
}

/// connectivity_plus, treating "none" as offline.
class PluginNetworkStatus implements NetworkStatus {
  @override
  Future<bool> online() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }
}

/// Quiet sync state for the path app bar.
class SyncSnapshot {
  const SyncSnapshot({this.running = false, this.message});

  final bool running;
  final String? message;
}

/// Runs [SyncWorker] on launch and when the network returns.
class SyncController extends Notifier<SyncSnapshot> {
  @override
  SyncSnapshot build() {
    final subscription = Connectivity().onConnectivityChanged.listen((_) {
      unawaited(run());
    });
    ref.onDispose(subscription.cancel);
    unawaited(run());
    return const SyncSnapshot();
  }

  Future<void> run() async {
    state = const SyncSnapshot(running: true);
    final status = await ref.read(syncWorkerProvider).run();
    final failed = status == SyncStatus.failed;
    state = SyncSnapshot(
      message: failed
          ? 'Sync paused. Your lesson is saved on this phone.'
          : null,
    );
    if (failed) {
      unawaited(ref.read(telemetryProvider).capture('sync_failed'));
    }
  }

  void dismiss() => state = const SyncSnapshot();
}

final timezoneSourceProvider = Provider<TimezoneSource>(
  (ref) => DeviceTimezoneSource(),
);

final telemetryProvider = Provider<AppTelemetry>((ref) => const AppTelemetry());

final networkStatusProvider = Provider<NetworkStatus>(
  (ref) => PluginNetworkStatus(),
);

final localDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.file();
  ref.onDispose(database.close);
  return database;
});

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => HttpProfileRepository(ref.watch(dioProvider)),
);

final pathRepositoryProvider = Provider<PathRepository>(
  (ref) => HttpPathRepository(ref.watch(dioProvider)),
);

final placementRepositoryProvider = Provider<PlacementRepository>(
  (ref) => HttpPlacementRepository(ref.watch(dioProvider)),
);

final syncApiProvider = Provider<SyncApi>(
  (ref) => HttpSyncApi(ref.watch(dioProvider)),
);

final syncWorkerProvider = Provider<SyncWorker>((ref) {
  return SyncWorker(
    database: ref.watch(localDatabaseProvider),
    api: ref.watch(syncApiProvider),
    online: ref.watch(networkStatusProvider).online,
    log: Logger(level: kDebugMode ? Level.info : Level.warning),
    onRefreshed: () async {
      ref
        ..invalidate(pathNodesProvider)
        ..invalidate(profileSummaryProvider);
    },
  );
});

final syncControllerProvider = NotifierProvider<SyncController, SyncSnapshot>(
  SyncController.new,
);

final lessonLauncherProvider = Provider<LessonLauncher>((ref) {
  return DriftLessonLauncher(
    database: ref.watch(localDatabaseProvider),
    api: ref.watch(syncApiProvider),
    online: ref.watch(networkStatusProvider).online,
  );
});

final lessonSubmitterProvider = Provider<LessonSubmitter>((ref) {
  return OutboxLessonSubmitter(
    database: ref.watch(localDatabaseProvider),
    worker: ref.watch(syncWorkerProvider),
    cachedStreak: () {
      final summary = ref.read(profileSummaryProvider).asData?.value;
      return summary?.streakCurrent ?? 0;
    },
  );
});

// FutureProvider's typedef is noisy next to the explicit type arguments.
// ignore: specify_nonobvious_property_types
final pathNodesProvider = FutureProvider.autoDispose<List<PathNode>>((
  ref,
) async {
  final result = await ref.watch(pathRepositoryProvider).load();
  return result.fold((failure) => throw Exception(failure.message), (nodes) {
    return nodes;
  });
});

// FutureProvider's typedef is noisy next to the explicit type arguments.
// ignore: specify_nonobvious_property_types
final profileSummaryProvider = FutureProvider.autoDispose<ProfileSummary>((
  ref,
) async {
  final result = await ref.watch(profileRepositoryProvider).summary();
  return result.fold((failure) => throw Exception(failure.message), (summary) {
    return summary;
  });
});

/// Haptics on a correct check. The profile page is the switch.
class HapticsSetting extends Notifier<bool> {
  @override
  bool build() => true;

  // setEnabled is a method so the profile switch can pass the new value.
  // ignore: use_setters_to_change_properties
  void setEnabled({required bool enabled}) => state = enabled;
}

final hapticsEnabledProvider = NotifierProvider<HapticsSetting, bool>(
  HapticsSetting.new,
);

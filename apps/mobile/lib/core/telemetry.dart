import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Product events and error reports. Both stay quiet without a key.
class AppTelemetry {
  const AppTelemetry();

  static const dsn = String.fromEnvironment('SENTRY_DSN');
  static const posthogKey = String.fromEnvironment('POSTHOG_KEY');
  static const release = String.fromEnvironment(
    'GIT_SHA',
    defaultValue: 'dev',
  );

  Future<void> start() async {
    if (dsn.isNotEmpty) {
      await SentryFlutter.init((options) {
        options
          ..dsn = dsn
          ..release = release;
      });
    }
    if (posthogKey.isNotEmpty) {
      await Posthog().setup(PostHogConfig(posthogKey));
    }
  }

  Future<void> capture(
    String event, {
    Map<String, Object>? properties,
  }) async {
    if (posthogKey.isEmpty) return;
    await Posthog().capture(eventName: event, properties: properties);
  }

  Future<void> check() async {
    if (dsn.isEmpty) return;
    await Sentry.captureException(Exception('axiom-sentry-check'));
  }
}

/// Debug-only sentry check. Production startup does not call this.
Future<void> debugSentryCheck() async {
  if (!kDebugMode) return;
  await const AppTelemetry().check();
}

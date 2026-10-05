import 'dart:async';

import 'package:axiom/app/app.dart';
import 'package:axiom/core/telemetry.dart';
import 'package:axiom/features/auth/application/auth_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Starts the widget tree after the binding is ready.
void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  assert(apiBaseUrl.isNotEmpty, 'API_BASE_URL is required');
  unawaited(const AppTelemetry().start());
  runApp(const ProviderScope(child: AxiomApp()));
}

import 'package:axiom/app/app.dart';
import 'package:axiom/app/bootstrap.dart';
import 'package:axiom/features/auth/application/auth_providers.dart';
import 'package:flutter/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (apiBaseUrl.isEmpty) {
    assert(false, 'API_BASE_URL is required');
    runApp(const MissingConfigApp());
    return;
  }
  bootstrap();
}

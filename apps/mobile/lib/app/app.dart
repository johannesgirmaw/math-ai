import 'package:axiom/app/router.dart';
import 'package:axiom/core/ui/app_theme.dart';
import 'package:axiom/core/ui/brand_lockup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root widget. Routes come from the session.
class AxiomApp extends ConsumerWidget {
  const AxiomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'MATH SI',
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}

/// Shown when the API origin was not compiled into the app.
class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MATH SI',
      theme: AppTheme.light(),
      home: const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BrandLockup(height: 160),
                SizedBox(height: 24),
                Text(
                  'API_BASE_URL is required. Run with '
                  '--dart-define=API_BASE_URL=http://127.0.0.1:3000',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

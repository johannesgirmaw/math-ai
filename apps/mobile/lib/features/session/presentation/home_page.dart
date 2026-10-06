import 'dart:async';

import 'package:axiom/core/ui/brand_lockup.dart';
import 'package:axiom/features/auth/application/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Signed-in landing screen.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final name = session.asData?.value?.displayName ?? '';
    return Scaffold(
      appBar: brandAppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(name, style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  unawaited(
                    ref.read(sessionControllerProvider.notifier).signOut(),
                  );
                },
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

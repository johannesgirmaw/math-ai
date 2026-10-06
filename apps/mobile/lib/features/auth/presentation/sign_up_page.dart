import 'package:axiom/core/ui/app_theme.dart';
import 'package:axiom/core/ui/brand_lockup.dart';
import 'package:axiom/features/auth/application/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Creates a learner account.
class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    if (name.isEmpty) {
      setState(() => _error = 'Enter your name.');
      return;
    }
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Use at least 8 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final message = await ref
        .read(sessionControllerProvider.notifier)
        .signUp(email: email, password: password, name: name);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                key: const Key('sign-up-back'),
                tooltip: 'Back',
                onPressed: () => context.go('/sign-in'),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            const Center(child: BrandLockup()),
            const SizedBox(height: 12),
            const SizedBox(
              height: 2,
              width: double.infinity,
              child: ColoredBox(color: AxiomColors.gold),
            ),
            const SizedBox(height: 24),
            Text(
              'Create account',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Creating' : 'Create account'),
            ),
            TextButton(
              onPressed: () => context.go('/sign-in'),
              child: const Text('I already have an account'),
            ),
          ],
        ),
      ),
    );
  }
}

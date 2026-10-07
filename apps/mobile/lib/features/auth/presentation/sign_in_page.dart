import 'package:axiom/core/ui/app_theme.dart';
import 'package:axiom/core/ui/brand_lockup.dart';
import 'package:axiom/features/auth/application/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Email and password sign-in.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _emailError;
  String? _passwordError;
  String? _formError;
  var _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Enter your email.';
        _passwordError = null;
        _formError = null;
      });
      return;
    }
    if (password.isEmpty) {
      setState(() {
        _emailError = null;
        _passwordError = 'Enter your password.';
        _formError = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _emailError = null;
      _passwordError = null;
      _formError = null;
    });
    final message = await ref
        .read(sessionControllerProvider.notifier)
        .signIn(email: email, password: password);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _formError = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            const Center(child: BrandLockup(symbolSize: 96)),
            const SizedBox(height: 12),
            const SizedBox(
              height: 2,
              width: double.infinity,
              child: ColoredBox(color: AxiomColors.gold),
            ),
            const SizedBox(height: 16),
            Text(
              'Function of SI',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AxiomColors.accent,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to continue the path.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('create-account'),
              onPressed: () => context.go('/sign-up'),
              child: const Text('Create an account'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: _emailError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: _passwordError,
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 12),
              Text(
                _formError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('sign-in-submit'),
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Signing in' : 'Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}

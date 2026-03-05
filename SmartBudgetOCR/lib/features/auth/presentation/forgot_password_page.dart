import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input.dart';
import '../../../core/router/app_router.dart';
import '../../../core/di/service_locator.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Please enter your email');
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await ServiceLocator.auth.sendPasswordResetEmail(email);
      if (mounted) {
        setState(() => _message = 'Password reset email sent');
      }
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Forgot password',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextInput(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(
                  _message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                onPressed: _loading ? null : _sendReset,
                loading: _loading,
                child: const Text('Send reset link'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading ? null : () => context.go(AppRouter.login),
                child: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

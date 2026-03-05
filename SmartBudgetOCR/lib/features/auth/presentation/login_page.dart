import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input.dart';

/// Login page. UI only - auth logic in AuthService.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ServiceLocator.auth.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) context.go(AppRouter.homeDashboard);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await ServiceLocator.auth.signInWithGoogle();
      if (cred != null && mounted) {
        context.go(AppRouter.homeDashboard);
      } else if (mounted) {
        setState(() => _error = 'Sign in cancelled');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // subtle background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF673AB7), Color(0xFF3F51B5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTokens.s24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.all(AppTokens.s24),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: AppTokens.cardRadius,
                      boxShadow: AppTokens.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: AppLogo(size: 52)),
                        const SizedBox(height: AppTokens.s16),
                        Text(
                          'Welcome back',
                          style: t.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTokens.s8),
                        Text(
                          'Sign in to manage your expenses.',
                          style: t.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTokens.s24),
                        TextInput(
                          controller: _emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          enabled: !_loading,
                        ),
                        const SizedBox(height: AppTokens.s12),
                        TextInput(
                          controller: _passwordController,
                          label: 'Password',
                          obscure: true,
                          autofillHints: const [AutofillHints.password],
                          enabled: !_loading,
                        ),
                        const SizedBox(height: AppTokens.s8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed:
                                _loading ? null : () => context.go(AppRouter.forgot),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: AppTokens.s8),
                          Text(
                            _error!,
                            style: t.textTheme.bodySmall?.copyWith(
                              color: t.colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: AppTokens.s16),
                        PrimaryButton(
                          onPressed: _loading ? null : _signInWithEmail,
                          loading: _loading,
                          child: const Text('Sign In'),
                        ),
                        const SizedBox(height: AppTokens.s12),
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _signInWithGoogle,
                          icon: const Icon(Icons.g_mobiledata),
                          label: const Text('Continue with Google'),
                        ),
                        const SizedBox(height: AppTokens.s12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'New here?',
                              style: t.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            TextButton(
                              onPressed: _loading ? null : () => context.go(AppRouter.signup),
                              child: const Text('Create account'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

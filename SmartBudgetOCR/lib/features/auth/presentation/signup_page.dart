import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input.dart';
import '../../../core/router/app_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_logo.dart';

/// Sign-up page with additional profile fields. After creating
/// a Firebase user the profile is saved to Firestore under `users/{uid}`.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmController.text;

    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await ServiceLocator.auth.signUpWithEmail(
        email: email,
        password: pass,
      );
      final uid = cred?.user?.uid;
      if (uid != null) {
        // Save profile to Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': name,
          'phone': phone,
          'email': email,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) context.go(AppRouter.homeDashboard);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await ServiceLocator.auth.signInWithGoogle();
      if (!mounted) return;
      if (cred == null) {
        setState(() => _error = 'Sign in cancelled');
        return;
      }
      // TODO: connect backend API (optional: create Firestore profile on first login)
      context.go(AppRouter.homeDashboard);
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
            // background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEFF6FF), AppColors.background],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTokens.s24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Container(
                    padding: const EdgeInsets.all(AppTokens.s24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTokens.cardRadius,
                      boxShadow: AppTokens.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: AppLogo(size: 52)),
                        const SizedBox(height: AppTokens.s16),
                        Text(
                          'Create your account',
                          style: t.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTokens.s8),
                        Text(
                          'Start tracking expenses with OCR-powered receipts.',
                          style: t.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTokens.s24),
                        TextInput(
                          controller: _nameController,
                          label: 'Full Name',
                          autofillHints: const [AutofillHints.name],
                          enabled: !_loading,
                        ),
                        const SizedBox(height: AppTokens.s12),
                        TextInput(
                          controller: _phoneController,
                          label: 'Phone Number',
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          enabled: !_loading,
                        ),
                        const SizedBox(height: AppTokens.s12),
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
                          autofillHints: const [AutofillHints.newPassword],
                          enabled: !_loading,
                        ),
                        const SizedBox(height: AppTokens.s12),
                        TextInput(
                          controller: _confirmController,
                          label: 'Confirm Password',
                          obscure: true,
                          autofillHints: const [AutofillHints.newPassword],
                          enabled: !_loading,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: AppTokens.s12),
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
                          onPressed: _loading ? null : _signUp,
                          loading: _loading,
                          child: const Text('Create Account'),
                        ),
                        const SizedBox(height: AppTokens.s12),
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _signUpWithGoogle,
                          icon: const Icon(Icons.g_mobiledata),
                          label: const Text('Continue with Google'),
                        ),
                        const SizedBox(height: AppTokens.s12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: t.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => context.go(AppRouter.login),
                              child: const Text('Log in'),
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

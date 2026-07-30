import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../providers/bike_provider.dart';
import '../../../../widgets/common/primary_button.dart';
import '../widgets/auth_text_field.dart';

// Auth Form State
class AuthFormState {
  final bool isLogin;
  final bool isLoading;
  final bool obscurePassword;
  final String? errorMessage;

  AuthFormState({
    this.isLogin = true,
    this.isLoading = false,
    this.obscurePassword = true,
    this.errorMessage,
  });

  AuthFormState copyWith({
    bool? isLogin,
    bool? isLoading,
    bool? obscurePassword,
    String? errorMessage,
  }) {
    return AuthFormState(
      isLogin: isLogin ?? this.isLogin,
      isLoading: isLoading ?? this.isLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      errorMessage: errorMessage,
    );
  }
}

class AuthFormNotifier extends AutoDisposeNotifier<AuthFormState> {
  @override
  AuthFormState build() => AuthFormState();

  void toggleMode() => state = state.copyWith(isLogin: !state.isLogin, errorMessage: null);
  void toggleObscure() => state = state.copyWith(obscurePassword: !state.obscurePassword);
  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
  void setError(String? error) => state = state.copyWith(errorMessage: error);
}

final authFormProvider = NotifierProvider.autoDispose<AuthFormNotifier, AuthFormState>(AuthFormNotifier.new);

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authFormProvider);
    final authNotifier = ref.read(authFormProvider.notifier);

    final emailCtrl = ref.watch(_emailControllerProvider);
    final passCtrl = ref.watch(_passControllerProvider);
    final confirmCtrl = ref.watch(_confirmControllerProvider);

    Future<void> submit() async {
      final email = emailCtrl.text.trim();
      final password = passCtrl.text;
      final confirm = confirmCtrl.text;

      if (email.isEmpty || password.isEmpty) {
        authNotifier.setError('Please fill in all fields.');
        return;
      }

      authNotifier.setLoading(true);
      authNotifier.setError(null);

      try {
        if (authState.isLogin) {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email, password: password,
          );
        } else {
          if (password != confirm) {
            authNotifier.setError('Passwords do not match.');
            authNotifier.setLoading(false);
            return;
          }
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email, password: password,
          );
        }
        
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await ref.read(bikeProvider.notifier).initialize(user.uid);
          if (context.mounted) context.go(AppRoutes.dashboard);
        }
      } on FirebaseAuthException catch (e) {
        authNotifier.setError(e.message ?? 'Authentication failed');
        authNotifier.setLoading(false);
      } catch (e) {
        authNotifier.setError('Something went wrong');
        authNotifier.setLoading(false);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              _buildLogo(theme),
              const SizedBox(height: 40),
              Text(
                authState.isLogin ? 'Welcome back,\nRider.' : 'Join the\npack.',
                style: theme.textTheme.displayLarge,
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
              const SizedBox(height: 8),
              Text(
                authState.isLogin
                    ? 'Sign in to track your bike expenses.'
                    : 'Create an account to get started.',
                style: theme.textTheme.bodyMedium,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 48),
              
              AuthTextField(
                controller: emailCtrl,
                label: 'Email Address',
                hintText: 'rider@example.com',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 20),
              
              AuthTextField(
                controller: passCtrl,
                label: 'Password',
                hintText: '••••••••',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                obscureText: authState.obscurePassword,
                onToggleObscure: authNotifier.toggleObscure,
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
              
              if (!authState.isLogin) ...[
                const SizedBox(height: 20),
                AuthTextField(
                  controller: confirmCtrl,
                  label: 'Confirm Password',
                  hintText: '••••••••',
                  prefixIcon: Icons.lock_reset_rounded,
                  isPassword: true,
                  obscureText: true,
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
              ],
              
              if (authState.isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password?',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                
              const SizedBox(height: 32),
              
              if (authState.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          authState.errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ).animate().shake(),

              PrimaryButton(
                label: authState.isLogin ? 'Ride In' : 'Join Now',
                isLoading: authState.isLoading,
                onPressed: submit,
              ).animate().fadeIn(delay: 700.ms).scale(begin: const Offset(0.9, 0.9)),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    authState.isLogin ? "Don't have an account? " : "Already have an account? ",
                    style: theme.textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: authNotifier.toggleMode,
                    child: Text(
                      authState.isLogin ? 'Sign Up' : 'Sign In',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.two_wheeler_rounded, color: Colors.black, size: 28),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MOTO LOGG',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            Text(
              'TRACK EVERYTHING',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.2);
  }
}

final _emailControllerProvider = Provider.autoDispose((ref) => TextEditingController());
final _passControllerProvider = Provider.autoDispose((ref) => TextEditingController());
final _confirmControllerProvider = Provider.autoDispose((ref) => TextEditingController());

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
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

class AuthFormNotifier extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => AuthFormState();

  void toggleMode() => state = state.copyWith(isLogin: !state.isLogin, errorMessage: null);
  void toggleObscure() => state = state.copyWith(obscurePassword: !state.obscurePassword);
  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
  void setError(String? error) => state = state.copyWith(errorMessage: error);
}

final authFormProvider = NotifierProvider<AuthFormNotifier, AuthFormState>(AuthFormNotifier.new);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _confirmCtrl;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController();
    _passCtrl = TextEditingController();
    _confirmCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Account not found or password incorrect.\nIf you are new here, tap "Sign Up" below to create an account!';
      case 'email-already-in-use':
        return 'This email is already registered.\nTap "Sign In" below to log in.';
      case 'invalid-email':
        return 'Please enter a valid email address (e.g. name@gmail.com).';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled in Firebase Console.';
      default:
        return e.message ?? 'Authentication failed. Please check your credentials.';
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final authState = ref.read(authFormProvider);
    final authNotifier = ref.read(authFormProvider.notifier);

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      authNotifier.setError('Please fill in both email and password.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both email and password.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!authState.isLogin && password != confirm) {
      authNotifier.setError('Passwords do not match.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    authNotifier.setLoading(true);
    authNotifier.setError(null);

    try {
      if (authState.isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await ref.read(bikeProvider.notifier).initialize(user.uid);
        if (mounted) {
          context.go(AppRoutes.dashboard);
        }
      }
    } on FirebaseAuthException catch (e) {
      final friendlyMsg = _friendlyAuthError(e);
      authNotifier.setError(friendlyMsg);
      authNotifier.setLoading(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMsg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      const genericMsg = 'Something went wrong. Please check your connection and try again.';
      authNotifier.setError(genericMsg);
      authNotifier.setLoading(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(genericMsg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address to reset password.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to $email.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Failed to send reset email.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authFormProvider);
    final authNotifier = ref.read(authFormProvider.notifier);

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
                controller: _emailCtrl,
                label: 'Email Address',
                hintText: 'rider@example.com',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 20),

              AuthTextField(
                controller: _passCtrl,
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
                  controller: _confirmCtrl,
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
                    onPressed: _handleForgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              if (authState.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (authState.isLogin && authState.errorMessage!.contains('Sign Up')) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              authNotifier.toggleMode();
                            },
                            child: Text(
                              'Switch to Sign Up',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ).animate().shake(),

              PrimaryButton(
                label: authState.isLogin ? 'Ride In' : 'Join Now',
                isLoading: authState.isLoading,
                onPressed: _submit,
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
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.2);
  }
}

// ═══════════════════════════════════════════════════════════
//  MOTO LOGG — Login Screen
//  Firebase Email/Password Auth  |  Dark Biker Theme
//  File: lib/login_screen.dart
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── Theme constants (mirrors main.dart) ──────────────────
const _bg         = Color(0xFF0D0D0D);
const _cardBg     = Color(0xFF1A1A1A);
const _iconBg     = Color(0xFF222222);
const _textPrimary   = Colors.white;
const _textSecondary = Color(0xFFAAAAAA);
const _textDim       = Color(0xFF666666);
const _border        = Color(0xFF2A2A2A);

// ──────────────────────────────────────────────────────────
// LOGIN SCREEN
// ──────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  // ── State ──────────────────────────────────────────────
  bool _isLogin = true;   // toggle Login ↔ Sign Up
  bool _loading  = false;
  bool _obscure  = true;
  String? _error;

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double>    _fadeAnim;
  late final Animation<Offset>    _slideAnim;

  // ── Init / Dispose ─────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Auth helpers ────────────────────────────────────────
  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });

    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm  = _confirmCtrl.text;

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      _setError('Please fill in all fields.');
      return;
    }
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(email)) {
      _setError('Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      _setError('Password must be at least 6 characters.');
      return;
    }
    if (!_isLogin && password != confirm) {
      _setError('Passwords do not match.');
      return;
    }

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email, password: password,
        );
      }
      // AuthWrapper in main.dart will automatically navigate away
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
    } catch (e) {
      _setError('Something went wrong. Try again.');
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _cardBg,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text(
              'Reset link sent — check your inbox.',
              style: TextStyle(color: _textPrimary, fontSize: 13),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
    }
  }

  void _setError(String msg) {
    setState(() { _error = msg; _loading = false; });
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':        return 'No account found for this email.';
      case 'wrong-password':        return 'Incorrect password.';
      case 'email-already-in-use':  return 'Email is already registered.';
      case 'invalid-email':         return 'Invalid email address.';
      case 'weak-password':         return 'Password is too weak.';
      case 'too-many-requests':     return 'Too many attempts. Try later.';
      case 'network-request-failed':return 'No internet connection.';
      default:                      return 'Authentication failed. Try again.';
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error   = null;
      _confirmCtrl.clear();
    });
    _animCtrl
      ..reset()
      ..forward();
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // ── Logo / Brand ──────────────────────────
                  _Logo(),

                  const SizedBox(height: 40),

                  // ── Heading ──────────────────────────────
                  Text(
                    _isLogin ? 'Welcome back,\nRider.' : 'Join the\npack.',
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin
                        ? 'Sign in to track your bike expenses.'
                        : 'Create an account to get started.',
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Email ─────────────────────────────────
                  _Label('EMAIL'),
                  const SizedBox(height: 8),
                  _AuthField(
                    controller: _emailCtrl,
                    hint: 'you@example.com',
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  // ── Password ──────────────────────────────
                  _Label('PASSWORD'),
                  const SizedBox(height: 8),
                  _AuthField(
                    controller: _passwordCtrl,
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscure,
                    suffix: GestureDetector(
                      onTap: () => setState(() => _obscure = !_obscure),
                      child: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _textDim,
                        size: 18,
                      ),
                    ),
                  ),

                  // ── Confirm Password (sign-up only) ───────
                  if (!_isLogin) ...[
                    const SizedBox(height: 16),
                    _Label('CONFIRM PASSWORD'),
                    const SizedBox(height: 8),
                    _AuthField(
                      controller: _confirmCtrl,
                      hint: '••••••••',
                      icon: Icons.lock_reset_rounded,
                      obscure: true,
                    ),
                  ],

                  // ── Forgot password (login only) ──────────
                  if (_isLogin) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _forgotPassword,
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                            decorationColor: _textDim,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ── Error message ─────────────────────────
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1010),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF3A2020)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Color(0xFF888888), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                  color: Color(0xFFAAAAAA), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Primary CTA ───────────────────────────
                  GestureDetector(
                    onTap: _loading ? null : _submit,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _loading ? _iconBg : _textPrimary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _textDim,
                          ),
                        )
                            : Text(
                          _isLogin ? 'Ride In →' : 'Create Account →',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Toggle mode ───────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? "Don't have an account? "
                            : 'Already have an account? ',
                        style: const TextStyle(
                            color: _textDim, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: _toggleMode,
                        child: Text(
                          _isLogin ? 'Sign Up' : 'Sign In',
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: _textDim,
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
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// LOGO WIDGET
// ──────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _textPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.two_wheeler_rounded,
            color: Colors.black,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MOTO LOGG',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
            Text(
              'Track Everything',
              style: TextStyle(
                color: _textDim,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// REUSABLE LABEL
// ──────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: _textDim,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.8,
    ),
  );
}

// ──────────────────────────────────────────────────────────
// REUSABLE AUTH FIELD
// ──────────────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: _textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textDim, fontSize: 13),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, color: _textDim, size: 18),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffix != null
            ? Padding(
          padding: const EdgeInsets.only(right: 14),
          child: suffix,
        )
            : null,
        suffixIconConstraints:
        const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: _iconBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF555555), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 16,
        ),
      ),
    );
  }
}
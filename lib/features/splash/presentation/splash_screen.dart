import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/kk_theme_context.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _showBiometricButton = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(CheckAuthStatus());
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Verify your identity to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuth && mounted) {
        context.read<AuthBloc>().add(BiometricLoginRequested());
      }
    } catch (e) {
      if (mounted) {
        final p = context.palette;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric error: $e'),
            backgroundColor: p.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.txt;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go('/home');
        } else if (state is BiometricAuthRequired) {
          setState(() => _showBiometricButton = true);
          _authenticateWithBiometric();
        } else if (state is Unauthenticated || state is AuthError) {
          context.go('/login');
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: p.accentGradient,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: p.accent.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shield_rounded,
                  size: 64,
                  color: p.textOnAccentButton,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.15, 1.15),
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 28),
              Text(
                'KryptoKart',
                style: t.display.copyWith(
                  fontSize: 32,
                  color: p.textPrimary,
                ),
              ).animate().fadeIn(duration: 600.ms),
              const SizedBox(height: 8),
              Text(
                'Scan. Pay. Track.',
                style: t.body.copyWith(color: p.textSecondary),
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
              const SizedBox(height: 48),
              if (_showBiometricButton) ...[
                GestureDetector(
                  onTap: _authenticateWithBiometric,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: p.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: p.accent.withValues(alpha: 0.3)),
                    ),
                    child: Icon(Icons.fingerprint, size: 40, color: p.accent),
                  ),
                ).animate().fadeIn().scale(),
                const SizedBox(height: 12),
                Text(
                  'Tap to authenticate',
                  style: t.caption.copyWith(color: p.textSecondary),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text(
                    'Use password instead',
                    style: t.caption.copyWith(
                      color: p.accent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ] else
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: p.accent,
                    strokeWidth: 2.5,
                  ),
                ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}

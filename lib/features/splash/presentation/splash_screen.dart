import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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

  /// Prompt fingerprint / face ID and navigate on success.
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric error: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go('/home');
        } else if (state is BiometricAuthRequired) {
          // Prompt biometric immediately
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
              // Pulsing logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_rounded, size: 64, color: AppColors.background),
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
                style: AppTextStyles.display.copyWith(
                  fontSize: 32,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 600.ms),

              const SizedBox(height: 8),

              Text(
                'Scan. Pay. Track.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

              const SizedBox(height: 48),

              // Show fingerprint icon + retry button when biometric is required
              if (_showBiometricButton) ...[
                GestureDetector(
                  onTap: _authenticateWithBiometric,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.fingerprint, size: 40, color: AppColors.accent),
                  ),
                ).animate().fadeIn().scale(),

                const SizedBox(height: 12),

                Text(
                  'Tap to authenticate',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 24),

                // Skip biometric → go to login
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text(
                    'Use password instead',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ] else
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
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

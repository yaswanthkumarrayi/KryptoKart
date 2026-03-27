import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kk_button.dart';
import '../../../core/widgets/kk_text_field.dart';
import '../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(LoginRequested(
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.go('/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.red,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shield_rounded, size: 44, color: AppColors.background),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOut),

                  const SizedBox(height: 20),

                  Text('KryptoKart', style: AppTextStyles.display.copyWith(color: AppColors.accent))
                      .animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 8),

                  Text(
                    'Your unified fintech ecosystem',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 40),

                  // Login form
                  GlassCard(
                    child: Column(
                      children: [
                        KkTextField(
                          label: 'Phone Number',
                          hint: 'Enter 10-digit phone number',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: Validators.validatePhone,
                          prefix: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('+91', style: AppTextStyles.bodyMedium),
                          ),
                        ),
                        const SizedBox(height: 20),
                        KkTextField(
                          label: 'Password',
                          hint: 'Enter your password',
                          controller: _passwordController,
                          obscure: _obscurePassword,
                          validator: Validators.validatePassword,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              'Forgot PIN?',
                              style: AppTextStyles.caption.copyWith(color: AppColors.accent),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // Login button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return KkButton(
                        label: 'Login',
                        onTap: _onLogin,
                        isLoading: state is AuthLoading,
                      );
                    },
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: AppTextStyles.caption),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Register button
                  KkButton(
                    label: 'Create Account',
                    onTap: () => context.push('/register'),
                    outlined: true,
                  ).animate().fadeIn(delay: 600.ms),

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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/kk_theme_context.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kk_button.dart';
import '../../../core/widgets/kk_text_field.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/wallet_display.dart';
import '../../../core/service_locator.dart';
import '../../../shared/services/wallet_service.dart';
import '../../../shared/services/api_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _upiController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agreedToTerms = false;
  String? _connectedWallet;
  String? _walletAddress;
  bool _isConnectingWallet = false;

  final _walletService = sl<WalletService>();
  final _apiService = sl<ApiService>();

  @override
  void initState() {
    super.initState();
    if (_walletService.isConnected) {
      _connectedWallet = _walletService.walletName;
      _walletAddress = _walletService.connectedAddress;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _upiController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to Terms of Service'),
          backgroundColor: context.palette.red,
        ),
      );
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(RegisterRequested(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            upiId: _upiController.text.trim().isEmpty ? null : _upiController.text.trim(),
            walletAddress: _walletAddress,
          ));
    }
  }

  Future<void> _connectMetaMask() async {
    setState(() => _isConnectingWallet = true);

    try {
      final address = await _walletService.connectMetaMask();

      if (mounted) {
        setState(() {
          _connectedWallet = 'MetaMask';
          _walletAddress = address;
          _isConnectingWallet = false;
        });

        if (_apiService.isAuthenticated) {
          try {
            await _apiService.updateWallet(address);
          } catch (_) {}
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'MetaMask connected: ${shortenWalletAddress(address)}',
              ),
              backgroundColor: context.palette.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnectingWallet = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: context.palette.red,
          ),
        );
      }
    }
  }

  void _connectPhantom() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phantom wallet coming soon. Use MetaMask.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.txt;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create Account'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (ctx, state) {
          if (state is Authenticated) {
            ctx.go('/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: ctx.palette.red,
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
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: p.surface2,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(Icons.shield_rounded, size: 40, color: p.accent),
                  ).animate().scale(duration: 500.ms),
                  const SizedBox(height: 16),
                  Text('Join the Revolution', style: t.display)
                      .animate()
                      .fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  Text(
                    "Secure your digital assets with KryptoKart's next-gen ecosystem.",
                    style: t.body.copyWith(color: p.textSecondary),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 30),
                  KkTextField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _nameController,
                    validator: Validators.validateName,
                  ).animate().fadeIn(delay: 350.ms),
                  const SizedBox(height: 20),
                  KkTextField(
                    label: 'Phone Number',
                    hint: 'Enter 10-digit phone number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                    prefix: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: p.surface2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('+91', style: t.bodyMedium),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 20),
                  KkTextField(
                    label: 'Password',
                    hint: 'Create a password',
                    controller: _passwordController,
                    obscure: true,
                    validator: Validators.validatePassword,
                  ).animate().fadeIn(delay: 450.ms),
                  const SizedBox(height: 20),
                  KkTextField(
                    label: 'UPI ID',
                    hint: 'example@upi',
                    controller: _upiController,
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 20),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Connect Wallet',
                                style: t.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: p.surface2,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                'OPTIONAL',
                                style: t.caption.copyWith(fontSize: 10),
                              ),
                            ),
                            if (_connectedWallet != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: p.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: p.green,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _connectedWallet!,
                                          style: t.caption.copyWith(
                                            color: p.green,
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (_walletAddress != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: p.surface2,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.key, color: p.accent, size: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    shortenWalletAddress(_walletAddress),
                                    style: t.captionMedium.copyWith(
                                      color: p.accent,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await _walletService.disconnect();
                                    setState(() {
                                      _connectedWallet = null;
                                      _walletAddress = null;
                                    });
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color: p.textSecondary,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _walletIcon(
                              context,
                              Icons.account_balance_wallet_rounded,
                              'MetaMask',
                              () => _connectMetaMask(),
                              isConnected: _connectedWallet == 'MetaMask',
                            ),
                            const SizedBox(width: 20),
                            _walletIcon(
                              context,
                              Icons.link_rounded,
                              'WalletConnect',
                              () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'WalletConnect: Use MetaMask or Phantom',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 20),
                            _walletIcon(
                              context,
                              Icons.blur_on_rounded,
                              'Phantom',
                              () => _connectPhantom(),
                              isConnected: _connectedWallet == 'Phantom',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        KkButton(
                          label: _connectedWallet != null
                              ? '✓ Wallet Connected'
                              : 'Connect Crypto Wallet',
                          icon: Icons.account_balance_wallet_outlined,
                          outlined: _connectedWallet == null,
                          height: 44,
                          isLoading: _isConnectingWallet,
                          onTap: _connectedWallet != null
                              ? null
                              : () => _connectMetaMask(),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 550.ms),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (v) =>
                            setState(() => _agreedToTerms = v ?? false),
                        activeColor: p.accent,
                        side: BorderSide(color: p.border),
                      ),
                      Expanded(
                        child: Text(
                          'I agree to the Terms of Service and Privacy Policy',
                          style: t.caption,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return KkButton(
                        label: 'Create My Account',
                        onTap: _onRegister,
                        isLoading: state is AuthLoading,
                      );
                    },
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: t.body.copyWith(color: p.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'Login',
                          style: t.bodyMedium.copyWith(color: p.accent),
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

  Widget _walletIcon(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isConnected = false,
  }) {
    final p = context.palette;
    final t = context.txt;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isConnected
                  ? p.accent.withValues(alpha: 0.15)
                  : p.surface2,
              shape: BoxShape.circle,
              border: Border.all(
                color: isConnected ? p.accent : p.border,
              ),
            ),
            child: Icon(
              icon,
              color: isConnected ? p.accent : p.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: t.caption.copyWith(
              fontSize: 10,
              color: isConnected ? p.accent : p.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

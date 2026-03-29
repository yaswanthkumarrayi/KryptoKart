import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/service_locator.dart';
import '../../../core/theme/kk_theme_context.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../shared/services/api_service.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = sl<ApiService>();
  final _localAuth = LocalAuthentication();
  bool _bio = false, _payAlerts = true, _priceAlerts = true, _isLoading = true;
  String _theme = 'dark';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.getSettings();
      final s = data['settings'];
      final theme = s['theme'] as String? ??
          (sl<ThemeController>().themeMode == ThemeMode.light ? 'light' : 'dark');
      setState(() {
        _bio = s['biometricEnabled'] ?? false;
        _payAlerts = s['paymentAlerts'] ?? true;
        _priceAlerts = s['priceAlerts'] ?? true;
        _theme = theme;
        _isLoading = false;
      });
      await sl<ThemeController>().setThemeFromApiString(_theme);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _update(String key, dynamic value) async {
    try {
      await _api.updateSettings({key: value});
    } catch (_) {}
  }

  Future<void> _onThemeChanged(bool dark) async {
    final next = dark ? 'dark' : 'light';
    setState(() => _theme = next);
    await _update('theme', _theme);
    await sl<ThemeController>().setThemeFromApiString(_theme);
  }

  Future<void> _onBiometricChanged(bool enable) async {
    if (enable) {
      final can = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!can) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Biometric authentication is not available on this device.',
              ),
            ),
          );
        }
        return;
      }
      try {
        final ok = await _localAuth.authenticate(
          localizedReason: 'Verify your identity to enable biometric login',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
        if (!ok) {
          if (mounted) setState(() => _bio = false);
          return;
        }
      } catch (e) {
        if (mounted) {
          setState(() => _bio = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Biometric error: $e')),
          );
        }
        return;
      }
    }

    setState(() => _bio = enable);
    await _update('biometricEnabled', enable);
    await AuthBloc.setBiometricEnabled(enable);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enable
                ? 'Biometric login enabled'
                : 'Biometric login disabled',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.txt;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: p.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(context, 'Appearance'),
                  GlassCard(
                    child: _sw(
                      context,
                      'Dark mode',
                      _theme == 'dark',
                      _onThemeChanged,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _header(context, 'Security'),
                  GlassCard(
                    child: Column(
                      children: [
                        _sw(
                          context,
                          'Biometric Login',
                          _bio,
                          _onBiometricChanged,
                        ),
                        Divider(color: p.border),
                        _menu(context, 'Change PIN', Icons.lock_outline, () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _header(context, 'Notifications'),
                  GlassCard(
                    child: Column(
                      children: [
                        _sw(
                          context,
                          'Payment Alerts',
                          _payAlerts,
                          (v) async {
                            setState(() => _payAlerts = v);
                            await _update('paymentAlerts', v);
                          },
                        ),
                        Divider(color: p.border),
                        _sw(
                          context,
                          'Price Alerts',
                          _priceAlerts,
                          (v) async {
                            setState(() => _priceAlerts = v);
                            await _update('priceAlerts', v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _header(context, 'About'),
                  GlassCard(
                    child: Column(
                      children: [
                        _menu(
                          context,
                          'App Version',
                          Icons.info_outline,
                          () {},
                          trailing: '1.0.0',
                        ),
                        Divider(color: p.border),
                        _menu(
                          context,
                          'Terms of Service',
                          Icons.description_outlined,
                          () {},
                        ),
                        Divider(color: p.border),
                        _menu(
                          context,
                          'Privacy Policy',
                          Icons.privacy_tip_outlined,
                          () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      context.read<AuthBloc>().add(LogoutRequested());
                      context.go('/login');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: p.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.red.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(
                          'Logout',
                          style: t.bodyMedium.copyWith(color: p.red),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _header(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(
          title,
          style: context.txt.captionMedium.copyWith(color: context.palette.accent),
        ),
      );

  Widget _sw(
    BuildContext context,
    String label,
    bool value,
    Future<void> Function(bool) onChanged,
  ) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: context.txt.bodyMedium)),
          Switch(
            value: value,
            onChanged: (v) => unawaited(onChanged(v)),
            activeTrackColor: context.palette.accent,
          ),
        ],
      );

  Widget _menu(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap, {
    String? trailing,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: context.palette.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: context.txt.bodyMedium)),
              if (trailing != null) Text(trailing, style: context.txt.caption),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: context.palette.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      );
}

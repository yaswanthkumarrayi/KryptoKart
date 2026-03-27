import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/service_locator.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = sl<ApiService>();
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
      setState(() {
        _bio = s['biometricEnabled'] ?? false;
        _payAlerts = s['paymentAlerts'] ?? true;
        _priceAlerts = s['priceAlerts'] ?? true;
        _theme = s['theme'] ?? 'dark';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _update(String key, dynamic value) async {
    try {
      await _api.updateSettings({key: value});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appearance
                  _header('Appearance'),
                  GlassCard(
                    child: _sw('Dark Theme', _theme == 'dark', (v) {
                      setState(() => _theme = v ? 'dark' : 'light');
                      _update('theme', _theme);
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Security
                  _header('Security'),
                  GlassCard(
                    child: Column(
                      children: [
                        _sw('Biometric Login', _bio, (v) {
                          setState(() => _bio = v);
                          _update('biometricEnabled', v);
                        }),
                        const Divider(color: AppColors.border),
                        _menu('Change PIN', Icons.lock_outline, () {}),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notifications
                  _header('Notifications'),
                  GlassCard(
                    child: Column(
                      children: [
                        _sw('Payment Alerts', _payAlerts, (v) {
                          setState(() => _payAlerts = v);
                          _update('paymentAlerts', v);
                        }),
                        const Divider(color: AppColors.border),
                        _sw('Price Alerts', _priceAlerts, (v) {
                          setState(() => _priceAlerts = v);
                          _update('priceAlerts', v);
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // About
                  _header('About'),
                  GlassCard(
                    child: Column(
                      children: [
                        _menu('App Version', Icons.info_outline, () {}, trailing: '1.0.0'),
                        const Divider(color: AppColors.border),
                        _menu('Terms of Service', Icons.description_outlined, () {}),
                        const Divider(color: AppColors.border),
                        _menu('Privacy Policy', Icons.privacy_tip_outlined, () {}),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Logout
                  GestureDetector(
                    onTap: () {
                      context.read<AuthBloc>().add(LogoutRequested());
                      context.go('/login');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text('Logout', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.red)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _header(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(t, style: AppTextStyles.captionMedium.copyWith(color: AppColors.accent)));

  Widget _sw(String l, bool v, ValueChanged<bool> c) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: AppTextStyles.bodyMedium),
        Switch(value: v, onChanged: c, activeTrackColor: AppColors.accent),
      ]);

  Widget _menu(String l, IconData i, VoidCallback t, {String? trailing}) => GestureDetector(
      onTap: t,
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Icon(i, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(l, style: AppTextStyles.bodyMedium)),
            if (trailing != null) Text(trailing, style: AppTextStyles.caption),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
          ])));
}

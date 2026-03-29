import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/kk_theme_context.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kk_button.dart';
import '../../../core/widgets/kk_text_field.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/service_locator.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _apiService = sl<ApiService>();
  int _currentStep = 0;
  bool _isProcessing = false;

  // Step 1 controllers
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _panController = TextEditingController();
  final _aadhaarController = TextEditingController();

  // Step 2 controllers
  final _bankController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _holderController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _panController.dispose();
    _aadhaarController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  Future<void> _submitStep() async {
    setState(() => _isProcessing = true);
    try {
      final step = _currentStep + 1;
      await _apiService.updateKyc({
        'pan': _panController.text,
        'aadhaar': _aadhaarController.text,
        'dob': _dobController.text,
        'bankName': _bankController.text,
        'accountNumber': _accountController.text,
        'ifsc': _ifscController.text,
        'accountHolderName': _holderController.text,
        'step': step,
      });

      if (_currentStep < 2) {
        setState(() => _currentStep++);
      } else {
        if (mounted) context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: context.palette.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Verification'),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text(
              'Skip',
              style: context.txt.bodyMedium
                  .copyWith(color: context.palette.textSecondary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  _stepIndicator(context, 0, 'Personal'),
                  _stepLine(context, 0),
                  _stepIndicator(context, 1, 'Bank'),
                  _stepLine(context, 1),
                  _stepIndicator(context, 2, 'Verify'),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 3,
                  backgroundColor: context.palette.surface2,
                  color: context.palette.accent,
                  minHeight: 4,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Step content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GlassCard(
                  child: _buildStepContent(context),
                ),
              ),
            ),

            // Next button
            Padding(
              padding: const EdgeInsets.all(24),
              child: KkButton(
                label: _currentStep < 2 ? 'Next' : 'Complete Verification',
                onTap: _submitStep,
                isLoading: _isProcessing,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    final p = context.palette;
    final t = context.txt;
    switch (_currentStep) {
      case 0:
        return Column(
          children: [
            KkTextField(label: 'Full Name', hint: 'Enter your name', controller: _nameController),
            const SizedBox(height: 16),
            KkTextField(label: 'Date of Birth', hint: 'DD/MM/YYYY', controller: _dobController),
            const SizedBox(height: 16),
            KkTextField(label: 'PAN Number', hint: 'ABCDE1234F', controller: _panController),
            const SizedBox(height: 16),
            KkTextField(label: 'Aadhaar Number', hint: '1234 5678 9012', controller: _aadhaarController, keyboardType: TextInputType.number),
          ],
        );
      case 1:
        return Column(
          children: [
            KkTextField(label: 'Bank Name', hint: 'Enter bank name', controller: _bankController),
            const SizedBox(height: 16),
            KkTextField(label: 'Account Number', hint: 'Enter account number', controller: _accountController, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            KkTextField(label: 'IFSC Code', hint: 'SBIN0001234', controller: _ifscController),
            const SizedBox(height: 16),
            KkTextField(label: 'Account Holder', hint: 'Enter holder name', controller: _holderController),
          ],
        );
      case 2:
        return Column(
          children: [
            Icon(Icons.verified_user_rounded, size: 64, color: p.accent),
            const SizedBox(height: 16),
            Text('Document Verification', style: t.titleSmall),
            const SizedBox(height: 8),
            Text(
              'In a production app, this step would capture Aadhaar front/back and a selfie for verification.',
              style: t.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: p.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your information has been saved. Tap "Complete Verification" to finalize.',
                      style: t.body.copyWith(color: p.green),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _stepIndicator(BuildContext context, int step, String label) {
    final p = context.palette;
    final t = context.txt;
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? p.accent : p.surface2,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive && _currentStep > step
                ? Icon(Icons.check, size: 16, color: p.textOnAccentButton)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? p.textOnAccentButton
                          : p.textSecondary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: t.caption.copyWith(
            color: isActive ? p.accent : p.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(BuildContext context, int afterStep) {
    final p = context.palette;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: _currentStep > afterStep ? p.accent : p.surface2,
      ),
    );
  }
}

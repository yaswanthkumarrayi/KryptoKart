import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/user_model.dart';

/// Premium credit card style profile widget using flutter_credit_card
class ProfileCard extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onEdit;
  final Function(String name, String cardNumber)? onSave;

  const ProfileCard({super.key, required this.user, this.onEdit, this.onSave});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  bool _isEditing = false;
  late String _cardNumber;
  late String _cardHolderName;
  late String _expiryDate;
  final String _cvvCode = '';
  bool _isCvvFocused = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeCardData();
  }

  void _initializeCardData() {
    _cardHolderName = widget.user.name.toUpperCase();
    // Generate a masked card number from user ID or phone
    _cardNumber = _generateCardNumber();
    _expiryDate = _generateExpiryDate();
  }

  String _generateCardNumber() {
    // Use phone or ID to generate a consistent card-like number
    final source = widget.user.phone.isNotEmpty
        ? widget.user.phone.replaceAll(RegExp(r'\D'), '')
        : widget.user.id;

    // Pad and format to look like a card number
    final digits = source.padLeft(16, '0').substring(0, 16);
    return '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8, 12)} ${digits.substring(12, 16)}';
  }

  String _generateExpiryDate() {
    // Generate expiry date based on current date + 3 years
    final now = DateTime.now();
    final expiryMonth = now.month.toString().padLeft(2, '0');
    final expiryYear = ((now.year + 3) % 100).toString().padLeft(2, '0');
    return '$expiryMonth/$expiryYear';
  }

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
  }

  void _saveChanges() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave?.call(_cardHolderName, _cardNumber);
      setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Credit card display with edit icon overlay
        Stack(
              children: [
                CreditCardWidget(
                  cardNumber: _cardNumber,
                  expiryDate: _expiryDate,
                  cardHolderName: _cardHolderName,
                  cvvCode: _cvvCode,
                  showBackView: _isCvvFocused,
                  cardBgColor: AppColors.surface2,
                  glassmorphismConfig: Glassmorphism(
                    blurX: 10.0,
                    blurY: 10.0,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accent.withValues(alpha: 0.3),
                        AppColors.primary.withOpacity(0.3),
                      ],
                      stops: const [0.1, 1],
                    ),
                  ),
                  obscureCardNumber: false,
                  obscureCardCvv: true,
                  isHolderNameVisible: true,
                  height: 200,
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  frontCardBorder: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  backCardBorder: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  onCreditCardWidgetChange: (_) {},
                  customCardTypeIcons: [
                    CustomCardTypeIcon(
                      cardType: CardType.otherBrand,
                      cardImage: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: AppColors.accent,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),

                // Edit button overlay
                Positioned(
                  top: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onEdit ?? _toggleEdit,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Icon(
                          _isEditing ? Icons.close : Icons.edit,
                          color: AppColors.accent,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
              duration: 400.ms,
            ),

        // Edit form (expandable)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isEditing ? _buildEditForm() : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Profile Card', style: AppTextStyles.titleSmall),
            const SizedBox(height: 16),

            CreditCardForm(
              formKey: _formKey,
              cardNumber: _cardNumber,
              expiryDate: _expiryDate,
              cardHolderName: _cardHolderName,
              cvvCode: _cvvCode,
              onCreditCardModelChange: (CreditCardModel data) {
                setState(() {
                  _cardNumber = data.cardNumber;
                  _expiryDate = data.expiryDate;
                  _cardHolderName = data.cardHolderName;
                  _isCvvFocused = data.isCvvFocused;
                });
              },
              obscureCvv: true,
              obscureNumber: false,
              isHolderNameVisible: true,
              isCardNumberVisible: true,
              isExpiryDateVisible: true,
              enableCvv: false,
              cardNumberValidator: (String? cardNumber) {
                return null; // No strict validation for display card
              },
              expiryDateValidator: (String? expiryDate) {
                return null;
              },
              cvvValidator: (String? cvv) {
                return null;
              },
              cardHolderValidator: (String? cardHolderName) {
                if (cardHolderName == null || cardHolderName.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
              inputConfiguration: InputConfiguration(
                cardNumberDecoration: InputDecoration(
                  labelText: 'Card Number',
                  labelStyle: AppTextStyles.caption,
                  hintText: 'XXXX XXXX XXXX XXXX',
                  hintStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
                expiryDateDecoration: InputDecoration(
                  labelText: 'Expiry Date',
                  labelStyle: AppTextStyles.caption,
                  hintText: 'MM/YY',
                  hintStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
                cvvCodeDecoration: InputDecoration(
                  labelText: 'CVV',
                  labelStyle: AppTextStyles.caption,
                  hintText: 'XXX',
                  hintStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
                cardHolderDecoration: InputDecoration(
                  labelText: 'Card Holder Name',
                  labelStyle: AppTextStyles.caption,
                  hintText: 'Your Name',
                  hintStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
                cardNumberTextStyle: AppTextStyles.body.copyWith(
                  color: Colors.white,
                ),
                cardHolderTextStyle: AppTextStyles.body.copyWith(
                  color: Colors.white,
                ),
                expiryDateTextStyle: AppTextStyles.body.copyWith(
                  color: Colors.white,
                ),
                cvvCodeTextStyle: AppTextStyles.body.copyWith(
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

/// Compact profile card for dashboard display
class ProfileCardMini extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const ProfileCardMini({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardNumber = _generateCardNumber();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withValues(alpha: 0.2),
              AppColors.primary.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.accent,
                  size: 24,
                ),
                Text(
                  'KryptoKart',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              cardNumber,
              style: AppTextStyles.bodyMedium.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    user.name.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(_generateExpiryDate(), style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _generateCardNumber() {
    final source = user.phone.isNotEmpty
        ? user.phone.replaceAll(RegExp(r'\D'), '')
        : user.id;
    final digits = source.padLeft(16, '0').substring(0, 16);
    return '**** **** **** ${digits.substring(12, 16)}';
  }

  String _generateExpiryDate() {
    final now = DateTime.now();
    final expiryMonth = now.month.toString().padLeft(2, '0');
    final expiryYear = ((now.year + 3) % 100).toString().padLeft(2, '0');
    return '$expiryMonth/$expiryYear';
  }
}

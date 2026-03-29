import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/kk_theme_context.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/kk_button.dart';
import '../../core/widgets/kk_text_field.dart';
import '../models/user_model.dart';

/// Premium profile card showing user details (Name, Mobile, UPI ID, DOB)
class ProfileCard extends StatefulWidget {
  final UserModel user;
  final Function(UserModel updatedUser)? onSave;

  const ProfileCard({super.key, required this.user, this.onSave});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _upiController;
  late TextEditingController _dobController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _upiController = TextEditingController(text: widget.user.upiId);
    _dobController = TextEditingController(text: widget.user.dob);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _upiController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_isEditing) {
      // Revert if cancelling
      _nameController.text = widget.user.name;
      _phoneController.text = widget.user.phone;
      _upiController.text = widget.user.upiId;
      _dobController.text = widget.user.dob;
    }
    setState(() => _isEditing = !_isEditing);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.palette.accent,
              onPrimary: context.palette.background,
              surface: context.palette.surface,
              onSurface: context.palette.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _saveChanges() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedUser = widget.user.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        upiId: _upiController.text.trim(),
        dob: _dobController.text.trim(),
      );
      widget.onSave?.call(updatedUser);
      setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.txt;

    return Column(
      children: [
        // Premium Profile Card display
        Stack(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    p.surface2,
                    p.surface.withValues(alpha: 0.8),
                  ],
                ),
                border: Border.all(
                  color: p.accent.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: p.accentGlow.withValues(alpha: 0.05),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Abstract design elements
                    Positioned(
                      top: -40,
                      right: -40,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: p.accent.withValues(alpha: 0.05),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: p.accentBlue.withValues(alpha: 0.05),
                      ),
                    ),
                    
                    // User Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: p.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.account_circle_rounded,
                                  color: p.accent,
                                  size: 28,
                                ),
                              ),
                              Text(
                                'KryptoKart ID',
                                style: t.label.copyWith(
                                  color: p.accent,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            widget.user.name.toUpperCase(),
                            style: t.title.copyWith(
                              letterSpacing: 1.2,
                              color: p.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _infoSlot(Icons.phone_android, widget.user.phone, context),
                              const SizedBox(width: 24),
                              _infoSlot(Icons.cake_rounded, widget.user.dob.isEmpty ? '—' : widget.user.dob, context),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _infoSlot(Icons.alternate_email_rounded, widget.user.upiId, context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

            // Edit button overlay
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggleEdit,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: p.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: p.accent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      _isEditing ? Icons.close : Icons.edit_rounded,
                      color: p.accent,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Edit form (expandable)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isEditing 
            ? _buildEditForm(key: const ValueKey('profile_edit_form')) 
            : const SizedBox.shrink(key: ValueKey('empty_form')),
        ),
      ],
    );
  }

  Widget _infoSlot(IconData icon, String text, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.palette.accent.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: context.txt.caption.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm({required Key key}) {
    final p = context.palette;
    final t = context.txt;

    return Container(
      key: key,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update Profile Info', style: t.titleSmall),
            const SizedBox(height: 20),
            
            KkTextField(
              label: 'Full Name',
              hint: 'Enter your name',
              controller: _nameController,
              validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
              prefix: Icon(Icons.person_outline_rounded, color: p.accent, size: 20),
            ),
            const SizedBox(height: 16),
            
            KkTextField(
              label: 'Mobile Number',
              hint: '10-digit mobile number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Mobile number is required';
                if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'Invalid mobile number';
                return null;
              },
              prefix: Icon(Icons.phone_iphone_rounded, color: p.accent, size: 20),
            ),
            const SizedBox(height: 16),
            
            KkTextField(
              label: 'UPI ID',
              hint: 'example@upi',
              controller: _upiController,
              validator: (v) {
                if (v == null || v.isEmpty) return 'UPI ID is required';
                if (!v.contains('@')) return 'Invalid UPI ID format';
                return null;
              },
              prefix: Icon(Icons.alternate_email_rounded, color: p.accent, size: 20),
            ),
            const SizedBox(height: 16),
            
            GestureDetector(
              onTap: _selectDate,
              child: AbsorbPointer(
                child: KkTextField(
                  label: 'Date of Birth',
                  hint: 'DD/MM/YYYY',
                  controller: _dobController,
                  validator: (v) => v == null || v.isEmpty ? 'DOB is required' : null,
                  prefix: Icon(Icons.calendar_today_rounded, color: p.accent, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            KkButton(
              label: 'Save Profile Changes',
              onTap: _saveChanges,
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

/// Compact profile card for dashboard display
class ProfileCardMini extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const ProfileCardMini({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.txt;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.account_circle_rounded,
                color: p.accent,
                size: 24,
              ),
              Text(
                'KK PROFILE',
                style: t.label.copyWith(
                  color: p.accent,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user.name.toUpperCase(),
            style: t.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            user.upiId.isNotEmpty ? user.upiId : user.phone,
            style: t.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

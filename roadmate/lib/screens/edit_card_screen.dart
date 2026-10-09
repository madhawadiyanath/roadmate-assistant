import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/payment_method.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/payment_widgets.dart';

export '../widgets/payment_widgets.dart'
    show CardExpiryInputFormatter, validateCardExpiry;

/// Edit / Manage Saved Card screen matching the Stitch design.
class EditCardScreen extends StatefulWidget {
  final PaymentMethod card;
  final PaymentService? paymentService;
  final String? userUid;

  const EditCardScreen({
    super.key,
    required this.card,
    this.paymentService,
    this.userUid,
  });

  @override
  State<EditCardScreen> createState() => _EditCardScreenState();
}

class _EditCardScreenState extends State<EditCardScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _expiryCtrl;
  late bool _isDefault;
  bool _saving = false;
  String? _expiryError;

  PaymentService get _service => widget.paymentService ?? PaymentService();
  String get _uid =>
      widget.userUid ?? (AuthService().currentUser?.uid ?? 'driver_demo');

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.card.holderName);
    final initialExpiry = (widget.card.expiryMonth.isNotEmpty &&
            widget.card.expiryYear.isNotEmpty)
        ? '${widget.card.expiryMonth.padLeft(2, '0')}/${widget.card.expiryYear}'
        : '12/28';
    _expiryCtrl = TextEditingController(text: initialExpiry);
    _isDefault = widget.card.isDefault;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  /// Validates the expiration date string.
  /// Returns null if valid, or a descriptive error message.
  String? _validateExpiration(String val) {
    return validateCardExpiry(val);
  }

  Future<void> _saveChanges() async {
    final error = _validateExpiration(_expiryCtrl.text);
    setState(() {
      _expiryError = error;
    });

    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter cardholder name')),
      );
      return;
    }

    if (error != null) {
      return;
    }

    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final parts = _expiryCtrl.text.split('/');
    final month = parts.isNotEmpty ? parts[0] : widget.card.expiryMonth;
    final year = parts.length > 1 ? parts[1] : widget.card.expiryYear;

    final updatedCard = widget.card.copyWith(
      holderName: _nameCtrl.text.trim(),
      expiryMonth: month,
      expiryYear: year,
      isDefault: _isDefault,
    );

    final index = mockPaymentMethods.indexWhere((m) => m.id == widget.card.id);
    if (index != -1) {
      if (_isDefault) {
        for (var i = 0; i < mockPaymentMethods.length; i++) {
          mockPaymentMethods[i] =
              mockPaymentMethods[i].copyWith(isDefault: false);
        }
      }
      mockPaymentMethods[index] = updatedCard;
    }

    await _service.updatePaymentMethod(uid: _uid, method: updatedCard);

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card details updated successfully'),
        backgroundColor: AppColors.successText,
      ),
    );
    Navigator.pop(context, CardActionResult.updated(updatedCard));
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Remove Card',
              style: AppTypography.headlineSm(color: AppColors.primary),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${widget.card.brand} ending in ${widget.card.last4}? This action cannot be undone.',
          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTypography.labelLg(color: AppColors.slateText),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      mockPaymentMethods.removeWhere((m) => m.id == widget.card.id);
      await _service.deletePaymentMethod(uid: _uid, methodId: widget.card.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card removed successfully'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context, CardActionResult.removed(widget.card.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVisa = widget.card.brand.toLowerCase().contains('visa');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            RoadMateAppHeader(
              title: 'Manage Card',
              showBack: true,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Visual Mock
                    Container(
                      height: 200,
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isVisa
                              ? [const Color(0xFF002546), const Color(0xFF0D3B66)]
                              : [const Color(0xFF1E293B), const Color(0xFF334155)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(50),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.card.brand.toUpperCase(),
                                style: AppTypography.titleMd(color: Colors.white),
                              ),
                              if (widget.card.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Text(
                                    'DEFAULT',
                                    style: AppTypography.labelSm(
                                        color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                '•••• •••• •••• ${widget.card.last4}',
                                style: AppTypography.headlineSm(
                                    color: Colors.white),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CARD HOLDER',
                                    style: AppTypography.labelSm(
                                        color: Colors.white70),
                                  ),
                                  Text(
                                    _nameCtrl.text.isEmpty
                                        ? 'NAME'
                                        : _nameCtrl.text.toUpperCase(),
                                    style: AppTypography.titleMd(
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'EXPIRES',
                                    style: AppTypography.labelSm(
                                        color: Colors.white70),
                                  ),
                                  Text(
                                    _expiryCtrl.text.isEmpty
                                        ? 'MM/YY'
                                        : _expiryCtrl.text,
                                    style: AppTypography.titleMd(
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Card Number (Read only)
                    Text('Card Number',
                        style: AppTypography.labelLg(color: AppColors.onSurface)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.outlineVariant.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.credit_card_rounded,
                              color: AppColors.onSurfaceVariant, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            '•••• •••• •••• ${widget.card.last4}',
                            style: AppTypography.titleMd(
                                color: AppColors.onSurfaceVariant),
                          ),
                          const Spacer(),
                          const Icon(Icons.lock_outline_rounded,
                              color: AppColors.mutedText, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cardholder Name (Editable)
                    RoadMateTextField(
                      label: 'Cardholder Name',
                      hint: 'e.g. John Doe',
                      controller: _nameCtrl,
                      prefixIcon: Icons.person_outline_rounded,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Expiration Date (Editable)
                    RoadMateTextField(
                      label: 'Expiration Date',
                      hint: 'MM/YY',
                      controller: _expiryCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      prefixIcon: Icons.calendar_today_outlined,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                        CardExpiryInputFormatter(),
                      ],
                      errorText: _expiryError,
                      onChanged: (val) {
                        if (_expiryError != null) {
                          setState(() {
                            _expiryError = null;
                          });
                        } else {
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Set as Default switch
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Set as Default Payment Method',
                                  style: AppTypography.titleMd(
                                      color: AppColors.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Use this card automatically for future requests',
                                  style: AppTypography.bodySm(
                                      color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isDefault,
                            activeTrackColor: AppColors.secondaryContainer,
                            onChanged: (val) => setState(() => _isDefault = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Save Changes Button
                    RoadMatePrimaryButton(
                      label: 'Save Changes',
                      icon: Icons.check_circle_outline_rounded,
                      loading: _saving,
                      onPressed: _saveChanges,
                    ),
                    const SizedBox(height: 12),

                    // Remove Card Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton.icon(
                        onPressed: _confirmDelete,
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.error, size: 20),
                        label: Text(
                          'Remove This Card',
                          style: AppTypography.labelLg(color: AppColors.error),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

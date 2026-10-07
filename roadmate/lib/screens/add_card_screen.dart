import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/payment_method.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/payment_widgets.dart';

/// Add Credit / Debit Card screen with live card preview (Stitch design).
class AddCardScreen extends StatefulWidget {
  final PaymentService? paymentService;
  final String? userUid;

  const AddCardScreen({
    super.key,
    this.paymentService,
    this.userUid,
  });

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _saveCard = true;
  bool _setDefault = true;
  bool _saving = false;
  String? _expiryError;

  PaymentService get _service => widget.paymentService ?? PaymentService();
  String get _uid =>
      widget.userUid ?? (AuthService().currentUser?.uid ?? 'driver_demo');

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  void _formatCardNumber(String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    final formatted = digits.length <= 16
        ? digits.replaceAllMapped(
            RegExp(r'.{1,4}'), (m) => '${m.group(0)} ').trim()
        : digits.substring(0, 16).replaceAllMapped(
            RegExp(r'.{1,4}'), (m) => '${m.group(0)} ').trim();
    if (formatted != _numberCtrl.text) {
      _numberCtrl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }


  Future<void> _submit() async {
    final digits = _numberCtrl.text.replaceAll(RegExp(r'\D'), '');
    final expiryError = validateCardExpiry(_expiryCtrl.text);
    setState(() {
      _expiryError = expiryError;
    });

    if (expiryError != null) {
      return;
    }

    if (digits.length < 16 || _nameCtrl.text.trim().isEmpty || _cvvCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all card details')),
      );
      return;
    }

    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _saving = false);

    final brand = digits.startsWith('4') ? 'Visa' : 'Mastercard';
    final card = PaymentMethod(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}',
      type: PaymentMethodType.card,
      label: '$brand •••• ${digits.substring(12)}',
      last4: digits.substring(12),
      brand: brand,
      expiryMonth: _expiryCtrl.text.split('/').first,
      expiryYear: _expiryCtrl.text.split('/').last,
      holderName: _nameCtrl.text.trim(),
      isDefault: _setDefault,
    );

    if (_setDefault) {
      for (var i = 0; i < mockPaymentMethods.length; i++) {
        mockPaymentMethods[i] =
            mockPaymentMethods[i].copyWith(isDefault: false);
      }
    }
    if (_saveCard) {
      if (!mockPaymentMethods.any((m) => m.id == card.id)) {
        mockPaymentMethods.add(card);
      }
      await _service.addPaymentMethod(uid: _uid, method: card);
    }

    if (!mounted) return;
    // Show success modal
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.tertiaryFixed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.tertiaryContainer, size: 36),
              ),
              const SizedBox(height: 16),
              Text('Card Verified!',
                  style: AppTypography.headlineSm(color: AppColors.primary)),
              const SizedBox(height: 8),
              Text(
                'Your card has been added as your ${_setDefault ? "default" : ""} payment method for all RoadMate services.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              RoadMatePrimaryButton(
                label: 'Done',
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );

    if (mounted) Navigator.pop(context, card);
  }

  @override
  Widget build(BuildContext context) {
    final displayNumber = _numberCtrl.text.isEmpty
        ? '•••• •••• •••• ••••'
        : _numberCtrl.text;
    final displayName =
        _nameCtrl.text.trim().isEmpty ? 'FULL NAME' : _nameCtrl.text.toUpperCase();
    final displayExpiry =
        _expiryCtrl.text.isEmpty ? 'MM/YY' : _expiryCtrl.text;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const RoadMateAppHeader(title: 'Add New Card'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Card preview ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryContainer,
                            Color(0xFF3A608D),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(50),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Chip + contactless
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // EMV chip
                              Container(
                                width: 44,
                                height: 30,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE5C07B),
                                      Color(0xFFFFEEBB),
                                      Color(0xFFD4AF37),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              Row(
                                children: [
                                  Transform.rotate(
                                    angle: 1.5708,
                                    child: Icon(Icons.contactless_rounded,
                                        color: Colors.white.withAlpha(180),
                                        size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  // Mastercard circles
                                  Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryContainer
                                              .withAlpha(240),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Transform.translate(
                                        offset: const Offset(-10, 0),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: AppColors.secondaryFixed
                                                .withAlpha(220),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Card number
                          Text(
                            displayNumber,
                            style: AppTypography.headlineSm(
                                    color: AppColors.onPrimary)
                                .copyWith(
                                    letterSpacing: 3,
                                    fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 20),

                          // Name + expiry
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Card Holder',
                                        style: AppTypography.labelSm(
                                            color: AppColors.onPrimaryContainer)),
                                    Text(
                                      displayName,
                                      style: AppTypography.titleMd(
                                          color: AppColors.onPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Expires',
                                      style: AppTypography.labelSm(
                                          color: AppColors.onPrimaryContainer)),
                                  Text(
                                    displayExpiry,
                                    style: AppTypography.titleMd(
                                        color: AppColors.onPrimary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Security pill
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded,
                              color: AppColors.tertiaryContainer, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('256-Bit Bank-grade Encryption',
                                style: AppTypography.labelMd(
                                    color: AppColors.onSurface)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text('PCI-DSS',
                                style: AppTypography.labelSm(
                                    color: AppColors.onSurfaceVariant)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Form ──
                    RoadMateTextField(
                      label: 'Card Number',
                      hint: '5412 7500 2424 4242',
                      prefixIcon: Icons.credit_card_rounded,
                      controller: _numberCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 19,
                      onChanged: _formatCardNumber,
                      helperText:
                          'Enter your 16-digit personal or corporate card number',
                    ),
                    const SizedBox(height: 16),

                    RoadMateTextField(
                      label: 'Cardholder Name',
                      hint: 'e.g. Johnathan Perera',
                      prefixIcon: Icons.person_rounded,
                      controller: _nameCtrl,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: RoadMateTextField(
                            label: 'Expires End',
                            hint: 'MM/YY',
                            prefixIcon: Icons.calendar_today_rounded,
                            controller: _expiryCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 5,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                              CardExpiryInputFormatter(),
                            ],
                            errorText: _expiryError,
                            onChanged: (val) {
                              if (_expiryError != null) {
                                setState(() => _expiryError = null);
                              } else {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: RoadMateTextField(
                            label: 'CVV / CVC',
                            hint: '•••',
                            prefixIcon: Icons.lock_rounded,
                            controller: _cvvCtrl,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            maxLength: 4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Toggles ──
                    RoadMateCard(
                      child: Column(
                        children: [
                          _Toggle(
                            icon: Icons.bolt_rounded,
                            title: '1-Click Dispatch & Tows',
                            subtitle:
                                'Securely remember this card for fast roadside response',
                            value: _saveCard,
                            onChanged: (v) =>
                                setState(() => _saveCard = v),
                          ),
                          const Divider(
                              color: AppColors.surfaceContainer, height: 20),
                          _Toggle(
                            icon: Icons.check_circle_rounded,
                            title: 'Set as Primary Method',
                            subtitle:
                                'Prioritize over wallet balance during checkouts',
                            value: _setDefault,
                            onChanged: (v) =>
                                setState(() => _setDefault = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Security notice
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_rounded,
                            color: AppColors.tertiaryContainer, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Your card information is tokenized and never stored on local servers.',
                            style: AppTypography.bodySm(
                                color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Action buttons ──
                    RoadMatePrimaryButton(
                      label: 'Save Card Securely',
                      icon: Icons.add_card_rounded,
                      onPressed: _submit,
                      loading: _saving,
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel',
                            style: AppTypography.labelLg(
                                color: AppColors.onSurfaceVariant)),
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

class _Toggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTypography.titleMd(color: AppColors.onSurface)),
              Text(subtitle,
                  style: AppTypography.bodySm(
                      color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primaryContainer,
        ),
      ],
    );
  }
}

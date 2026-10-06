import 'package:flutter/material.dart';
import '../models/payment_method.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/payment_widgets.dart';
import 'add_card_screen.dart';
import 'edit_card_screen.dart';

/// Payment Methods: view saved cards, add new, set default, remove.
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  late List<PaymentMethod> _methods;

  @override
  void initState() {
    super.initState();
    _methods = List.of(mockPaymentMethods);
  }

  void _setDefault(String id) {
    setState(() {
      _methods = _methods.map((m) => m.copyWith(isDefault: m.id == id)).toList();
      for (int i = 0; i < mockPaymentMethods.length; i++) {
        mockPaymentMethods[i] = mockPaymentMethods[i].copyWith(
          isDefault: mockPaymentMethods[i].id == id,
        );
      }
    });

    final selected = _methods.firstWhere((m) => m.id == id, orElse: () => _methods.first);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${selected.label} set as default payment method',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMethodDetails(PaymentMethod method) {
    _setDefault(method.id);
    final isWallet = method.type == PaymentMethodType.wallet;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isWallet
                        ? AppColors.primaryContainer
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isWallet
                        ? Icons.account_balance_wallet_rounded
                        : Icons.payments_rounded,
                    color: isWallet ? Colors.white : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.label,
                        style: AppTypography.headlineSm(color: AppColors.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isWallet
                            ? 'RoadMate Wallet Active'
                            : 'Direct Cash Settlement',
                        style: AppTypography.bodySm(color: AppColors.successText),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    'Default',
                    style: AppTypography.labelSm(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 14),
            if (isWallet) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVAILABLE BALANCE',
                      style: AppTypography.labelSm(
                          color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. 2,450.00',
                      style: AppTypography.headlineLg(color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Usable instantly for all roadside dispatch services and towing.',
                      style: AppTypography.bodySm(color: AppColors.slateText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              RoadMatePrimaryButton(
                label: 'Top Up Wallet Balance',
                icon: Icons.add_circle_outline_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Top-up gateway opening...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CASH PAYMENT POLICY',
                      style: AppTypography.labelSm(
                          color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pay physical cash directly to the dispatched patrol specialist once emergency assistance is verified and complete.',
                      style: AppTypography.bodySm(color: AppColors.slateText),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            color: AppColors.secondaryContainer, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'No pre-authorisation hold on cards',
                            style:
                                AppTypography.bodySm(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              RoadMatePrimaryButton(
                label: 'Confirmed as Payment Method',
                icon: Icons.check_circle_rounded,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _removeCard(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.errorContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.credit_card_off_rounded,
              color: AppColors.error, size: 26),
        ),
        title: Text('Remove this card?',
            style: AppTypography.headlineSm(color: AppColors.onSurface)),
        content: Text(
          'This card will be permanently deleted from RoadMate.',
          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTypography.labelLg(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _methods.removeWhere((m) => m.id == id));
            },
            child: Text('Yes, Remove',
                style: AppTypography.labelLg(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _addCard() async {
    final result = await Navigator.push<PaymentMethod>(
      context,
      MaterialPageRoute(builder: (_) => const AddCardScreen()),
    );
    if (result != null && mounted) {
      setState(() => _methods.add(result));
    }
  }

  Future<void> _editCard(PaymentMethod card) async {
    final result = await Navigator.push<PaymentMethod>(
      context,
      MaterialPageRoute(builder: (_) => EditCardScreen(card: card)),
    );
    if (result != null && mounted) {
      setState(() {
        final idx = _methods.indexWhere((m) => m.id == card.id);
        if (idx != -1) _methods[idx] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = _methods.where((m) => m.type == PaymentMethodType.card).toList();
    final wallet = _methods.firstWhere(
      (m) => m.type == PaymentMethodType.wallet,
      orElse: () => const PaymentMethod(id: '', type: PaymentMethodType.wallet),
    );
    final cash = _methods.firstWhere(
      (m) => m.type == PaymentMethodType.cash,
      orElse: () => const PaymentMethod(id: '', type: PaymentMethodType.cash),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const RoadMateAppHeader(title: 'Payment Methods'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Saved Cards ──
                    const SectionHeader(title: 'Saved Cards'),
                    ...cards.map((card) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SavedCardItem(
                            card: card,
                            onSetDefault: () => _setDefault(card.id),
                            onEdit: () => _editCard(card),
                            onRemove: () => _removeCard(card.id),
                          ),
                        )),

                    // Add card button
                    GestureDetector(
                      onTap: _addCard,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.outlineVariant, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_card_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text('Add New Card',
                                style: AppTypography.labelLg(
                                    color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Other Methods ──
                    const SectionHeader(title: 'Other Payment Methods'),

                    // Wallet
                    if (wallet.id.isNotEmpty)
                      _OtherMethodCard(
                        icon: Icons.account_balance_wallet_rounded,
                        iconBg: AppColors.primaryContainer,
                        title: wallet.label,
                        subtitle: wallet.subtitle,
                        isDefault: wallet.isDefault,
                        onTap: () => _showMethodDetails(wallet),
                      ),
                    const SizedBox(height: 10),

                    // Cash
                    if (cash.id.isNotEmpty)
                      _OtherMethodCard(
                        icon: Icons.payments_rounded,
                        iconBg: AppColors.surfaceContainer,
                        iconColor: AppColors.primary,
                        title: cash.label,
                        subtitle: cash.subtitle,
                        isDefault: cash.isDefault,
                        onTap: () => _showMethodDetails(cash),
                      ),
                    const SizedBox(height: 24),
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

class _SavedCardItem extends StatelessWidget {
  final PaymentMethod card;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _SavedCardItem({
    required this.card,
    required this.onSetDefault,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: card.isDefault ? AppColors.primary : AppColors.cardBorder,
            width: card.isDefault ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Card brand visual
            Container(
              width: 48,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: card.brand == 'Mastercard'
                  ? _MastercardLogo()
                  : _VisaLogo(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '•••• ${card.last4}',
                          style: AppTypography.titleMd(
                              color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (card.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text('Default',
                              style: AppTypography.labelSm(
                                  color: AppColors.primary)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${card.brand} • Exp ${card.expiry}',
                    style: AppTypography.bodySm(
                        color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.outline, size: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (v) {
                if (v == 'default') onSetDefault();
                if (v == 'edit') onEdit();
                if (v == 'remove') onRemove();
              },
              itemBuilder: (_) => [
                if (!card.isDefault)
                  const PopupMenuItem(
                      value: 'default', child: Text('Set as Default')),
                const PopupMenuItem(value: 'edit', child: Text('Edit Card')),
                const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove', style: TextStyle(color: AppColors.error))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OtherMethodCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final bool isDefault;
  final VoidCallback? onTap;

  const _OtherMethodCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.isDefault = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: isDefault
              ? AppColors.surfaceContainerLow
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDefault ? AppColors.primary : AppColors.cardBorder,
            width: isDefault ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(isDefault ? 14 : 6),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withAlpha(25),
          highlightColor: AppColors.primary.withAlpha(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: AppTypography.titleMd(
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                'Default',
                                style: AppTypography.labelSm(
                                    color: AppColors.primary),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isDefault
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: isDefault
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MastercardLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFEB001B).withAlpha(220),
            shape: BoxShape.circle,
          ),
        ),
        Transform.translate(
          offset: const Offset(-5, 0),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFF79E1B).withAlpha(220),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _VisaLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'VISA',
        style: AppTypography.labelSm(color: const Color(0xFF1A1F71)),
      ),
    );
  }
}

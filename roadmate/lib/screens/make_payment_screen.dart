import 'package:flutter/material.dart';
import '../models/earnings_record.dart';
import '../models/payment_method.dart';
import '../models/payment_transaction.dart';
import '../services/auth_service.dart';
import '../services/earnings_service.dart';
import '../services/payment_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/payment_widgets.dart';
import 'payment_confirmation_screen.dart';
import 'payment_methods_screen.dart';

/// Make Payment screen matching the Stitch design.
class MakePaymentScreen extends StatefulWidget {
  final String? jobId;
  final String? serviceType;
  final String? providerName;
  final double? serviceCharge;
  final double? additionalCharges;

  const MakePaymentScreen({
    super.key,
    this.jobId,
    this.serviceType,
    this.providerName,
    this.serviceCharge,
    this.additionalCharges,
  });

  @override
  State<MakePaymentScreen> createState() => _MakePaymentScreenState();
}

class _MakePaymentScreenState extends State<MakePaymentScreen> {
  late String _selectedMethodId;
  bool _processing = false;

  late final String _jobId;
  late final String _serviceType;
  late final String _providerName;
  late final double _baseCharge;
  late final double _additionalCharge;
  late final double _totalAmount;

  PaymentMethod get _selectedMethod => mockPaymentMethods.firstWhere(
        (m) => m.id == _selectedMethodId,
        orElse: () => mockPaymentMethods.first,
      );

  bool get _isWalletSelected =>
      _selectedMethod.type == PaymentMethodType.wallet;

  double get _walletBalance => _selectedMethod.walletBalance;

  bool get _isInsufficientBalance =>
      _isWalletSelected && (_walletBalance < _totalAmount);

  double get _remainingRequired =>
      _isInsufficientBalance ? (_totalAmount - _walletBalance) : 0.0;

  @override
  void initState() {
    super.initState();
    _jobId = widget.jobId ?? 'REQ-2026-8921';
    _serviceType = widget.serviceType ?? 'Emergency Towing';
    _providerName = widget.providerName ?? 'Kasun Perera (Mobile Tech)';
    _baseCharge = widget.serviceCharge ?? 6500.00;
    _additionalCharge = widget.additionalCharges ?? 750.00;
    _totalAmount = _baseCharge + _additionalCharge;

    final defaultMethod = mockPaymentMethods.firstWhere(
      (m) => m.isDefault,
      orElse: () => mockPaymentMethods.first,
    );
    _selectedMethodId = defaultMethod.id;
  }

  void _onSelectMethod(String id) {
    setState(() => _selectedMethodId = id);
  }

  void _showTopUpDialog() {
    final topUpAmount = _remainingRequired > 0 ? _remainingRequired : 5000.0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Top Up Wallet',
                style: AppTypography.headlineSm(color: AppColors.primary),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add funds to your RoadMate In-App Wallet to proceed with payment.',
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Current Balance',
                            style: AppTypography.labelSm(
                                color: AppColors.onSurfaceVariant),
                          ),
                        ),
                        Text(
                          formatCurrency(_walletBalance),
                          style: AppTypography.labelMd(color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Top-Up Amount',
                            style: AppTypography.labelSm(
                                color: AppColors.onSurfaceVariant),
                          ),
                        ),
                        Text(
                          formatCurrency(topUpAmount),
                          style: AppTypography.titleMd(
                              color: AppColors.secondaryContainer),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'New Balance',
                            style: AppTypography.labelSm(
                                color: AppColors.onSurfaceVariant),
                          ),
                        ),
                        Text(
                          formatCurrency(_walletBalance + topUpAmount),
                          style: AppTypography.titleMd(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTypography.labelLg(color: AppColors.slateText)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final newBal = _walletBalance + topUpAmount;
              final updatedWallet = _selectedMethod.copyWith(
                balance: newBal,
                subtitle: 'Available Balance: ${formatCurrency(newBal)}',
              );
              final idx =
                  mockPaymentMethods.indexWhere((m) => m.id == _selectedMethod.id);
              if (idx != -1) {
                mockPaymentMethods[idx] = updatedWallet;
              }
              await PaymentService().updatePaymentMethod(
                uid: AuthService().currentUser?.uid ?? 'driver_demo',
                method: updatedWallet,
              );
              if (!mounted) return;
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Wallet topped up successfully with ${formatCurrency(topUpAmount)}'),
                  backgroundColor: AppColors.successText,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999)),
            ),
            child: const Text('Top Up Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    if (_isInsufficientBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient wallet balance. Please add ${formatCurrency(_remainingRequired)} or select another payment method.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 1400));

    final selectedMethod = _selectedMethod;

    // Deduct wallet balance if wallet payment
    if (selectedMethod.type == PaymentMethodType.wallet) {
      final remainingBal = _walletBalance - _totalAmount;
      final updatedWallet = selectedMethod.copyWith(
        balance: remainingBal,
        subtitle: 'Available Balance: ${formatCurrency(remainingBal)}',
      );
      final idx =
          mockPaymentMethods.indexWhere((m) => m.id == selectedMethod.id);
      if (idx != -1) {
        mockPaymentMethods[idx] = updatedWallet;
      }
      await PaymentService().updatePaymentMethod(
        uid: AuthService().currentUser?.uid ?? 'driver_demo',
        method: updatedWallet,
      );
    }

    final txnId =
        'TXN-${10000000 + DateTime.now().millisecondsSinceEpoch % 90000000}';

    final tx = PaymentTransaction(
      transactionId: txnId,
      jobId: _jobId,
      serviceType: _serviceType,
      serviceProvider: _providerName,
      dateTime: DateTime.now(),
      serviceCharge: _baseCharge,
      additionalCharges: _additionalCharge,
      totalAmount: _totalAmount,
      paymentMethod: selectedMethod.type == PaymentMethodType.card
          ? '${selectedMethod.brand} •••• ${selectedMethod.last4}'
          : selectedMethod.label,
      status: TransactionStatus.completed,
    );

    // Save to PaymentService (Firestore + in-memory)
    await PaymentService().recordTransaction(tx);

    // Also record into EarningsService for provider/mechanic side
    final earning = EarningsRecord(
      jobId: _jobId,
      transactionId: txnId,
      serviceType: _serviceType,
      customerName: 'Driver',
      serviceCharge: _baseCharge,
      platformFee: _additionalCharge > 0 ? (_additionalCharge * 0.2) : 200,
      netEarnings: _baseCharge,
      paymentStatus: 'Completed',
      completedDate: DateTime.now(),
    );
    await EarningsService().recordEarning(earning);

    if (!mounted) return;
    setState(() => _processing = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentConfirmationScreen(transaction: tx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            RoadMateAppHeader(
              title: 'Make Payment',
              showBack: true,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service & Job Summary Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryContainer,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(40),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(35),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  _jobId,
                                  style: AppTypography.labelSm(
                                      color: Colors.white),
                                ),
                              ),
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_rounded,
                                        color: AppColors.onTertiaryContainer,
                                        size: 16),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Service Completed',
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.labelSm(
                                            color: AppColors.tertiaryFixed),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _serviceType,
                            style: AppTypography.headlineSm(
                                color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.engineering_rounded,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _providerName,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySm(
                                      color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Amount Breakdown Card
                    Text('Charge Breakdown',
                        style: AppTypography.labelLg(color: AppColors.primary)),
                    const SizedBox(height: 8),
                    RoadMateCard(
                      child: Column(
                        children: [
                          InfoRow(
                            label: 'Base Service Charge',
                            value: formatCurrency(_baseCharge),
                          ),
                          const Divider(color: AppColors.divider, height: 16),
                          InfoRow(
                            label: 'Travel & Spare Parts Fee',
                            value: formatCurrency(_additionalCharge),
                          ),
                          const Divider(color: AppColors.divider, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Total Payable',
                                  style: AppTypography.titleMd(
                                      color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: AmountDisplay(
                                    amount: _totalAmount,
                                    style: AppTypography.headlineSm(
                                      color: AppColors.secondaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Method Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('Select Payment Method',
                              style:
                                  AppTypography.labelLg(color: AppColors.primary)),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PaymentMethodsScreen(),
                              ),
                            ).then((_) => setState(() {}));
                          },
                          child: Text(
                            '+ Add New',
                            style: AppTypography.labelMd(
                                color: AppColors.secondaryContainer),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // List of methods
                    ...mockPaymentMethods.map((method) {
                      final isSelected = method.id == _selectedMethodId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => _onSelectMethod(method.id),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.surfaceContainerLow
                                  : AppColors.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.cardBorder,
                                width: isSelected ? 1.8 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: method.type == PaymentMethodType.card
                                        ? AppColors.primaryContainer
                                        : method.type ==
                                                PaymentMethodType.wallet
                                            ? AppColors.secondaryContainer
                                            : AppColors.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    method.type == PaymentMethodType.card
                                        ? Icons.credit_card_rounded
                                        : method.type ==
                                                PaymentMethodType.wallet
                                            ? Icons.account_balance_wallet_rounded
                                            : Icons.payments_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        method.label,
                                        style: AppTypography.titleMd(
                                            color: AppColors.onSurface),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        method.subtitle,
                                        style: AppTypography.bodySm(
                                            color: AppColors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.outlineVariant,
                                      width: isSelected ? 6 : 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    if (_isWalletSelected && _isInsufficientBalance) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFFECDD3), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFE4E6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Insufficient wallet balance',
                                    style: AppTypography.titleMd(
                                            color: AppColors.error)
                                        .copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Your wallet balance is ${formatCurrency(_walletBalance)}, but the total payment is ${formatCurrency(_totalAmount)}.',
                              style: AppTypography.bodySm(
                                  color: const Color(0xFF9F1239)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Please add ${formatCurrency(_remainingRequired)} to your wallet or select another payment method.',
                              style: AppTypography.bodySm(
                                      color: const Color(0xFF9F1239))
                                  .copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _showTopUpDialog,
                                  icon: const Icon(
                                      Icons.add_circle_outline_rounded,
                                      size: 16),
                                  label: const Text('Top Up Wallet'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(9999),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final card = mockPaymentMethods.firstWhere(
                                      (m) => m.type == PaymentMethodType.card,
                                      orElse: () => mockPaymentMethods.first,
                                    );
                                    _onSelectMethod(card.id);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    textStyle: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: const Text('Select Card Instead'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Security & Guarantee note
                    Row(
                      children: [
                        const Icon(Icons.security_rounded,
                            color: AppColors.onTertiaryContainer, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '256-Bit SSL Encrypted & Protected RoadMate Guarantee',
                            style: AppTypography.labelSm(
                                color: AppColors.slateText),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pay Now Action Button
                    RoadMatePrimaryButton(
                      label: _isInsufficientBalance
                          ? 'Insufficient Wallet Balance'
                          : 'Pay ${formatCurrency(_totalAmount)}',
                      icon: _isInsufficientBalance
                          ? Icons.block_rounded
                          : Icons.lock_outline_rounded,
                      loading: _processing,
                      color: _isInsufficientBalance
                          ? const Color(0xFFCBD5E1)
                          : AppColors.secondaryContainer,
                      onPressed: _isInsufficientBalance ? null : _handlePayment,
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

import 'package:flutter/material.dart';
import '../models/payment_method.dart';
import '../models/payment_transaction.dart';
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

  @override
  void initState() {
    super.initState();
    _jobId = widget.jobId ?? 'REQ-2026-8921';
    _serviceType = widget.serviceType ?? 'Tire Replacement & Inflation';
    _providerName = widget.providerName ?? 'Kasun Perera (Mobile Tech)';
    _baseCharge = widget.serviceCharge ?? 3500.00;
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

  Future<void> _handlePayment() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 1400));

    final selectedMethod = mockPaymentMethods.firstWhere(
      (m) => m.id == _selectedMethodId,
      orElse: () => mockPaymentMethods.first,
    );

    final tx = PaymentTransaction(
      transactionId: 'TXN-2026-8921',
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

    // Add to history
    mockTransactions.insert(0, tx);

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
                              Row(
                                children: [
                                  const Icon(Icons.verified_rounded,
                                      color: AppColors.onTertiaryContainer,
                                      size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Service Completed',
                                    style: AppTypography.labelSm(
                                        color: AppColors.tertiaryFixed),
                                  ),
                                ],
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
                              Text(
                                _providerName,
                                style: AppTypography.bodySm(
                                    color: Colors.white70),
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
                      label: 'Pay ${formatCurrency(_totalAmount)}',
                      icon: Icons.lock_outline_rounded,
                      loading: _processing,
                      color: AppColors.secondaryContainer,
                      onPressed: _handlePayment,
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

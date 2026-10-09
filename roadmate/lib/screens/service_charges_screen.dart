import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/payment_widgets.dart';
import 'make_payment_screen.dart';

/// Service Charges / Pricing screen matching the Stitch design.
class ServiceChargesScreen extends StatefulWidget {
  final String? serviceType;
  final double? baseCharge;
  final double? distanceCharge;
  final String? jobId;

  const ServiceChargesScreen({
    super.key,
    this.serviceType,
    this.baseCharge,
    this.distanceCharge,
    this.jobId,
  });

  @override
  State<ServiceChargesScreen> createState() => _ServiceChargesScreenState();
}

class _ServiceChargesScreenState extends State<ServiceChargesScreen> {
  late String _serviceType;
  late double _baseCharge;
  late double _distanceCharge;
  late double _platformFee;
  late double _estimatedTotal;
  late String _jobId;

  // Selected service option
  final List<Map<String, dynamic>> _serviceCatalog = [
    {
      'type': 'Tire Replacement & Repair',
      'base': 3500.0,
      'desc': 'On-site spare tire fitment, puncture plug, or inflation',
      'icon': Icons.tire_repair_rounded,
    },
    {
      'type': 'Battery Jumpstart',
      'base': 2500.0,
      'desc': 'Heavy-duty jump starter pack or booster cables service',
      'icon': Icons.battery_charging_full_rounded,
    },
    {
      'type': 'Emergency Towing',
      'base': 6500.0,
      'desc': 'Flatbed or wheel-lift tow to nearest verified workshop',
      'icon': Icons.fire_truck_rounded,
    },
    {
      'type': 'Emergency Fuel Delivery',
      'base': 2000.0,
      'desc': '5L petrol/diesel delivered directly to roadside location',
      'icon': Icons.local_gas_station_rounded,
    },
    {
      'type': 'Lockout & Key Rescue',
      'base': 3000.0,
      'desc': 'Non-destructive vehicle entry by verified technician',
      'icon': Icons.lock_open_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _jobId = widget.jobId ?? 'REQ-2026-8921';
    _serviceType = widget.serviceType ?? 'Tire Replacement & Repair';
    _baseCharge = widget.baseCharge ?? 3500.0;
    _distanceCharge = widget.distanceCharge ?? 500.0;
    _platformFee = 250.0;
    _calculateTotal();
  }

  void _calculateTotal() {
    _estimatedTotal = _baseCharge + _distanceCharge + _platformFee;
  }

  void _selectService(Map<String, dynamic> item) {
    setState(() {
      _serviceType = item['type'] as String;
      _baseCharge = item['base'] as double;
      _calculateTotal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            RoadMateAppHeader(
              title: 'Pricing & Service Charges',
              showBack: true,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transparent Pricing Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: AppColors.surfaceContainerHigh),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Guaranteed Standard Rates',
                                  style: AppTypography.titleMd(
                                      color: AppColors.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'No surge pricing or hidden dispatch fees. Pay only for verified assistance.',
                                  style: AppTypography.bodySm(
                                      color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Estimated Pricing Breakdown Card
                    SectionHeader(title: 'Estimated Charge Breakdown'),
                    RoadMateCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _serviceType,
                                  style: AppTypography.titleMd(
                                      color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatCurrency(_baseCharge),
                                style: AppTypography.titleMd(
                                    color: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Standard base rate for on-site diagnosis and repair',
                            style: AppTypography.bodySm(
                                color: AppColors.onSurfaceVariant),
                          ),
                          const Divider(color: AppColors.divider, height: 20),
                          InfoRow(
                            label: 'Technician Travel Fee (4.8 km)',
                            value: formatCurrency(_distanceCharge),
                          ),
                          const Divider(color: AppColors.divider, height: 20),
                          InfoRow(
                            label: 'RoadMate Platform Guarantee Fee',
                            value: formatCurrency(_platformFee),
                          ),
                          const Divider(color: AppColors.divider, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Estimated Total',
                                      style: AppTypography.headlineSm(
                                          color: AppColors.primary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Final price confirmed upon service completion',
                                      style: AppTypography.labelSm(
                                          color: AppColors.slateText),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: AmountDisplay(
                                    amount: _estimatedTotal,
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

                    // Service Rate Card Catalog
                    SectionHeader(title: 'RoadMate Standard Rates'),
                    ..._serviceCatalog.map((item) {
                      final isSelected = item['type'] == _serviceType;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => _selectService(item),
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
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.surfaceContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    item['icon'] as IconData,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['type'] as String,
                                        style: AppTypography.titleMd(
                                            color: AppColors.primary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item['desc'] as String,
                                        style: AppTypography.bodySm(
                                            color: AppColors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatCurrency(item['base'] as double),
                                  style: AppTypography.labelLg(
                                    color: isSelected
                                        ? AppColors.secondaryContainer
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),

                    // Transparent Policy Bullet Notes
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: AppColors.secondaryContainer,
                                  size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pricing Policy',
                                  style: AppTypography.titleMd(
                                      color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _policyBullet(
                              'Fixed base rate applies within standard 10 km service radius.'),
                          _policyBullet(
                              'Spare parts or batteries replaced are charged according to supplier invoices.'),
                          _policyBullet(
                              'Payment is only debited or transferred after job completion.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Proceed to Make Payment Button
                    RoadMatePrimaryButton(
                      label: 'Proceed to Payment (${formatCurrency(_estimatedTotal)})',
                      icon: Icons.payment_rounded,
                      color: AppColors.secondaryContainer,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MakePaymentScreen(
                              jobId: _jobId,
                              serviceType: _serviceType,
                              serviceCharge: _baseCharge,
                              additionalCharges: _distanceCharge + _platformFee,
                            ),
                          ),
                        );
                      },
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

  Widget _policyBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.slateText, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySm(color: AppColors.slateText),
            ),
          ),
        ],
      ),
    );
  }
}

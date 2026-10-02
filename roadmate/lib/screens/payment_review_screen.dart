import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/app_user.dart';
import '../models/service_request.dart';
import '../services/assistance_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'request_success_screen.dart';

/// Step 3b of the driver flow: rate + pay before the request is sent.
/// Pops `true` (→ Requests tab), `'home'`, or a tab index, like the rest.
class PaymentReviewScreen extends StatefulWidget {
  final AppUser user;
  final AssistanceType serviceType;
  final String address;
  final AssistanceService? assistanceService;

  const PaymentReviewScreen({
    super.key,
    required this.user,
    required this.serviceType,
    required this.address,
    this.assistanceService,
  });

  @override
  State<PaymentReviewScreen> createState() => _PaymentReviewScreenState();
}

class _PaymentReviewScreenState extends State<PaymentReviewScreen> {
  int _rating = 4;
  final _feedback = TextEditingController();
  final _tags = <String>{'Professional'};
  String _method = 'card';
  bool _submitting = false;

  AssistanceService get _assist =>
      widget.assistanceService ?? AssistanceService();

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _complete() async {
    if (!firebaseReady) {
      _snack('Firebase not connected yet. Add google-services files first.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final fee = feeFor(widget.serviceType);
      final requestId = await _assist.createRequest(
        driverUid: widget.user.uid,
        driverName: widget.user.name,
        type: widget.serviceType,
        address: widget.address,
        paymentMethod: _method,
        rating: _rating,
        feedback: _feedback.text.trim(),
        totalFee: fee.total,
      );
      if (!mounted) return;
      final result = await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RequestSuccessScreen(
            requestId: requestId,
            serviceType: widget.serviceType,
            address: widget.address,
          ),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, result ?? true);
    } catch (e) {
      _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fee = feeFor(widget.serviceType);
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Top bar
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_rounded,
                          size: 22, color: AppColors.navy),
                      SizedBox(width: 6),
                      Text(
                        'RoadMate',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.navy,
                    child: Icon(Icons.person_rounded,
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.navyDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rate Your Experience',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          'How was the service during your breakdown?',
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.greyText),
                        ),
                      ],
                    ),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'REQUEST',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.greyText,
                        ),
                      ),
                      Text(
                        '#NEW',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.help_outline_rounded,
                      size: 20, color: AppColors.greyText),
                ],
              ),
              const SizedBox(height: 14),

              // Mechanic preview card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.fieldFill,
                      child: Icon(Icons.person_rounded,
                          color: AppColors.navy, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nearby Patrol',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navyDark,
                            ),
                          ),
                          Text(
                            'Assigned on dispatch',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDE0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'On-Duty',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_ratingLabel()} (${_rating.toStringAsFixed(1)})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const Text(
                    'Tap star to rate',
                    style:
                        TextStyle(fontSize: 11.5, color: AppColors.greyText),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (int i = 1; i <= 5; i++)
                    GestureDetector(
                      onTap: () => setState(() => _rating = i),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          i <= _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 34,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Feedback
              TextField(
                controller: _feedback,
                maxLines: 3,
                style: const TextStyle(
                    fontSize: 13.5, color: AppColors.navyDark),
                decoration: InputDecoration(
                  hintText:
                      'Share feedback (optional) — the dispatch team reads every note…',
                  hintStyle: const TextStyle(
                      color: AppColors.fieldHint, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFE3E8F0), width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFE3E8F0), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.navy, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in const [
                    'Fast Arrival',
                    'Professional',
                    'Polite',
                    'Careful Handling'
                  ])
                    _Tag(
                      label: t,
                      selected: _tags.contains(t),
                      onTap: () => setState(() => _tags.contains(t)
                          ? _tags.remove(t)
                          : _tags.add(t)),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Payment summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payment Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.receipt_long_outlined,
                          size: 15, color: AppColors.greyText),
                      SizedBox(width: 4),
                      Text(
                        'Receipt emailed',
                        style: TextStyle(
                            fontSize: 11.5, color: AppColors.greyText),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
                ),
                child: Column(
                  children: [
                    _FeeRow(label: fee.line1, value: formatFee(fee.fee1)),
                    const SizedBox(height: 8),
                    _FeeRow(label: fee.line2, value: formatFee(fee.fee2)),
                    const Divider(height: 20, color: Color(0xFFEDF1F7)),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL PAID',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyDark,
                          ),
                        ),
                        Text(
                          'Taxes & toll included',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.greyText),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        formatFee(fee.total),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Payment method
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  Text(
                    'Selected Account',
                    style:
                        TextStyle(fontSize: 11.5, color: AppColors.greyText),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MethodCard(
                      selected: _method == 'card',
                      onTap: () => setState(() => _method = 'card'),
                      icon: Icons.credit_card_rounded,
                      title: 'Card •• 4242',
                      subtitle: 'VISA Exp 08/27',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MethodCard(
                      selected: _method == 'cash',
                      onTap: () => setState(() => _method = 'cash'),
                      icon: Icons.money_outlined,
                      title: 'Cash on Site',
                      subtitle: 'Driver receipt',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Complete & submit
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _complete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Complete & Submit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) => Navigator.pop(context, i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.greyText,
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.garage_outlined),
            label: 'Garage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Chat',
          ),
        ],
      ),
    );
  }

  String _ratingLabel() => switch (_rating) {
        5 => 'Excellent Service!',
        4 => 'Great Service!',
        3 => 'Good Service',
        2 => 'Needs Work',
        _ => 'Poor Service',
      };
}

/// Fixed-rate fee breakdown per service type.
class ServiceFee {
  final String line1;
  final double fee1;
  final String line2;
  final double fee2;
  const ServiceFee(this.line1, this.fee1, this.line2, this.fee2);
  double get total => fee1 + fee2;
}

ServiceFee feeFor(AssistanceType t) => switch (t) {
      AssistanceType.flatTyre =>
        const ServiceFee('Flatbed Dispatch & Triage', 2800, 'Tyre Change Labour', 700),
      AssistanceType.jumpStart =>
        const ServiceFee('Jumpstart Dispatch', 1800, 'Battery Diagnostic', 700),
      AssistanceType.fuelDrop =>
        const ServiceFee('Fuel Delivery & Triage', 3200, 'On-site Service', 800),
      AssistanceType.towing =>
        const ServiceFee('Flatbed Dispatch & Triage', 2800, 'Towing (10 km)', 5700),
      AssistanceType.general =>
        const ServiceFee('Dispatch & Triage', 2300, 'Inspection', 700),
    };

String formatFee(double v) {
  final s = v.toStringAsFixed(2);
  final parts = s.split('.');
  final digits = parts[0].split('').reversed.toList();
  final buf = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && i % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return 'Rs. ${buf.toString().split('').reversed.join()}.${parts[1]}';
}

class _Tag extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tag({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFEDE0) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.orange : const Color(0xFFE3E8F0),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              const Icon(Icons.check_rounded,
                  size: 14, color: AppColors.orange),
            if (selected) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.orange : AppColors.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  const _FeeRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13.5, color: AppColors.greyText),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
          ),
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  const _MethodCard({
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.navy : const Color(0xFFE3E8F0),
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: AppColors.navy,
              ),
          ],
        ),
      ),
    );
  }
}

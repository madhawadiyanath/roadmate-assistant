import 'package:flutter/material.dart';

import '../models/payment_transaction.dart';
import '../models/payments.dart';
import '../models/service_request.dart';
import '../theme/app_colors.dart';
import 'digital_receipt_screen.dart';

/// Step 4 of the driver flow: success receipt after Submit.
/// Pops `true` (Track Request → Requests tab), `'home'` (Back to Home),
/// or a dashboard tab index from the bottom nav / X.
class RequestSuccessScreen extends StatelessWidget {
  final String refCode;
  final AssistanceType serviceType;
  final String address;
  final String vehicleDisplay;
  final PaymentTransaction? transaction;
  final TxnRecord? txn;

  const RequestSuccessScreen({
    super.key,
    required this.refCode,
    required this.serviceType,
    required this.address,
    this.vehicleDisplay = 'No vehicle selected',
    this.transaction,
    this.txn,
  });

  String get _refCode => refCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
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
              const SizedBox(height: 12),

              // Dispatch strip
              Row(
                children: [
                  const Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_fire_department_outlined,
                            size: 15, color: AppColors.orange),
                        SizedBox(width: 6),
                        Text(
                          'Priority Dispatch Active',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, 'home'),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.greyText,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Success check
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFF22B573).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22B573),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Request Submitted!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Your request has been received. A certified service patrol will be assigned to your vehicle shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppColors.greyText,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle,
                        size: 9, color: Color(0xFF22B573)),
                    SizedBox(width: 7),
                    Text(
                      'Status: Searching Nearby Patrol',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Receipt card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'REQUEST ID',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: AppColors.greyText,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.fieldFill,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.my_location_rounded,
                                  size: 12, color: AppColors.orange),
                              SizedBox(width: 4),
                              Text(
                                'GPS Locked',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _refCode,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    const Divider(height: 22, color: Color(0xFFEDF1F7)),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.fieldFill,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.watch_later_outlined,
                            color: AppColors.navy,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estimated Arrival',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.greyText,
                                ),
                              ),
                              Text(
                                serviceType.eta,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7EE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Optimal Route',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF22B573),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 22, color: Color(0xFFEDF1F7)),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDE0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.tire_repair_rounded,
                            color: AppColors.orange,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${serviceType.label} Assistance',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              Text(
                                vehicleDisplay,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.greyText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 22, color: Color(0xFFEDF1F7)),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: AppColors.fieldFill,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_outlined,
                            color: AppColors.navy,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '24/7 Roadside Hotline',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.greyText,
                                ),
                              ),
                              Text(
                                '1-800-ROADMATE',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: AppColors.fieldFill,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_outlined,
                            color: AppColors.orange,
                            size: 19,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Track request
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.track_changes_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Track Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
              // Digital receipt
              if (transaction != null || txn != null) ...[
                const SizedBox(height: 2),
                TextButton(
                  onPressed: () {
                    final tx = transaction ?? txn?.toPaymentTransaction();
                    if (tx != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DigitalReceiptScreen(transaction: tx),
                        ),
                      );
                    }
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 18, color: AppColors.navy),
                      SizedBox(width: 6),
                      Text(
                        'View Receipt',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 6),

              // Back home
              TextButton(
                onPressed: () => Navigator.pop(context, 'home'),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_outlined,
                        size: 18, color: AppColors.greyText),
                    SizedBox(width: 6),
                    Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
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
}

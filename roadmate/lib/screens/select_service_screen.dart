import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/service_request.dart';
import '../theme/app_colors.dart';

/// Full-screen service catalogue (emergency clarity):
/// big rows with icon, title, description and chevron.
/// Pops with the picked [AssistanceType], or with a dashboard tab index
/// when the bottom nav is used.
class SelectServiceScreen extends StatelessWidget {
  final AppUser user;
  const SelectServiceScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
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
                    child: Text(
                      user.name.trim().isEmpty
                          ? 'D'
                          : user.name.trim()[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Back + live badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.navyDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF2F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle,
                            size: 8, color: AppColors.orange),
                        SizedBox(width: 6),
                        Text(
                          'LIVE DISPATCH',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              const Text(
                'Select Service',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'What do you need help with?',
                style: TextStyle(fontSize: 13.5, color: AppColors.greyText),
              ),
              const SizedBox(height: 16),

              for (final item in _items) ...[
                _ServiceRow(item: item),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 8),
              const _DispatchCallBanner(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _ServiceNav(
        onTap: (i) => Navigator.pop(context, i),
      ),
    );
  }
}

class _ServiceItem {
  final AssistanceType type;
  final String title;
  final String desc;
  final IconData icon;
  const _ServiceItem({
    required this.type,
    required this.title,
    required this.desc,
    required this.icon,
  });
}

const _items = [
  _ServiceItem(
    type: AssistanceType.flatTyre,
    title: 'Flat Tyre',
    desc: 'Puncture repair or tyre change',
    icon: Icons.tire_repair_rounded,
  ),
  _ServiceItem(
    type: AssistanceType.jumpStart,
    title: 'Battery Jump Start',
    desc: 'Fast on-site battery booster',
    icon: Icons.bolt_rounded,
  ),
  _ServiceItem(
    type: AssistanceType.fuelDrop,
    title: 'Fuel Delivery',
    desc: 'Petrol or Diesel drop to location',
    icon: Icons.local_gas_station_rounded,
  ),
  _ServiceItem(
    type: AssistanceType.towing,
    title: 'Towing Service',
    desc: 'Flatbed & wheel-lift tow to garage',
    icon: Icons.local_shipping_rounded,
  ),
  _ServiceItem(
    type: AssistanceType.general,
    title: 'Other',
    desc: 'Lockout, mechanical check & more',
    icon: Icons.more_horiz_rounded,
  ),
];

class _ServiceRow extends StatelessWidget {
  final _ServiceItem item;
  const _ServiceRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, item.type),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: AppColors.navy, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.desc,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.fieldFill,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DispatchCallBanner extends StatelessWidget {
  const _DispatchCallBanner();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: const Color(0xFF5B8DEF),
        radius: 14,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.peachBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_in_talk_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Immediate Dispatch?',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  Text(
                    'Call 1-800-ROADMATE (24/7)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.orange,
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: const Row(
                children: [
                  Text(
                    'Call',
                    style: TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedBorderPainter({required this.color, this.radius = 14});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const dash = 5.0, gap = 4.0;
    final path = Path()
      ..addRRect(RRect.fromLTRBR(
          0, 0, size.width, size.height, Radius.circular(radius)));
    final metrics = path.computeMetrics().first;
    double d = 0;
    while (d < metrics.length) {
      canvas.drawPath(
          metrics.extractPath(d, (d + dash).clamp(0, metrics.length)), paint);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ServiceNav extends StatelessWidget {
  final ValueChanged<int> onTap;
  const _ServiceNav({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.orange,
      unselectedItemColor: AppColors.greyText,
      selectedLabelStyle:
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
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
    );
  }
}

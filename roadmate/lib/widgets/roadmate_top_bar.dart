import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Brand header used on the garage pages: shield logo, "RoadMate" and the
/// round profile button on the right.
class RoadMateTopBar extends StatelessWidget {
  final VoidCallback? onAvatarTap;
  const RoadMateTopBar({super.key, this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Row(
        children: [
          const _ShieldLogo(),
          const SizedBox(width: 8),
          const Text(
            'RoadMate',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              letterSpacing: -0.4,
            ),
          ),
          const Spacer(),
          Semantics(
            button: true,
            label: 'Profile',
            child: GestureDetector(
              onTap: onAvatarTap,
              child: const CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.navy,
                child: Icon(Icons.person_outline_rounded,
                    size: 21, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShieldLogo extends StatelessWidget {
  const _ShieldLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.shield_rounded, color: AppColors.navy, size: 34),
          const Positioned(
            top: 8,
            child: Icon(Icons.directions_car_filled_rounded,
                color: Colors.white, size: 14),
          ),
          Positioned(
            top: 3,
            right: 5,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page heading row: optional back arrow, bold title, optional trailing
/// widget (e.g. the "4 vehicles" pill).
class RoadMatePageTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  const RoadMatePageTitle({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 18, 4),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.navy, size: 26),
            )
          else
            const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
                letterSpacing: -0.4,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

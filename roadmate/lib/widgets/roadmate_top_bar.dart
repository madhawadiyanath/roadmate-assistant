import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// "RoadMate" logo row + round profile button shown at the top of the
/// module screens (same bar as the job details screen).
class RoadMateTopBar extends StatelessWidget {
  final VoidCallback? onAvatarTap;
  const RoadMateTopBar({super.key, this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.shield_rounded, size: 22, color: AppColors.navy),
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
        GestureDetector(
          onTap: onAvatarTap,
          child: const CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.navy,
            child:
                Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}

/// Back arrow + page title row used under [RoadMateTopBar].
class PageTitleRow extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  const PageTitleRow({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          GestureDetector(
            onTap: onBack,
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.navyDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

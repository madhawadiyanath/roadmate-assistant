import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../theme/app_colors.dart';

/// Driver / Mechanic picker used on Sign Up.
class RoleSelector extends StatelessWidget {
  final AppRole selected;
  final ValueChanged<AppRole> onChanged;
  const RoleSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            role: AppRole.driver,
            title: 'Driver',
            subtitle: 'Need rescue',
            icon: Icons.directions_car_filled_rounded,
            selected: selected == AppRole.driver,
            onTap: () => onChanged(AppRole.driver),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RoleCard(
            role: AppRole.mechanic,
            title: 'Mechanic',
            subtitle: 'Give rescue',
            icon: Icons.build_rounded,
            selected: selected == AppRole.mechanic,
            onTap: () => onChanged(AppRole.mechanic),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final AppRole role;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? AppColors.navy : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 26,
              color: selected ? Colors.white : AppColors.navy,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.navyDark,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? Colors.white.withValues(alpha: 0.75)
                    : AppColors.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

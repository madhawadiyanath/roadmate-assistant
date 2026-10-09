import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centered icon + title + message for the non-list states of a page
/// (empty, error, "Firebase not connected").
class StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color = AppColors.greyText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 96),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: AppColors.greyText),
            ),
          ],
        ),
      ),
    );
  }
}

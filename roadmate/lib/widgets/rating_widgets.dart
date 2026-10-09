import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Quick tags offered on the rating screen.
const ratingTags = ['Fast Arrival', 'Professional', 'Polite', 'Careful Handling'];

/// "Great Service!" for 4 stars, and so on. 0 = nothing picked yet.
String ratingLabel(int rating) => switch (rating) {
      5 => 'Excellent Service!',
      4 => 'Great Service!',
      3 => 'Good Service',
      2 => 'Needs Work',
      1 => 'Poor Service',
      _ => 'How was the service?',
    };

/// Five stars. Interactive when [onChanged] is set, read-only otherwise.
class StarRow extends StatelessWidget {
  final int rating;
  final ValueChanged<int>? onChanged;
  final double size;

  const StarRow({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            key: Key('star-$i'),
            onTap: onChanged == null ? null : () => onChanged!(i),
            child: Padding(
              padding: EdgeInsets.only(right: onChanged == null ? 2 : 6),
              child: Icon(
                i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: AppColors.orange,
                semanticLabel: '$i star${i == 1 ? '' : 's'}',
              ),
            ),
          ),
      ],
    );
  }
}

/// Selectable quick-tag chip ("✓ Professional").
class RatingTagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const RatingTagChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
              if (selected) ...[
                const Icon(Icons.check_rounded,
                    size: 15, color: AppColors.orange),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.orange : AppColors.greyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

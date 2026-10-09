import 'package:flutter/material.dart';

import '../models/emergency_contact.dart';
import '../theme/app_colors.dart';

({Color fg, Color bg}) _relationColors(ContactRelation r) {
  switch (r) {
    case ContactRelation.family:
    case ContactRelation.spouse:
      return (fg: const Color(0xFFB45A06), bg: AppColors.peachBg);
    case ContactRelation.friend:
      return (fg: const Color(0xFF2F5BD9), bg: const Color(0xFFE8EEFF));
    case ContactRelation.colleague:
      return (fg: const Color(0xFF1C8C5A), bg: const Color(0xFFE6F7EE));
  }
}

/// "Family" / "Friend" ... pill, coloured per relation.
class RelationChip extends StatelessWidget {
  final ContactRelation relation;
  const RelationChip({super.key, required this.relation});

  @override
  Widget build(BuildContext context) {
    final c = _relationColors(relation);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        relation.label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: c.fg,
        ),
      ),
    );
  }
}

/// One emergency contact: initials avatar, name, phone, relation, and
/// edit / delete buttons.
class ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8F5), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: Text(
              contact.initials,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contact.phone,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: 6),
                RelationChip(relation: contact.relation),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SquareButton(
            tooltip: 'Edit ${contact.name}',
            icon: Icons.edit_outlined,
            fg: AppColors.navy,
            bg: const Color(0xFFEEF2FF),
            onTap: onEdit,
          ),
          const SizedBox(width: 8),
          _SquareButton(
            tooltip: 'Delete ${contact.name}',
            icon: Icons.delete_outline_rounded,
            fg: const Color(0xFFE5484D),
            bg: const Color(0xFFFDE8E8),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color fg;
  final Color bg;
  final VoidCallback onTap;
  const _SquareButton({
    required this.tooltip,
    required this.icon,
    required this.fg,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 21, color: fg),
          ),
        ),
      ),
    );
  }
}

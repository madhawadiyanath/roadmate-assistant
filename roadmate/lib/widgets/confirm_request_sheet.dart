import 'package:flutter/material.dart';

import '../models/service_request.dart';
import '../theme/app_colors.dart';

/// Shared "confirm before dispatch" sheet used by the driver flow.
/// Shows [address] when the location step already ran.
class ConfirmRequestSheet extends StatelessWidget {
  final AssistanceType type;
  final String address;
  const ConfirmRequestSheet({super.key, required this.type, this.address = ''});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emergency_rounded,
              color: AppColors.orange,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Confirm ${type.label}?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            address.isEmpty
                ? 'ETA ${type.eta} • GPS location will be shared with the mechanic.'
                : 'ETA ${type.eta} • $address',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.greyText),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Confirm',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

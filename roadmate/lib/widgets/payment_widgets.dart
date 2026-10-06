import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Reusable RoadMate app header matching the Stitch design:
/// back button + title on the left, help + profile avatar on the right.
class RoadMateAppHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;

  const RoadMateAppHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (showBack)
            GestureDetector(
              onTap: onBack ?? () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
          if (showBack) const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: AppTypography.headlineSm(color: AppColors.primary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(
                Icons.help_outline_rounded,
                color: AppColors.onSurfaceVariant,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.onPrimary,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width primary action button (pill shape, dark navy fill).
class RoadMatePrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? color;

  const RoadMatePrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 2,
          shadowColor: AppColors.primary.withAlpha(40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: AppTypography.labelLg(color: AppColors.onPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Secondary / outline button with surface-container-high fill.
class RoadMateSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const RoadMateSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceContainerHigh,
          foregroundColor: AppColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: AppTypography.labelLg(color: AppColors.primary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard card container matching the Stitch card style.
class RoadMateCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;

  const RoadMateCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Status badge matching Stitch status pills.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  factory StatusBadge.completed() => const StatusBadge(
        label: 'Completed',
        bgColor: AppColors.successBg,
        textColor: AppColors.successText,
      );

  factory StatusBadge.pending() => const StatusBadge(
        label: 'Pending',
        bgColor: AppColors.pendingBg,
        textColor: AppColors.pendingText,
      );

  factory StatusBadge.failed() => const StatusBadge(
        label: 'Failed',
        bgColor: AppColors.errorContainer,
        textColor: AppColors.error,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(label, style: AppTypography.labelSm(color: textColor)),
    );
  }
}

/// Reusable info row for receipt/detail screens: label on left, value on right.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Widget? trailing;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: trailing ??
                Text(
                  value,
                  style: bold
                      ? AppTypography.titleMd(color: AppColors.primary)
                      : AppTypography.bodyMd(color: AppColors.onSurface),
                  textAlign: TextAlign.end,
                ),
          ),
        ],
      ),
    );
  }
}

/// Section header: title on left, optional action text on right.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.labelLg(color: AppColors.primary),
            ),
          ),
          if (actionText != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionText!,
                style: AppTypography.labelMd(color: AppColors.secondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Payment amount display with currency formatting.
class AmountDisplay extends StatelessWidget {
  final double amount;
  final TextStyle? style;

  const AmountDisplay({super.key, required this.amount, this.style});

  @override
  Widget build(BuildContext context) {
    final formatted = _formatCurrency(amount);
    return Text(
      formatted,
      style: style ?? AppTypography.headlineLg(color: AppColors.primary),
    );
  }

  static String _formatCurrency(double v) {
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
}

/// Format a currency value as "Rs. X,XXX.XX".
String formatCurrency(double v) => AmountDisplay._formatCurrency(v);

/// RoadMate bottom navigation bar matching the Stitch design.
class RoadMateBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const RoadMateBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.secondaryContainer,
      unselectedItemColor: AppColors.slateText,
      selectedLabelStyle: AppTypography.labelSm(),
      unselectedLabelStyle: AppTypography.labelSm(),
      elevation: 8,
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
    );
  }
}

/// Transaction list item used in Payment History & Transaction History.
class TransactionListItem extends StatelessWidget {
  final String serviceType;
  final String transactionId;
  final String date;
  final String amount;
  final String status;
  final VoidCallback? onTap;

  const TransactionListItem({
    super.key,
    required this.serviceType,
    required this.transactionId,
    required this.date,
    required this.amount,
    this.status = 'Completed',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'Completed';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.build_circle_outlined,
                  color: AppColors.onPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceType,
                    style: AppTypography.titleMd(color: AppColors.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$transactionId • $date',
                    style:
                        AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: AppTypography.titleMd(color: AppColors.primary),
                ),
                const SizedBox(height: 2),
                StatusBadge(
                  label: status,
                  bgColor:
                      isCompleted ? AppColors.successBg : AppColors.pendingBg,
                  textColor: isCompleted
                      ? AppColors.successText
                      : AppColors.pendingText,
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.mutedText, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Validates an expiration date string in MM/YY format.
/// Returns null if valid, or a descriptive error message if invalid.
String? validateCardExpiry(String? value, {DateTime? now}) {
  if (value == null || value.trim().isEmpty) {
    return 'Enter a valid expiration date (MM/YY)';
  }

  final trimmed = value.trim();
  final parts = trimmed.split('/');
  if (parts.length != 2 || parts[0].length != 2 || parts[1].length != 2) {
    return 'Enter a valid expiration date (MM/YY)';
  }

  final month = int.tryParse(parts[0]);
  final year = int.tryParse(parts[1]);

  if (month == null || month < 1 || month > 12) {
    return 'Enter a valid expiration date (MM/YY)';
  }

  if (year == null) {
    return 'Enter a valid expiration date (MM/YY)';
  }

  final currentDate = now ?? DateTime.now();
  final fullYear = 2000 + year;
  final currentYear = currentDate.year;
  final currentMonth = currentDate.month;

  if (fullYear < currentYear || (fullYear == currentYear && month < currentMonth)) {
    return 'Card has expired';
  }

  return null;
}

/// Custom formatter for card expiration date enforcing strict MM/YY format:
/// - Only digits allowed.
/// - Month strictly 01-12 (typing 2-9 auto-prefixes with 0; month 00 or >12 is blocked).
/// - Automatically places '/' after the 2-digit month.
/// - Year is strictly 2 digits. Maximum 5 characters total (MM/YY).
class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    // 1. If empty, allow clearing
    if (newText.isEmpty) {
      return newValue;
    }

    // 2. Handle deletion across slash:
    // If the slash was deleted by the user
    if (oldText.contains('/') && !newText.contains('/')) {
      final oldSlashIdx = oldText.indexOf('/');
      final beforeSlash = oldText.substring(0, oldSlashIdx);
      final afterSlash = oldText.substring(oldSlashIdx + 1);
      final shortenedBefore = beforeSlash.isNotEmpty
          ? beforeSlash.substring(0, beforeSlash.length - 1)
          : '';
      if (shortenedBefore.isEmpty && afterSlash.isEmpty) {
        return const TextEditingValue(text: '');
      }
      final newFormatted = afterSlash.isNotEmpty
          ? '$shortenedBefore/$afterSlash'
          : shortenedBefore;
      return TextEditingValue(
        text: newFormatted,
        selection: TextSelection.collapsed(offset: shortenedBefore.length),
      );
    }

    // 3. User is deleting characters (backspace) within month or year
    if (newText.length < oldText.length) {
      return newValue;
    }

    // 4. User typed '/' or pasted with '/'
    if (newText.contains('/')) {
      final parts = newText.split('/');
      final monthDigits = parts[0].replaceAll(RegExp(r'\D'), '');
      final yearDigits = parts.length > 1
          ? parts[1].replaceAll(RegExp(r'\D'), '')
          : '';

      // If month was a single digit (e.g. typing 1 then / -> 01/)
      if (monthDigits.length == 1) {
        final mNum = int.tryParse(monthDigits) ?? 0;
        if (mNum >= 1 && mNum <= 9) {
          final padded = '0$monthDigits';
          final clampedYear = yearDigits.length > 2
              ? yearDigits.substring(0, 2)
              : yearDigits;
          final formatted = '$padded/$clampedYear';
          return TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(
              offset: yearDigits.isEmpty ? 3 : formatted.length,
            ),
          );
        } else {
          return oldValue;
        }
      }

      if (monthDigits.length == 2) {
        final mNum = int.tryParse(monthDigits) ?? 0;
        if (mNum < 1 || mNum > 12) {
          return oldValue;
        }
        if (yearDigits.length > 2) {
          return oldValue;
        }
        final formatted = '$monthDigits/$yearDigits';
        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }

    // 5. User typing numbers without slash
    final digits = newText.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    if (digits.length > 4) {
      return oldValue;
    }

    final buffer = StringBuffer();
    final firstChar = digits[0];
    final firstNum = int.parse(firstChar);

    if (digits.length == 1) {
      if (firstNum >= 2 && firstNum <= 9) {
        // Digits 2-9 cannot have another month digit -> auto prefix with 0 and add /
        buffer.write('0$firstChar/');
      } else {
        // 0 or 1
        buffer.write(firstChar);
      }
    } else {
      // 2 or more digits
      final monthStr = digits.substring(0, 2);
      final monthNum = int.parse(monthStr);

      if (monthNum == 0 || monthNum > 12) {
        return oldValue;
      }

      buffer.write(monthStr);
      buffer.write('/');

      if (digits.length > 2) {
        buffer.write(digits.substring(2));
      }
    }

    final formatted = buffer.toString();
    int cursorPosition = formatted.length;
    if (newValue.selection.end < newText.length) {
      cursorPosition = newValue.selection.end;
      if (formatted.length > newText.length) {
        cursorPosition += (formatted.length - newText.length);
      }
      cursorPosition = cursorPosition.clamp(0, formatted.length);
    }

    if (cursorPosition == 2 && formatted.length >= 3 && formatted[2] == '/') {
      cursorPosition = 3;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

/// Reusable styled text field matching Stitch form inputs.
class RoadMateTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLength;
  final String? helperText;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  const RoadMateTextField({
    super.key,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
    this.helperText,
    this.errorText,
    this.inputFormatters,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelLg(color: AppColors.onSurface)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLength: maxLength,
          inputFormatters: inputFormatters?.cast(),
          onChanged: onChanged,
          style: AppTypography.titleMd(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                AppTypography.titleMd(color: AppColors.outlineVariant),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: AppColors.onSurfaceVariant)
                : null,
            suffixIcon: suffix,
            counterText: '',
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: errorText != null
                  ? const BorderSide(color: AppColors.error, width: 1.2)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? AppColors.error : AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: AppTypography.bodySm(color: AppColors.error),
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

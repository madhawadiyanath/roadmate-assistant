import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

const _unreadTint = Color(0xFFEEF2FF);

/// Icon + colours for each notification type.
({IconData icon, Color fg, Color bg}) notificationVisual(NotificationType t) {
  switch (t) {
    case NotificationType.accepted:
      return (
        icon: Icons.build_rounded,
        fg: const Color(0xFFB45A06),
        bg: AppColors.peachBg
      );
    case NotificationType.arriving:
      return (
        icon: Icons.local_shipping_rounded,
        fg: const Color(0xFF2F5BD9),
        bg: const Color(0xFFE8EEFF)
      );
    case NotificationType.message:
      return (
        icon: Icons.chat_bubble_outline_rounded,
        fg: const Color(0xFF1C8C5A),
        bg: const Color(0xFFE6F7EE)
      );
    case NotificationType.completed:
      return (
        icon: Icons.check_circle_outline_rounded,
        fg: const Color(0xFF1C8C5A),
        bg: const Color(0xFFE6F7EE)
      );
    case NotificationType.receipt:
      return (
        icon: Icons.receipt_long_outlined,
        fg: const Color(0xFF2F5BD9),
        bg: const Color(0xFFE8EEFF)
      );
    case NotificationType.cancelled:
      return (
        icon: Icons.cancel_outlined,
        fg: const Color(0xFFE5484D),
        bg: const Color(0xFFFDE8E8)
      );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Notifications whose server timestamp has not resolved yet (just
/// created) count as today.
bool isTodayNotification(AppNotification n, {DateTime? now}) =>
    n.createdAt == null || _sameDay(n.createdAt!, now ?? DateTime.now());

/// "Just now", "2 min ago", "3 hr ago", "Yesterday · 6:52 PM",
/// "12 Mar · 6:52 PM".
String notificationTimeLabel(DateTime? t, {DateTime? now}) {
  if (t == null) return 'Just now';
  final n = now ?? DateTime.now();
  final diff = n.difference(t);
  if (_sameDay(t, n)) {
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return '${diff.inHours} hr ago';
  }
  final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  final clock = '$hour12:$minute ${t.hour < 12 ? 'AM' : 'PM'}';
  final yesterday = n.subtract(const Duration(days: 1));
  if (_sameDay(t, yesterday)) return 'Yesterday · $clock';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${t.day} ${months[t.month - 1]} · $clock';
}

/// One inbox row. Unread rows are tinted and carry an orange dot.
class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final DateTime? now;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final v = notificationVisual(n.type);
    return Semantics(
      button: true,
      label: n.read ? n.title : 'Unread, ${n.title}',
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: n.read ? Colors.white : _unreadTint,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: v.bg, shape: BoxShape.circle),
                child: Icon(v.icon, color: v.fg, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    if (n.body.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        n.body,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      notificationTimeLabel(n.createdAt, now: now),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),
              if (!n.read)
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 4),
                  child: Container(
                    key: const Key('unread-dot'),
                    width: 11,
                    height: 11,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bell icon for the dashboards; the orange dot shows only while the
/// user has unread notifications.
class NotificationBellButton extends StatefulWidget {
  final String uid;
  final NotificationService? service;
  final VoidCallback onPressed;
  final double iconSize;

  const NotificationBellButton({
    super.key,
    required this.uid,
    required this.onPressed,
    this.service,
    this.iconSize = 26,
  });

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  Stream<List<AppNotification>>? _stream;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(NotificationBellButton old) {
    super.didUpdateWidget(old);
    if (old.uid != widget.uid || old.service != widget.service) _subscribe();
  }

  void _subscribe() {
    _stream = widget.service != null || firebaseReady
        ? (widget.service ?? NotificationService())
            .watchUserNotifications(widget.uid)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final bell = IconButton(
      tooltip: 'Notifications',
      onPressed: widget.onPressed,
      icon: Icon(Icons.notifications_outlined,
          color: AppColors.navy, size: widget.iconSize),
    );
    final stream = _stream;
    if (stream == null) return bell;
    return StreamBuilder<List<AppNotification>>(
      stream: stream,
      builder: (context, snap) {
        final unread = snap.data?.any((n) => !n.read) ?? false;
        return Stack(
          children: [
            bell,
            if (unread)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  key: const Key('bell-dot'),
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

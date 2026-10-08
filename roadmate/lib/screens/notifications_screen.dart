import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/app_notification.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/notification_widgets.dart';
import '../widgets/roadmate_top_bar.dart';
import '../widgets/state_message.dart';

/// The user's inbox (`users/{uid}/notifications`): unread rows are
/// highlighted, tapping a row marks it read, "Mark all read" clears all.
class NotificationsScreen extends StatefulWidget {
  final String uid;
  final NotificationService? service;
  final VoidCallback? onAvatarTap;

  const NotificationsScreen({
    super.key,
    required this.uid,
    this.service,
    this.onAvatarTap,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Stream<List<AppNotification>>? _stream;

  /// An injected service (tests, previews) always counts as connected.
  bool get _connected => widget.service != null || firebaseReady;
  NotificationService get _service => widget.service ?? NotificationService();

  @override
  void initState() {
    super.initState();
    if (_connected) _stream = _service.watchUserNotifications(widget.uid);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _markAllRead() async {
    try {
      await _service.markAllRead(widget.uid);
    } catch (e) {
      if (mounted) _snack(AuthService.friendlyMessage(e));
    }
  }

  Future<void> _open(AppNotification n) async {
    if (n.read) return;
    try {
      await _service.markRead(widget.uid, n.id);
    } catch (e) {
      if (mounted) _snack(AuthService.friendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            RoadMateTopBar(onAvatarTap: widget.onAvatarTap),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final stream = _stream;
    if (stream == null) {
      return _layout(
        unread: null,
        body: const StateMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Firebase not connected',
          message: 'Add your google-services files to see notifications.',
        ),
      );
    }
    return StreamBuilder<List<AppNotification>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return _layout(
            unread: null,
            body: StateMessage(
              icon: Icons.error_outline_rounded,
              color: const Color(0xFFB02A37),
              title: 'Could not load notifications',
              message: AuthService.friendlyMessage(snap.error!),
            ),
          );
        }
        if (!snap.hasData) {
          return _layout(
            unread: null,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return _layout(
            unread: 0,
            body: const StateMessage(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              message:
                  'Updates about your requests and messages will show up here.',
            ),
          );
        }
        final unread = items.where((n) => !n.read).length;
        final now = DateTime.now();
        final today = items.where((n) => isTodayNotification(n, now: now));
        final earlier = items.where((n) => !isTodayNotification(n, now: now));
        Widget tile(AppNotification n) => Column(
              key: ValueKey(n.id),
              children: [
                NotificationTile(
                  notification: n,
                  now: now,
                  onTap: () => _open(n),
                ),
                const Divider(height: 1, color: Color(0xFFE3E8F5)),
              ],
            );
        return _layout(
          unread: unread,
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (today.isNotEmpty) ...[
                const _SectionLabel('TODAY'),
                for (final n in today) tile(n),
              ],
              if (earlier.isNotEmpty) ...[
                const _SectionLabel('EARLIER'),
                for (final n in earlier) tile(n),
              ],
            ],
          ),
        );
      },
    );
  }

  /// [unread] null = unknown (loading / error / not connected).
  Widget _layout({required int? unread, required Widget body}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoadMatePageTitle(
          title: 'Notifications',
          onBack: () => Navigator.pop(context),
          trailing: unread != null && unread > 0
              ? TextButton(
                  onPressed: _markAllRead,
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.orange,
                    ),
                  ),
                )
              : null,
        ),
        if (unread != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Text(
              unread > 0 ? '$unread unread' : 'You are all caught up',
              style: const TextStyle(fontSize: 14.5, color: AppColors.greyText),
            ),
          ),
        Expanded(child: body),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
          color: AppColors.greyText,
        ),
      ),
    );
  }
}

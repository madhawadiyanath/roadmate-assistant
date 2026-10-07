import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/service_request.dart';
import '../services/assistance_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/request_history_widgets.dart';
import '../widgets/roadmate_top_bar.dart';
import '../widgets/state_message.dart';

enum _Filter { all, completed, cancelled }

/// The driver's past and current requests, from
/// [AssistanceService.watchDriverRequests], with All / Completed /
/// Cancelled filters (each showing its count).
class RequestHistoryScreen extends StatefulWidget {
  final String uid;
  final AssistanceService? service;

  /// Called when a card is tapped (e.g. open live tracking). Cards are
  /// not tappable when null. Receives the screen's own context so the
  /// caller can navigate from it.
  final void Function(BuildContext context, ServiceRequest request)? onOpen;
  final VoidCallback? onAvatarTap;

  const RequestHistoryScreen({
    super.key,
    required this.uid,
    this.service,
    this.onOpen,
    this.onAvatarTap,
  });

  @override
  State<RequestHistoryScreen> createState() => _RequestHistoryScreenState();
}

class _RequestHistoryScreenState extends State<RequestHistoryScreen> {
  Stream<List<ServiceRequest>>? _stream;
  _Filter _filter = _Filter.all;

  /// An injected service (tests, previews) always counts as connected.
  bool get _connected => widget.service != null || firebaseReady;

  @override
  void initState() {
    super.initState();
    if (_connected) {
      _stream = (widget.service ?? AssistanceService())
          .watchDriverRequests(widget.uid);
    }
  }

  static bool _matches(_Filter f, ServiceRequest r) {
    switch (f) {
      case _Filter.all:
        return true;
      case _Filter.completed:
        return r.status == RequestStatus.completed;
      case _Filter.cancelled:
        return r.status == RequestStatus.cancelled;
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
            RoadMatePageTitle(
              title: 'Request History',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final stream = _stream;
    if (stream == null) {
      return const StateMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Firebase not connected',
        message: 'Add your google-services files to see your requests.',
      );
    }
    return StreamBuilder<List<ServiceRequest>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return StateMessage(
            icon: Icons.error_outline_rounded,
            color: const Color(0xFFB02A37),
            title: 'Could not load requests',
            message: AuthService.friendlyMessage(snap.error!),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data!;
        if (all.isEmpty) {
          return const StateMessage(
            icon: Icons.assignment_outlined,
            title: 'No requests yet',
            message: 'Your assistance requests will appear here.',
          );
        }
        final shown = all.where((r) => _matches(_filter, r)).toList();
        final now = DateTime.now();
        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: Row(
                children: [
                  for (final f in _Filter.values) ...[
                    RequestFilterTab(
                      label: switch (f) {
                        _Filter.all => 'All',
                        _Filter.completed => 'Completed',
                        _Filter.cancelled => 'Cancelled',
                      },
                      count: all.where((r) => _matches(f, r)).length,
                      selected: _filter == f,
                      onTap: () => setState(() => _filter = f),
                    ),
                    const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? StateMessage(
                      icon: Icons.filter_list_off_rounded,
                      title: _filter == _Filter.completed
                          ? 'No completed requests'
                          : 'No cancelled requests',
                      message: 'Nothing matches this filter yet.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      itemCount: shown.length,
                      itemBuilder: (_, i) => RequestHistoryCard(
                        request: shown[i],
                        now: now,
                        onTap: widget.onOpen == null
                            ? null
                            : () => widget.onOpen!(context, shown[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Entry row shown in the dashboard's Requests tab.
class RequestHistoryLink extends StatelessWidget {
  final VoidCallback onTap;
  const RequestHistoryLink({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.history_rounded, size: 18),
      label: const Text(
        'History',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      style: TextButton.styleFrom(foregroundColor: AppColors.orange),
    );
  }
}

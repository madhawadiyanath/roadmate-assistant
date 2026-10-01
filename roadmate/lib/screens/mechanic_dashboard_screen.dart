import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/app_user.dart';
import '../models/service_request.dart';
import '../services/assistance_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'onboarding_screen.dart';

/// Mechanic home: live feed of pending driver requests to accept,
/// plus assigned jobs to advance (accepted → on the way → completed).
class MechanicDashboardScreen extends StatefulWidget {
  final AppUser user;
  final AuthService? authService;
  final AssistanceService? assistanceService;

  const MechanicDashboardScreen({
    super.key,
    required this.user,
    this.authService,
    this.assistanceService,
  });

  @override
  State<MechanicDashboardScreen> createState() =>
      _MechanicDashboardScreenState();
}

class _MechanicDashboardScreenState extends State<MechanicDashboardScreen> {
  bool _available = true;
  bool _busy = false;

  AssistanceService get _assist =>
      widget.assistanceService ?? AssistanceService();

  String get _firstName {
    final n = widget.user.name.trim();
    return n.isEmpty ? 'Mechanic' : n.split(' ').first;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _accept(ServiceRequest r) async {
    if (!firebaseReady) {
      _snack('Firebase not connected yet. Add google-services files first.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _assist.acceptRequest(
        requestId: r.id,
        mechanicUid: widget.user.uid,
        mechanicName: widget.user.name,
      );
      if (!mounted) return;
      _snack('${r.type.label} accepted — driver notified!');
    } catch (e) {
      _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _advance(ServiceRequest r) async {
    final next = r.status == RequestStatus.accepted
        ? RequestStatus.onTheWay
        : RequestStatus.completed;
    setState(() => _busy = true);
    try {
      await _assist.updateStatus(r.id, next);
      if (!mounted) return;
      _snack(next == RequestStatus.completed
          ? 'Job completed. Nice work!'
          : 'On the way to driver.');
    } catch (e) {
      _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    try {
      await (widget.authService ?? AuthService()).signOut();
    } catch (_) {
      // Leave anyway.
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ROADSIDE CARE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AppColors.orange,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.build_rounded,
                              size: 20, color: AppColors.navy),
                          SizedBox(width: 4),
                          Text(
                            'RoadMate Mechanic',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _logout,
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.navy,
                      child: Text(
                        _firstName.isEmpty
                            ? 'M'
                            : _firstName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'Hello, $_firstName 🔧',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const Text(
                'Accept jobs nearby and help drivers fast.',
                style: TextStyle(fontSize: 13, color: AppColors.greyText),
              ),
              const SizedBox(height: 12),

              // Availability toggle
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _available
                      ? const Color(0xFFE6F7EE)
                      : AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: _available
                          ? const Color(0xFF22B573)
                          : AppColors.greyText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _available
                            ? 'You are Online — new jobs will appear'
                            : 'You are Offline — go online to get jobs',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ),
                    Switch(
                      value: _available,
                      activeThumbColor: const Color(0xFF22B573),
                      onChanged: (v) => setState(() => _available = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'New Requests',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                ),
              ),
              const SizedBox(height: 10),
              if (!firebaseReady)
                Column(
                  children: [
                    _IncomingCard(
                      request: const ServiceRequest(
                        id: 'demo-m1',
                        driverUid: 'd1',
                        driverName: 'Kasun Perera',
                        type: AssistanceType.flatTyre,
                        status: RequestStatus.pending,
                        address: 'No. 25, Galle Road, Colombo 06',
                      ),
                      busy: _busy,
                      onAccept: _accept,
                    ),
                    const SizedBox(height: 10),
                    _IncomingCard(
                      request: const ServiceRequest(
                        id: 'demo-m2',
                        driverUid: 'd2',
                        driverName: 'Amal Silva',
                        type: AssistanceType.towing,
                        status: RequestStatus.pending,
                        address: 'Outer Circular Hwy',
                      ),
                      busy: _busy,
                      onAccept: _accept,
                    ),
                  ],
                )
              else
                StreamBuilder<List<ServiceRequest>>(
                  stream: _assist.watchPendingRequests(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child:
                            Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snap.hasError) {
                      return _ErrorBox(error: snap.error);
                    }
                    final items = (snap.data ?? [])
                        .where((r) => r.driverUid != widget.user.uid)
                        .toList();
                    if (items.isEmpty || !_available) {
                      return _EmptyBox(
                        text: _available
                            ? 'No new requests right now.'
                            : 'Go online to receive requests.',
                      );
                    }
                    return Column(
                      children: [
                        for (final r in items) ...[
                          _IncomingCard(
                            request: r,
                            busy: _busy,
                            onAccept: _accept,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              const SizedBox(height: 18),

              const Text(
                'My Jobs',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                ),
              ),
              const SizedBox(height: 10),
              if (!firebaseReady)
                const _EmptyBox(text: 'Accepted jobs appear here.')
              else
                StreamBuilder<List<ServiceRequest>>(
                  stream:
                      _assist.watchMechanicJobs(widget.user.uid),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child:
                            Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snap.hasError) {
                      return _ErrorBox(error: snap.error);
                    }
                    final items = (snap.data ?? [])
                        .where((r) =>
                            r.status != RequestStatus.completed &&
                            r.status != RequestStatus.cancelled)
                        .toList();
                    if (items.isEmpty) {
                      return const _EmptyBox(
                          text: 'Accepted jobs appear here.');
                    }
                    return Column(
                      children: [
                        for (final r in items) ...[
                          _JobCard(
                            request: r,
                            busy: _busy,
                            onAdvance: _advance,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomingCard extends StatelessWidget {
  final ServiceRequest request;
  final bool busy;
  final ValueChanged<ServiceRequest> onAccept;
  const _IncomingCard({
    required this.request,
    required this.busy,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: AppColors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.type.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyDark,
                      ),
                    ),
                    Text(
                      '${request.driverName} • ${request.refCode}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDE0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.type.eta,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          if (request.address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 15, color: AppColors.greyText),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: busy ? null : () => onAccept(request),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'Accept Job',
                style: TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final ServiceRequest request;
  final bool busy;
  final ValueChanged<ServiceRequest> onAdvance;
  const _JobCard({
    required this.request,
    required this.busy,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final nextLabel = request.status == RequestStatus.accepted
        ? 'Start — On the way'
        : 'Mark Completed';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${request.type.label} • ${request.refCode}',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                  ),
                ),
              ),
              _StatusPill(status: request.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${request.driverName} • ${request.address}',
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.greyText),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: busy ? null : () => onAdvance(request),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22B573),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: Text(
                nextLabel,
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final RequestStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == RequestStatus.completed
        ? const Color(0xFF22B573)
        : status == RequestStatus.pending
            ? AppColors.orange
            : const Color(0xFF2F7DE1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final Object? error;
  const _ErrorBox({this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5C2C7), width: 1.2),
      ),
      child: Text(
        'Could not load jobs.\n$error',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFB02A37), fontSize: 12.5),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.greyText, fontSize: 13),
      ),
    );
  }
}

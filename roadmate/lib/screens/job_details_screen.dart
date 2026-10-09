import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/service_request.dart';
import '../services/assistance_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mini_map_illustration.dart';
import 'chat_screen.dart';

/// Full details of one incoming job. Opened by tapping a job card.
/// Pops `true` after accept/reject (lists refresh via streams),
/// or a dashboard tab index from the bottom nav.
class JobDetailsScreen extends StatefulWidget {
  final ServiceRequest request;
  final String mechanicUid;
  final String mechanicName;
  final AssistanceService? assistanceService;

  const JobDetailsScreen({
    super.key,
    required this.request,
    required this.mechanicUid,
    required this.mechanicName,
    this.assistanceService,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _accepting = false;
  bool _rejecting = false;

  AssistanceService get _assist =>
      widget.assistanceService ?? AssistanceService();

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _accept() async {
    if (!firebaseReady) {
      _snack('Firebase not connected yet. Add google-services files first.');
      return;
    }
    setState(() => _accepting = true);
    try {
      await _assist.acceptRequest(
        requestId: widget.request.id,
        driverUid: widget.request.driverUid,
        mechanicUid: widget.mechanicUid,
        mechanicName: widget.mechanicName,
      );
      if (!mounted) return;
      _snack('${widget.request.type.label} accepted — driver notified!');
      Navigator.pop(context, true);
    } catch (e) {
      _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  Future<void> _reject() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject request?'),
        content: const Text(
            'This job will be removed from your feed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    if (!firebaseReady) {
      _snack('Firebase not connected yet. Add google-services files first.');
      return;
    }
    setState(() => _rejecting = true);
    try {
      await _assist.updateStatus(
          widget.request.id, RequestStatus.cancelled);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _rejecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_rounded,
                          size: 22, color: AppColors.navy),
                      SizedBox(width: 6),
                      Text(
                        'RoadMate',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.navy,
                    child: Icon(Icons.person_rounded,
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.navyDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Request Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Service card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.navy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.tire_repair_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r.type.label} Assistance',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navyDark,
                            ),
                          ),
                          Text(
                            'Request ID ${r.refCode}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.greyText,
                            ),
                          ),
                          Text(
                            timeAgo(r.createdAt),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Customer Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              const SizedBox(height: 8),

              // Customer card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.fieldFill,
                          child: Text(
                            r.driverName.trim().isEmpty
                                ? 'D'
                                : r.driverName.trim()[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.driverName.isEmpty
                                    ? 'Driver'
                                    : r.driverName,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              const Text(
                                'Customer',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.greyText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                request: r,
                                senderUid: widget.mechanicUid,
                                senderName: widget.mechanicName,
                                senderRole: 'mechanic',
                                peerName: r.driverName,
                              ),
                            ),
                          ),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: AppColors.fieldFill,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppColors.navy,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              _snack('Calling ${r.driverName}…'),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: AppColors.fieldFill,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.phone_outlined,
                              color: AppColors.navy,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFEDF1F7)),
                    Row(
                      children: [
                        const Icon(Icons.directions_car_outlined,
                            size: 20, color: AppColors.greyText),
                        const SizedBox(width: 10),
                        Text(
                          '${r.vehicle.isEmpty ? 'Toyota Axio' : r.vehicle} (${r.plate.isEmpty ? 'ABC 1234' : r.plate})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 20, color: AppColors.greyText),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            r.address.isEmpty
                                ? 'Location not shared'
                                : r.address,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.navyDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Map card
              Container(
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFE3E8F0), width: 1.2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      const Positioned.fill(
                          child: MiniMapIllustration()),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: GestureDetector(
                          onTap: () => _snack('Opening in Maps…'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.map_outlined,
                                    size: 16, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Open in Maps',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Distance + fee
              Row(
                children: [
                  Expanded(
                    child: _InfoBox(
                      label: 'Estimated Distance',
                      value: '2.5 km (8 mins)',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoBox(
                      label: 'Estimated Service Fee',
                      value: _feeFor(r.type),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Reject / Accept
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: _rejecting ? null : _reject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(
                              color: Color(0xFFF5C2C7), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _rejecting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5),
                              )
                            : const Text(
                                'Reject',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _accepting ? null : _accept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _accepting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Accept',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (i) => Navigator.pop(context, i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.greyText,
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_rounded),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}

String _feeFor(AssistanceType t) => switch (t) {
      AssistanceType.flatTyre => 'Rs. 3,500',
      AssistanceType.jumpStart => 'Rs. 2,500',
      AssistanceType.fuelDrop => 'Rs. 4,000',
      AssistanceType.towing => 'Rs. 8,500',
      AssistanceType.general => 'Rs. 3,000',
    };

String timeAgo(DateTime? d) {
  if (d == null) return 'Just now';
  final m = DateTime.now().difference(d).inMinutes;
  if (m < 1) return 'Just now';
  if (m < 60) return '$m minute${m == 1 ? '' : 's'} ago';
  final h = m ~/ 60;
  if (h < 24) return '$h hour${h == 1 ? '' : 's'} ago';
  return '${h ~/ 24} day${h ~/ 24 == 1 ? '' : 's'} ago';
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.greyText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDark,
            ),
          ),
        ],
      ),
    );
  }
}

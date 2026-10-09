import 'dart:async';

import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/service_request.dart';
import 'chat_screen.dart';
import '../services/assistance_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';

/// Live tracking for an accepted / on-the-way request.
/// Streams the Firestore doc so mechanic progress updates live.
class TrackRequestScreen extends StatefulWidget {
  final ServiceRequest request;
  final AssistanceService? assistanceService;
  final ChatService? chatService;

  const TrackRequestScreen({
    super.key,
    required this.request,
    this.assistanceService,
    this.chatService,
  });

  @override
  State<TrackRequestScreen> createState() => _TrackRequestScreenState();
}

class _TrackRequestScreenState extends State<TrackRequestScreen> {
  Timer? _ticker;
  int _updatedSecs = 10;

  AssistanceService get _assist =>
      widget.assistanceService ?? AssistanceService();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() => _updatedSecs += 10);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _cancel() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel request?'),
        content: const Text('The patrol will be told to stand down.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    if (!firebaseReady) {
      _snack('Firebase not connected yet. Add google-services files first.');
      return;
    }
    try {
      await _assist.cancelRequest(widget.request.id);
      if (!mounted) return;
      Navigator.pop(context, 'cancelled');
    } catch (e) {
      _snack(AuthService.friendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return _Body(
        request: widget.request,
        updatedSecs: _updatedSecs,
        onCancel: _cancel,
        onHelp: () => _snack('Calling 1-800-ROADMATE…'),
        chatService: widget.chatService,
      );
    }
    return StreamBuilder<ServiceRequest?>(
      stream: _assist.watchRequest(widget.request.id),
      initialData: widget.request,
      builder: (context, snap) {
        final r = snap.data ?? widget.request;
        if (r.status == RequestStatus.cancelled ||
            r.status == RequestStatus.completed) {
          // Job ended elsewhere — go back to the list.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.pop(context, true);
          });
        }
        return _Body(
          request: r,
          updatedSecs: _updatedSecs,
          onCancel: _cancel,
          onHelp: () => _snack('Calling 1-800-ROADMATE…'),
          chatService: widget.chatService,
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final ServiceRequest request;
  final int updatedSecs;
  final VoidCallback onCancel;
  final VoidCallback onHelp;
  final ChatService? chatService;
  const _Body({
    required this.request,
    required this.updatedSecs,
    required this.onCancel,
    required this.onHelp,
    this.chatService,
  });

  String get _mechName =>
      request.mechanicName.trim().isEmpty ? 'Sampath Perera' : request.mechanicName.trim();
  String get _mechFirst => _mechName.split(' ').first;
  String get _etaMins =>
      request.status == RequestStatus.onTheWay ? '3' : '8';

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
              const SizedBox(height: 12),

              // Map card
              Container(
                height: 300,
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
                          child: TrackingMapIllustration()),
                      // Mechanic bubble
                      Positioned(
                        top: 26,
                        left: 0,
                        right: 60,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle,
                                    size: 8,
                                    color: Color(0xFF22B573)),
                                const SizedBox(width: 6),
                                Text(
                                  '$_mechFirst (Patrol #04)',
                                  style: const TextStyle(
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
                      // Right buttons
                      Positioned(
                        right: 10,
                        top: 60,
                        child: Column(
                          children: [
                            _MapBtn(icon: Icons.navigation_rounded),
                            const SizedBox(height: 8),
                            _MapBtn(icon: Icons.my_location_rounded),
                            const SizedBox(height: 8),
                            _MapBtn(icon: Icons.layers_outlined),
                          ],
                        ),
                      ),
                      // Distance + speed pills
                      Positioned(
                        left: 10,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Column(
                            children: [
                              Text(
                                '2.4 km',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              Text(
                                'away',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.greyText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Column(
                            children: [
                              Text(
                                'Speed 38',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              Text(
                                'km/h',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.greyText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Mechanic card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          AppColors.navy.withValues(alpha: 0.1),
                      child: Text(
                        _mechName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _mechName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navyDark,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.fieldFill,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'PATROL #04',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 15, color: AppColors.orange),
                              SizedBox(width: 4),
                              Text(
                                '4.8  (240+ jobs)',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.greyText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            request: request,
                            senderUid: request.driverUid,
                            senderName: request.driverName,
                            senderRole: 'driver',
                            peerName: request.mechanicName,
                            chatService: chatService,
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
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppColors.navy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ETA card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.watch_later_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'ESTIMATED ARRIVAL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: AppColors.greyText,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.circle,
                                  size: 6,
                                  color: Color(0xFF22B573)),
                            ],
                          ),
                          Text(
                            'Arriving in $_etaMins minutes',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7EE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'On Schedule',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF22B573),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Updated ${updatedSecs}s ago',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.greyText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Vehicle row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        color: AppColors.navy,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assistance Vehicle',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.greyText,
                            ),
                          ),
                          Text(
                            'Service Vehicle: Toyota Hilux',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'WP CA 5678',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onCancel,
                    child: const Text(
                      'Cancel Request',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  Text(
                    'Request  ${request.refCode}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.greyText,
                    ),
                  ),
                  GestureDetector(
                    onTap: onHelp,
                    child: const Row(
                      children: [
                        Icon(Icons.help_outline_rounded,
                            size: 16, color: AppColors.greyText),
                        SizedBox(width: 4),
                        Text(
                          'Help',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
            icon: Icon(Icons.receipt_long_rounded),
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
      ),
    );
  }
}

class _MapBtn extends StatelessWidget {
  final IconData icon;
  const _MapBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 19, color: AppColors.navyDark),
    );
  }
}

/// Stylised tracking map: streets, patrol route, destination pin.
class TrackingMapIllustration extends StatelessWidget {
  const TrackingMapIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrackingMapPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _TrackingMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base + blocks
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFE7EEE6),
    );
    final block = Paint()..color = const Color(0xFFF2F5F0);
    for (final r in [
      Rect.fromLTWH(w * 0.04, h * 0.04, w * 0.38, h * 0.30),
      Rect.fromLTWH(w * 0.56, h * 0.05, w * 0.40, h * 0.26),
      Rect.fromLTWH(w * 0.58, h * 0.42, w * 0.38, h * 0.30),
      Rect.fromLTWH(w * 0.05, h * 0.62, w * 0.30, h * 0.33),
      Rect.fromLTWH(w * 0.60, h * 0.76, w * 0.36, h * 0.19),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(10)),
        block,
      );
    }

    // Highway (orange)
    final hwy = Paint()
      ..color = const Color(0xFFF5A623)
      ..strokeWidth = h * 0.045
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(-w * 0.05, h * 0.18)
        ..quadraticBezierTo(w * 0.5, h * 0.12, w * 1.05, h * 0.20),
      hwy,
    );

    // Streets (white)
    final street = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.24, 0), Offset(w * 0.20, h),
        street..strokeWidth = h * 0.035);
    canvas.drawLine(Offset(0, h * 0.48), Offset(w, h * 0.44),
        street..strokeWidth = h * 0.028);
    canvas.drawLine(Offset(w * 0.70, h * 0.30), Offset(w * 0.66, h),
        street..strokeWidth = h * 0.028);

    // Labels
    void label(String t, double x, double y, double rot) {
      final tp = TextPainter(
        text: TextSpan(
          text: t,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: const Color(0xFF8A8F7A).withValues(alpha: 0.9),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(w * x, h * y);
      canvas.rotate(rot);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    label('GALLE ROAD', 0.17, 0.62, 1.62);
    label('HIGH STREET', 0.40, 0.465, -0.02);

    // Route: patrol (top-centre) → driver (bottom-centre)
    final route = Path()
      ..moveTo(w * 0.52, h * 0.24)
      ..quadraticBezierTo(w * 0.60, h * 0.40, w * 0.44, h * 0.52)
      ..quadraticBezierTo(w * 0.34, h * 0.62, w * 0.44, h * 0.76);
    canvas.drawPath(
      route,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 9
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFF2F7DE1)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Destination pin
    final dest = Offset(w * 0.44, h * 0.78);
    canvas.drawCircle(
        dest, w * 0.07, Paint()..color = Colors.red.withValues(alpha: 0.15));
    final pin = Paint()..color = const Color(0xFFE53935);
    canvas.drawCircle(Offset(dest.dx, dest.dy - h * 0.035), w * 0.038, pin);
    final tip = Path()
      ..moveTo(dest.dx - w * 0.032, dest.dy - h * 0.022)
      ..lineTo(dest.dx, dest.dy + h * 0.015)
      ..lineTo(dest.dx + w * 0.032, dest.dy - h * 0.022)
      ..close();
    canvas.drawPath(tip, pin);
    canvas.drawCircle(Offset(dest.dx, dest.dy - h * 0.035), w * 0.015,
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

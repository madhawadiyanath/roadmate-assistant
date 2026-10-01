import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/app_user.dart';
import '../models/service_request.dart';
import '../services/assistance_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/confirm_request_sheet.dart';
import '../widgets/mini_map_illustration.dart';

/// Step 2 of the driver flow: confirm pickup location for [serviceType].
/// Pops `true` when the request was created, or a tab index from bottom nav.
class LocationScreen extends StatefulWidget {
  final AppUser user;
  final AssistanceType serviceType;
  final AssistanceService? assistanceService;

  const LocationScreen({
    super.key,
    required this.user,
    required this.serviceType,
    this.assistanceService,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _search = TextEditingController(text: '452 Galle Road, Colombo 03');
  bool _locked = true;
  bool _locating = false;
  bool _creating = false;

  AssistanceService get _assist =>
      widget.assistanceService ?? AssistanceService();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Simulated high-precision GPS lock.
  /// TODO: swap with geolocator + reverse-geocode for live coordinates.
  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _locating = false;
      _locked = true;
      _search.text = 'Highland Expressway, Mile Post 42';
    });
    _snack('GPS locked • High precision (±3m)');
  }

  Future<void> _next() async {
    final address = _search.text.trim();
    if (address.isEmpty) {
      _snack('Please enter or pick your location.');
      return;
    }
    if (!firebaseReady) {
      _snack('Firebase not connected yet. Add google-services files first.');
      return;
    }
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ConfirmRequestSheet(
        type: widget.serviceType,
        address: address,
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _creating = true);
    try {
      await _assist.createRequest(
        driverUid: widget.user.uid,
        driverName: widget.user.name,
        type: widget.serviceType,
        address: address,
      );
      if (!mounted) return;
      _snack('${widget.serviceType.label} requested — help is on the way!');
      Navigator.pop(context, true);
    } catch (e) {
      _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
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
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.navyDark,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF2F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle,
                            size: 8, color: AppColors.orange),
                        SizedBox(width: 6),
                        Text(
                          '24/7 ROADSIDE ASSISTANCE',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        _snack('Calling 1-800-ROADMATE…'),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE3C2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_outlined,
                        color: AppColors.orange,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              const Text(
                'Your Location',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'Confirm your current location',
                style: TextStyle(fontSize: 13.5, color: AppColors.greyText),
              ),
              const SizedBox(height: 14),

              // Map card
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFE3E8F0), width: 1.2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      const Positioned.fill(child: MiniMapIllustration()),
                      // Zoom buttons
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Column(
                          children: [
                            _ZoomBtn(
                                icon: Icons.add,
                                onTap: () =>
                                    _snack('Zoom in — map preview')),
                            const SizedBox(height: 6),
                            _ZoomBtn(
                                icon: Icons.remove,
                                onTap: () =>
                                    _snack('Zoom out — map preview')),
                          ],
                        ),
                      ),
                      // GPS info overlay
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE6F7EE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.my_location_rounded,
                                  color: Color(0xFF22B573),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _search.text.isEmpty
                                          ? 'Pick your location'
                                          : _search.text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.navyDark,
                                      ),
                                    ),
                                    Text(
                                      _locked
                                          ? 'GPS Locked • High Precision (±3m)'
                                          : 'GPS searching…',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: _locked
                                            ? const Color(0xFF22B573)
                                            : AppColors.greyText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_locked)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEDE0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Live',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.orange,
                                    ),
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

              // Use current location
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _locating ? null : _useCurrentLocation,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side:
                        const BorderSide(color: AppColors.navy, width: 1.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _locating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.my_location_rounded,
                                size: 20, color: AppColors.orange),
                            SizedBox(width: 8),
                            Text(
                              'Use Current Location',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Search field
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                    fontSize: 14, color: AppColors.navyDark),
                decoration: InputDecoration(
                  hintText: 'Search address…',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.greyText, size: 20),
                  suffixIcon: _search.text.isEmpty
                      ? const Icon(Icons.my_location_outlined,
                          color: AppColors.greyText, size: 20)
                      : IconButton(
                          onPressed: () =>
                              setState(() => _search.clear()),
                          icon: const Icon(Icons.cancel_rounded,
                              color: AppColors.greyText, size: 20),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFE3E8F0), width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFE3E8F0), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.navy, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Recents
              Row(
                children: [
                  const Text(
                    'RECENT:',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.greyText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RecentChip(
                    label: 'Outer Circular Hwy',
                    onTap: () => setState(
                        () => _search.text = 'Outer Circular Hwy'),
                  ),
                  const SizedBox(width: 8),
                  _RecentChip(
                    label: 'Kandy Rd, Kelaniya',
                    onTap: () => setState(
                        () => _search.text = 'Kandy Rd, Kelaniya'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const EmergencyBanner(),
              const SizedBox(height: 12),

              // Next
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _creating ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _creating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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
            activeIcon: Icon(Icons.home_rounded),
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
      ),
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.navyDark),
      ),
    );
  }
}

class _RecentChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _RecentChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3E8F0), width: 1),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.navyDark,
          ),
        ),
      ),
    );
  }
}

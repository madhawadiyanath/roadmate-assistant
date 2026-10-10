import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/garage_profile.dart';
import '../services/auth_service.dart';
import '../services/garage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mini_map_illustration.dart';
import '../widgets/roadmate_top_bar.dart';
import '../widgets/state_message.dart';
import 'garage_profile_form_screen.dart';

/// Screen displaying the Mechanic's Garage Profile and Workshop Location details.
class GarageProfileScreen extends StatefulWidget {
  final String uid;
  final GarageService? service;
  final VoidCallback? onAvatarTap;

  const GarageProfileScreen({
    super.key,
    required this.uid,
    this.service,
    this.onAvatarTap,
  });

  @override
  State<GarageProfileScreen> createState() => _GarageProfileScreenState();
}

class _GarageProfileScreenState extends State<GarageProfileScreen> {
  Stream<GarageProfile?>? _stream;
  bool get _connected => widget.service != null || firebaseReady;

  GarageService get _service => widget.service ?? GarageService();

  // Demo fallback profile for offline/preview mode
  static const _demoProfile = GarageProfile(
    ownerUid: 'demo_owner',
    garageName: 'RoadMate Auto Care & Recovery',
    registrationNumber: 'BR-2024-8841',
    hotline: '+94 77 123 4567',
    address: 'No. 120, High Level Road, Nugegoda',
    latitude: 6.8722,
    longitude: 79.8893,
    operatingHours: '08:00 AM - 08:00 PM',
    is24Hours: false,
    isOpen: true,
    facilities: [
      'Hydraulic Lift',
      'Flatbed Tow Truck',
      'OBD2 Diagnostic Scanner',
      'Battery Booster & Charger',
      'Wheel Alignment',
    ],
    imageUrls: [
      'https://images.unsplash.com/photo-1613214149922-f1809c99b414?w=600&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=600&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=600&auto=format&fit=crop',
    ],
  );

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _stream = _connected ? _service.watchGarageProfile(widget.uid) : null;
  }

  void _openEdit(GarageProfile? current) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GarageProfileFormScreen(
          uid: widget.uid,
          initialProfile: current,
          garageService: widget.service,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleStatus(GarageProfile profile) async {
    if (!_connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect Firebase to sync live state.')),
      );
      return;
    }
    try {
      await _service.toggleOpenStatus(widget.uid, !profile.isOpen);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.friendlyMessage(e))),
      );
    }
  }

  void _openPhotoDialog(
      BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Photo ${initialIndex + 1} of ${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                images[initialIndex],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: AppColors.fieldFill,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded,
                        color: AppColors.greyText, size: 40),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              title: 'Garage Profile',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: _stream == null
                  ? _buildContent(_demoProfile, isDemo: true)
                  : StreamBuilder<GarageProfile?>(
                      stream: _stream,
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return StateMessage(
                            icon: Icons.error_outline_rounded,
                            color: const Color(0xFFB02A37),
                            title: 'Could not load garage profile',
                            message: AuthService.friendlyMessage(snap.error!),
                          );
                        }
                        if (!snap.hasData &&
                            snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final profile = snap.data;
                        if (profile == null) {
                          return _buildEmpty();
                        }
                        return _buildContent(profile, isDemo: false);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.garage_rounded,
                  size: 38, color: AppColors.orange),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Garage Profile Setup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your workshop name, physical address, emergency hotline, and operating hours so drivers can find you.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.greyText),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openEdit(null),
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Setup Garage Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(GarageProfile profile, {required bool isDemo}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Garage Header Card (Clean, Modern, Arranged without blue container)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.fieldFill, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Garage Icon Badge
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.orange,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.garageName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (profile.registrationNumber.isNotEmpty)
                            Text(
                              'Reg: ${profile.registrationNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.greyText,
                              ),
                            )
                          else
                            const Text(
                              'Registered Workshop',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.greyText,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Edit Profile Button
                    IconButton(
                      onPressed: () => _openEdit(profile),
                      tooltip: 'Edit Garage Details',
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.fieldFill,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.navy,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.fieldFill),
                const SizedBox(height: 10),
                // Status Pill & Operating Summary Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: profile.isOpen
                            ? const Color(0xFF22B573).withOpacity(0.12)
                            : Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: profile.isOpen
                              ? const Color(0xFF22B573).withOpacity(0.3)
                              : Colors.redAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            profile.isOpen
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            size: 13,
                            color: profile.isOpen
                                ? const Color(0xFF1B8A57)
                                : Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            profile.isOpen ? 'OPEN NOW' : 'CLOSED',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: profile.isOpen
                                  ? const Color(0xFF1B8A57)
                                  : Colors.redAccent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      profile.is24Hours
                          ? 'Open 24/7'
                          : profile.operatingHours,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Compact & Sleek Workshop Gallery Preview
          if (profile.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Workshop Gallery',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  '${profile.imageUrls.length} Photos • Tap to view',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greyText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: profile.imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final img = profile.imageUrls[i];
                  return GestureDetector(
                    onTap: () =>
                        _openPhotoDialog(context, profile.imageUrls, i),
                    child: Container(
                      width: 110,
                      height: 92,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.navy.withOpacity(0.12),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              img,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.fieldFill,
                                child: const Center(
                                  child: Icon(Icons.broken_image_rounded,
                                      color: AppColors.greyText, size: 24),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.65),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${i + 1}/${profile.imageUrls.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Quick Toggle Switch Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        profile.isOpen
                            ? Icons.storefront_rounded
                            : Icons.lock_clock_rounded,
                        color: profile.isOpen
                            ? const Color(0xFF22B573)
                            : AppColors.greyText,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Workshop Availability',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                            Text(
                              profile.isOpen
                                  ? 'Accepting service requests'
                                  : 'Temporarily closed',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.greyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: profile.isOpen,
                  activeColor: const Color(0xFF22B573),
                  onChanged: (_) => _toggleStatus(profile),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Contact Hotline
          _DetailCard(
            icon: Icons.phone_in_talk_rounded,
            title: 'Emergency Hotline',
            subtitle: profile.hotline.isNotEmpty
                ? profile.hotline
                : 'No hotline specified',
          ),
          const SizedBox(height: 12),

          // Operating Hours
          _DetailCard(
            icon: Icons.access_time_rounded,
            title: 'Working Hours',
            subtitle: profile.is24Hours
                ? 'Open 24 Hours / 7 Days'
                : profile.operatingHours,
          ),
          const SizedBox(height: 12),

          // Location & Mini Map Illustration
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.fieldFill, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: AppColors.orange, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Workshop Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  profile.address.isNotEmpty
                      ? profile.address
                      : 'Address not configured',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (profile.hasLocation) ...[
                  const SizedBox(height: 4),
                  Text(
                    'GPS: ${profile.locationCoordText}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Mini Map Preview Illustration
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: MiniMapIllustration(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Facilities & Equipment
          if (profile.facilities.isNotEmpty) ...[
            const Text(
              'Equipment & Facilities',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.facilities.map((fac) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.navy.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 15, color: Color(0xFF22B573)),
                      const SizedBox(width: 6),
                      Text(
                        fac,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DetailCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldFill, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.orange, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greyText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

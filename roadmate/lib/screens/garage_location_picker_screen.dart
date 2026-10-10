import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';
import '../widgets/roadmate_top_bar.dart';

class LocationPickResult {
  final double latitude;
  final double longitude;
  final String address;

  const LocationPickResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

/// Popular Sri Lanka hubs for quick jumping
class _SriLankaHub {
  final String name;
  final double lat;
  final double lng;
  const _SriLankaHub(this.name, this.lat, this.lng);
}

const _popularHubs = <_SriLankaHub>[
  _SriLankaHub('Colombo', 6.9271, 79.8612),
  _SriLankaHub('Nugegoda', 6.8722, 79.8893),
  _SriLankaHub('Kandy', 7.2906, 80.6337),
  _SriLankaHub('Gampaha', 7.0840, 79.9939),
  _SriLankaHub('Galle', 6.0535, 80.2210),
  _SriLankaHub('Negombo', 7.2083, 79.8358),
  _SriLankaHub('Dehiwala', 6.8510, 79.8659),
  _SriLankaHub('Moratuwa', 6.7730, 79.8816),
  _SriLankaHub('Kurunegala', 7.4863, 80.3623),
];

class GarageLocationPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String initialAddress;

  const GarageLocationPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.initialAddress,
  });

  @override
  State<GarageLocationPickerScreen> createState() =>
      _GarageLocationPickerScreenState();
}

class _GarageLocationPickerScreenState
    extends State<GarageLocationPickerScreen> {
  late final MapController _mapController;
  late double _selectedLat;
  late double _selectedLng;
  late final TextEditingController _addressController;
  double _currentZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLat = widget.initialLat;
    _selectedLng = widget.initialLng;
    _addressController = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _selectedLat = point.latitude;
      _selectedLng = point.longitude;
    });
  }

  void _jumpTo(double lat, double lng, [String? name]) {
    setState(() {
      _selectedLat = lat;
      _selectedLng = lng;
      if (name != null && _addressController.text.trim().isEmpty) {
        _addressController.text = '$name, Sri Lanka';
      }
    });
    _mapController.move(LatLng(lat, lng), 15.0);
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(3.0, 19.0);
    });
    _mapController.move(LatLng(_selectedLat, _selectedLng), _currentZoom);
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(3.0, 19.0);
    });
    _mapController.move(LatLng(_selectedLat, _selectedLng), _currentZoom);
  }

  void _confirm() {
    Navigator.pop(
      context,
      LocationPickResult(
        latitude: _selectedLat,
        longitude: _selectedLng,
        address: _addressController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPoint = LatLng(
      _selectedLat.clamp(-90.0, 90.0),
      _selectedLng.clamp(-180.0, 180.0),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const RoadMateTopBar(),
            RoadMatePageTitle(
              title: 'Select Workshop Location',
              onBack: () => Navigator.pop(context),
            ),

            // Quick City Bar
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _popularHubs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final hub = _popularHubs[idx];
                  return ActionChip(
                    label: Text(hub.name),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    onPressed: () => _jumpTo(hub.lat, hub.lng, hub.name),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),

            // Real Map Area
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: currentPoint,
                      initialZoom: _currentZoom,
                      onTap: (_, point) => _onMapTap(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.roadmate.assistant',
                        maxZoom: 19,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: currentPoint,
                            width: 60,
                            height: 60,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.orange,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Map Controls (Zoom + Recenter)
                  Positioned(
                    right: 16,
                    bottom: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'zoom_in_btn',
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.navy,
                          onPressed: _zoomIn,
                          child: const Icon(Icons.add_rounded),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'zoom_out_btn',
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.navy,
                          onPressed: _zoomOut,
                          child: const Icon(Icons.remove_rounded),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'recenter_btn',
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          onPressed: () => _jumpTo(_selectedLat, _selectedLng),
                          child: const Icon(Icons.my_location_rounded),
                        ),
                      ],
                    ),
                  ),

                  // Hint Banner
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.touch_app_rounded,
                              size: 18, color: AppColors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap anywhere on the map to pin your workshop location',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
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

            // Bottom Confirmation Panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pin_drop_rounded,
                          color: AppColors.orange, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'GPS: ${_selectedLat.toStringAsFixed(4)}, ${_selectedLng.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      hintText: 'Enter or confirm workshop address',
                      prefixIcon: const Icon(Icons.business_rounded,
                          size: 20, color: AppColors.navy),
                      filled: true,
                      fillColor: AppColors.fieldFill,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Confirm Workshop Location',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

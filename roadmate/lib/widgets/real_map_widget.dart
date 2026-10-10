import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';

/// Reusable Real Map widget using OpenStreetMap tiles.
/// Includes interactive controls (+ and - zoom icons), pin marker, and gestures.
class RealMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double initialZoom;
  final bool isInteractive;
  final ValueChanged<LatLng>? onTap;
  final String? markerLabel;
  final MapController? mapController;
  final bool showZoomControls;

  const RealMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.initialZoom = 15.0,
    this.isInteractive = true,
    this.onTap,
    this.markerLabel,
    this.mapController,
    this.showZoomControls = true,
  });

  @override
  State<RealMapWidget> createState() => _RealMapWidgetState();
}

class _RealMapWidgetState extends State<RealMapWidget> {
  late final MapController _internalController;
  late double _currentZoom;

  MapController get _controller => widget.mapController ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = MapController();
    _currentZoom = widget.initialZoom;
  }

  @override
  void didUpdateWidget(covariant RealMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _controller.move(
        LatLng(
          widget.latitude.clamp(-90.0, 90.0),
          widget.longitude.clamp(-180.0, 180.0),
        ),
        _currentZoom,
      );
    }
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(3.0, 19.0);
    });
    _controller.move(
      LatLng(
        widget.latitude.clamp(-90.0, 90.0),
        widget.longitude.clamp(-180.0, 180.0),
      ),
      _currentZoom,
    );
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(3.0, 19.0);
    });
    _controller.move(
      LatLng(
        widget.latitude.clamp(-90.0, 90.0),
        widget.longitude.clamp(-180.0, 180.0),
      ),
      _currentZoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(
      widget.latitude.clamp(-90.0, 90.0),
      widget.longitude.clamp(-180.0, 180.0),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: center,
              initialZoom: _currentZoom,
              interactionOptions: InteractionOptions(
                flags: widget.isInteractive
                    ? InteractiveFlag.all
                    : InteractiveFlag.none,
              ),
              onTap: widget.onTap != null
                  ? (_, point) => widget.onTap!(point)
                  : null,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.roadmate.assistant',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 60,
                    height: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Zoom + and - Controls
          if (widget.showZoomControls && widget.isInteractive)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _zoomIn,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.add_rounded,
                          size: 22,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    Container(
                      width: 26,
                      height: 1,
                      color: const Color(0xFFE2E8F0),
                    ),
                    InkWell(
                      onTap: _zoomOut,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(10),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 22,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // OpenStreetMap Attribution
          Positioned(
            left: 8,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '© OpenStreetMap',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

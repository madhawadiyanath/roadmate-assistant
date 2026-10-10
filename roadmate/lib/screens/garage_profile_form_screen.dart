import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/garage_profile.dart';
import '../services/auth_service.dart';
import '../services/garage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/roadmate_top_bar.dart';

const _availableFacilities = [
  'Hydraulic Lift',
  'Flatbed Tow Truck',
  'Wheel Alignment',
  'OBD2 Diagnostic Scanner',
  'Battery Booster & Charger',
  'AC Gas Refill Station',
  'Tire Changer & Balancer',
  '24/7 Mobile Recovery Unit',
];

/// Form to setup or edit Garage / Workshop details.
class GarageProfileFormScreen extends StatefulWidget {
  final String uid;
  final GarageProfile? initialProfile;
  final GarageService? garageService;

  const GarageProfileFormScreen({
    super.key,
    required this.uid,
    this.initialProfile,
    this.garageService,
  });

  @override
  State<GarageProfileFormScreen> createState() =>
      _GarageProfileFormScreenState();
}

class _GarageProfileFormScreenState extends State<GarageProfileFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _regNo;
  late final TextEditingController _hotline;
  late final TextEditingController _address;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _hours;
  late final TextEditingController _imageUrlController;

  late bool _is24Hours;
  late bool _isOpen;
  late List<String> _facilities;
  late List<String> _imageUrls;

  String? _nameError, _hotlineError, _addressError;
  bool _saving = false;

  GarageService get _service => widget.garageService ?? GarageService();

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _name = TextEditingController(text: p?.garageName ?? '');
    _regNo = TextEditingController(text: p?.registrationNumber ?? '');
    _hotline = TextEditingController(text: p?.hotline ?? '');
    _address = TextEditingController(text: p?.address ?? '');
    _lat = TextEditingController(
        text: p?.latitude != null ? '${p!.latitude}' : '6.9271');
    _lng = TextEditingController(
        text: p?.longitude != null ? '${p!.longitude}' : '79.8612');
    _hours = TextEditingController(
        text: p?.operatingHours ?? '08:00 AM - 07:00 PM');
    _imageUrlController = TextEditingController();
    _is24Hours = p?.is24Hours ?? false;
    _isOpen = p?.isOpen ?? true;
    _facilities = List<String>.from(p?.facilities ?? ['Battery Booster & Charger', 'OBD2 Diagnostic Scanner']);
    _imageUrls = List<String>.from(p?.imageUrls ?? []);
  }

  @override
  void dispose() {
    _name.dispose();
    _regNo.dispose();
    _hotline.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    _hours.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _validate() {
    setState(() {
      _nameError =
          _name.text.trim().isEmpty ? 'Enter your garage or workshop name' : null;
      _hotlineError =
          _hotline.text.trim().isEmpty ? 'Enter an emergency hotline' : null;
      _addressError =
          _address.text.trim().isEmpty ? 'Enter the workshop address' : null;
    });
    return _nameError == null &&
        _hotlineError == null &&
        _addressError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    if (!firebaseReady && widget.garageService == null) {
      _snack('Firebase not connected yet. Add google-services files first.');
      return;
    }

    setState(() => _saving = true);
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());

    final profile = GarageProfile(
      ownerUid: widget.uid,
      garageName: _name.text.trim(),
      registrationNumber: _regNo.text.trim(),
      hotline: _hotline.text.trim(),
      address: _address.text.trim(),
      latitude: lat,
      longitude: lng,
      operatingHours: _is24Hours ? 'Open 24 Hours' : _hours.text.trim(),
      is24Hours: _is24Hours,
      isOpen: _isOpen,
      facilities: _facilities,
      imageUrls: _imageUrls,
    );

    try {
      await _service.saveGarageProfile(widget.uid, profile);
      if (!mounted) return;
      _snack('Garage profile updated successfully');
      Navigator.pop(context, profile);
    } catch (e) {
      if (!mounted) return;
      _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const RoadMateTopBar(),
            RoadMatePageTitle(
              title: widget.initialProfile != null
                  ? 'Edit Garage Details'
                  : 'Setup Garage Profile',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Garage Name
                    const Text(
                      'Garage / Workshop Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'e.g. Apex Auto Care & Recovery',
                        prefixIcon: const Icon(Icons.garage_rounded,
                            color: AppColors.navy),
                        errorText: _nameError,
                        filled: true,
                        fillColor: AppColors.fieldFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Registration Number & Hotline Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reg. Number (BR)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _regNo,
                                decoration: InputDecoration(
                                  hintText: 'BR-2024-001',
                                  filled: true,
                                  fillColor: AppColors.fieldFill,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Emergency Hotline',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _hotline,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: '077 123 4567',
                                  errorText: _hotlineError,
                                  filled: true,
                                  fillColor: AppColors.fieldFill,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address
                    const Text(
                      'Workshop Physical Address',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _address,
                      decoration: InputDecoration(
                        hintText: 'No. 120, High Level Road, Nugegoda',
                        prefixIcon: const Icon(Icons.location_on_rounded,
                            color: AppColors.navy),
                        errorText: _addressError,
                        filled: true,
                        fillColor: AppColors.fieldFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // GPS Coordinates
                    const Text(
                      'GPS Location (Coordinates)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _lat,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Latitude',
                              filled: true,
                              fillColor: AppColors.fieldFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _lng,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Longitude',
                              filled: true,
                              fillColor: AppColors.fieldFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Operating Hours & 24/7 Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Operating Hours',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _is24Hours,
                              activeColor: AppColors.orange,
                              onChanged: (v) {
                                setState(() => _is24Hours = v ?? false);
                              },
                            ),
                            const Text(
                              'Open 24/7',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (!_is24Hours) ...[
                      const SizedBox(height: 4),
                      TextField(
                        controller: _hours,
                        decoration: InputDecoration(
                          hintText: 'e.g. 08:00 AM - 07:00 PM',
                          prefixIcon: const Icon(Icons.access_time_rounded,
                              color: AppColors.navy),
                          filled: true,
                          fillColor: AppColors.fieldFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),

                    // Available Equipment & Facilities
                    const Text(
                      'Facilities & Equipment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableFacilities.map((fac) {
                        final selected = _facilities.contains(fac);
                        return FilterChip(
                          label: Text(fac),
                          selected: selected,
                          selectedColor: AppColors.orange,
                          checkmarkColor: Colors.white,
                          backgroundColor: AppColors.fieldFill,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.navy,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide.none,
                          ),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _facilities.add(fac);
                              } else {
                                _facilities.remove(fac);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Workshop Photos Gallery
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Workshop & Garage Photos',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _imageUrls = [
                                'https://images.unsplash.com/photo-1613214149922-f1809c99b414?w=600&auto=format&fit=crop',
                                'https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=600&auto=format&fit=crop',
                                'https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=600&auto=format&fit=crop',
                              ];
                            });
                          },
                          icon: const Icon(Icons.auto_awesome,
                              size: 16, color: AppColors.orange),
                          label: const Text(
                            'Sample Photos',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _imageUrlController,
                            decoration: InputDecoration(
                              hintText: 'Paste Image URL (e.g. https://...)',
                              prefixIcon: const Icon(Icons.image_outlined,
                                  color: AppColors.navy),
                              filled: true,
                              fillColor: AppColors.fieldFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final url = _imageUrlController.text.trim();
                            if (url.isNotEmpty) {
                              setState(() {
                                _imageUrls.add(url);
                                _imageUrlController.clear();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    if (_imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, idx) {
                            final url = _imageUrls[idx];
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    url,
                                    width: 110,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 110,
                                      height: 90,
                                      color: AppColors.fieldFill,
                                      child: const Icon(
                                        Icons.broken_image_rounded,
                                        color: AppColors.greyText,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _imageUrls.removeAt(idx);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Open / Closed Status Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isOpen ? 'Workshop Open' : 'Workshop Closed',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _isOpen
                                      ? const Color(0xFF22B573)
                                      : Colors.red,
                                ),
                              ),
                              const Text(
                                'Controls whether drivers see you as available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.greyText,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isOpen,
                            activeColor: const Color(0xFF22B573),
                            onChanged: (v) => setState(() => _isOpen = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Garage Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

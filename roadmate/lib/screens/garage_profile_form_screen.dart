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

class _PresetWorkshopPhoto {
  final String title;
  final String category;
  final String url;
  const _PresetWorkshopPhoto({
    required this.title,
    required this.category,
    required this.url,
  });
}

const _workshopPresets = <_PresetWorkshopPhoto>[
  _PresetWorkshopPhoto(
    title: 'Main Workshop & Hoist Bay',
    category: 'Workshop Bay',
    url:
        'https://images.unsplash.com/photo-1613214149922-f1809c99b414?w=800&auto=format&fit=crop',
  ),
  _PresetWorkshopPhoto(
    title: 'Engine Diagnostics & Tuning',
    category: 'Diagnostics',
    url:
        'https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=800&auto=format&fit=crop',
  ),
  _PresetWorkshopPhoto(
    title: 'Precision Tools & Equipment',
    category: 'Tools',
    url:
        'https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=800&auto=format&fit=crop',
  ),
  _PresetWorkshopPhoto(
    title: 'Hydraulic Lift Station',
    category: 'Workshop Bay',
    url:
        'https://images.unsplash.com/photo-1517524008697-84bbe3c3fd98?w=800&auto=format&fit=crop',
  ),
  _PresetWorkshopPhoto(
    title: 'Tire Changer & Wheel Balancer',
    category: 'Tires',
    url:
        'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&auto=format&fit=crop',
  ),
  _PresetWorkshopPhoto(
    title: 'Air Conditioning & Electrical Bay',
    category: 'Electrical',
    url:
        'https://images.unsplash.com/photo-1625047509168-a7026f36de04?w=800&auto=format&fit=crop',
  ),
  _PresetWorkshopPhoto(
    title: 'Customer Reception & Lounge',
    category: 'Lounge',
    url:
        'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=800&auto=format&fit=crop',
  ),
  _PresetWorkshopPhoto(
    title: '24/7 Roadside Recovery Truck',
    category: 'Fleet',
    url:
        'https://images.unsplash.com/photo-1563720223185-11003d516935?w=800&auto=format&fit=crop',
  ),
  _PresetWorkshopPhoto(
    title: 'Modern Workshop Exterior',
    category: 'Exterior',
    url:
        'https://images.unsplash.com/photo-1508974239320-0a029497e820?w=800&auto=format&fit=crop',
  ),
  _PresetWorkshopPhoto(
    title: 'Body Repair & Spray Booth',
    category: 'Body Work',
    url:
        'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=800&auto=format&fit=crop',
  ),
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
      imageUrls: _imageUrls.take(4).toList(),
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

  void _openPhotoGalleryPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Drag handle
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.photo_library_rounded,
                              color: AppColors.orange, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Workshop Photo Gallery',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                              ),
                              Text(
                                '${_imageUrls.length}/4 photo(s) selected (Max 4)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.greyText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.navy),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 20),
                  // Gallery grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.22,
                      ),
                      itemCount: _workshopPresets.length,
                      itemBuilder: (context, idx) {
                        final item = _workshopPresets[idx];
                        final isSelected = _imageUrls.contains(item.url);
                        return GestureDetector(
                          onTap: () {
                            if (!isSelected && _imageUrls.length >= 4) {
                              _snack('Maximum 4 photos allowed');
                              return;
                            }
                            setState(() {
                              if (isSelected) {
                                _imageUrls.remove(item.url);
                              } else {
                                _imageUrls.add(item.url);
                              }
                            });
                            setModalState(() {});
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.orange
                                    : Colors.black12,
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: AppColors.orange.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    item.url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppColors.fieldFill,
                                      child: const Icon(
                                        Icons.broken_image_rounded,
                                        color: AppColors.greyText,
                                      ),
                                    ),
                                  ),
                                  // Gradient overlay
                                  Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black87,
                                        ],
                                        stops: [0.45, 1.0],
                                      ),
                                    ),
                                  ),
                                  // Title & category
                                  Positioned(
                                    left: 8,
                                    right: 8,
                                    bottom: 8,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.orange,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.category,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Checkbox badge
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.orange
                                            : Colors.black45,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isSelected
                                            ? Icons.check
                                            : Icons.add,
                                        color: Colors.white,
                                        size: 14,
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
                  // Direct URL Bar inside modal for maximum flexibility
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.pageBg,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Or paste a custom image URL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.greyText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _imageUrlController,
                                decoration: InputDecoration(
                                  hintText: 'https://...',
                                  prefixIcon: const Icon(
                                      Icons.link_rounded,
                                      color: AppColors.navy,
                                      size: 18),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                final url = _imageUrlController.text.trim();
                                if (url.isNotEmpty) {
                                  if (_imageUrls.length >= 4) {
                                    _snack('Maximum 4 photos allowed');
                                    return;
                                  }
                                  setState(() {
                                    if (!_imageUrls.contains(url)) {
                                      _imageUrls.add(url);
                                    }
                                    _imageUrlController.clear();
                                  });
                                  setModalState(() {});
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Done (${_imageUrls.length}/4 Selected)',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

                    // Workshop Photos Dropzone & Gallery Selector
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
                        if (_imageUrls.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() => _imageUrls.clear()),
                            child: const Text(
                              'Clear All',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Drag & Drop / Photo Gallery Selector Box
                    InkWell(
                      onTap: _openPhotoGalleryPicker,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 22, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.fieldFill.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.navy.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: AppColors.orange.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_upload_outlined,
                                color: AppColors.orange,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Drag & Drop photos or select from gallery',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Select service bays, hoist, diagnostics & lounge photos',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.greyText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _openPhotoGalleryPicker,
                                  icon: const Icon(Icons.photo_library_outlined,
                                      size: 16),
                                  label: const Text('Select from Photo Gallery'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.navy,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _imageUrls = [
                                        'https://images.unsplash.com/photo-1613214149922-f1809c99b414?w=800&auto=format&fit=crop',
                                        'https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=800&auto=format&fit=crop',
                                        'https://images.unsplash.com/photo-1580273916550-e323be2ae537?w=800&auto=format&fit=crop',
                                        'https://images.unsplash.com/photo-1517524008697-84bbe3c3fd98?w=800&auto=format&fit=crop',
                                      ];
                                    });
                                    _snack('Loaded 4 showcase photos (Max 4)');
                                  },
                                  icon: const Icon(Icons.auto_awesome,
                                      size: 15, color: AppColors.orange),
                                  label: const Text(
                                    'Auto Presets',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.orange,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: AppColors.orange),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Selected photos horizontal carousel (Compact & Sleek)
                    if (_imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            'Selected Photos (${_imageUrls.length}/4)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            '1st photo is Cover • Max 4 photos',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.greyText,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 88,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageUrls.length < 4
                              ? _imageUrls.length + 1
                              : _imageUrls.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            if (idx == _imageUrls.length) {
                              // Add More button tile (only if < 4)
                              return InkWell(
                                onTap: _openPhotoGalleryPicker,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 80,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    color: AppColors.fieldFill,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_rounded,
                                          color: AppColors.navy, size: 22),
                                      SizedBox(height: 4),
                                      Text(
                                        'Add More',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.navy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final url = _imageUrls[idx];
                            final isCover = idx == 0;
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    url,
                                    width: 105,
                                    height: 88,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 105,
                                      height: 88,
                                      color: AppColors.fieldFill,
                                      child: const Icon(
                                        Icons.broken_image_rounded,
                                        color: AppColors.greyText,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isCover)
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.orange,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: const Text(
                                        'COVER',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
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
                                      padding: const EdgeInsets.all(3.5),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 12,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/firebase_state.dart';
import '../models/mechanic_service.dart';
import '../services/auth_service.dart';
import '../services/mechanic_service_service.dart';
import '../theme/app_colors.dart';
import '../widgets/roadmate_top_bar.dart';

/// Form to Add (when [service] is null) or Edit a mechanic service.
class ServiceFormScreen extends StatefulWidget {
  final String uid;
  final MechanicService? service;
  final MechanicServiceService? serviceService;

  const ServiceFormScreen({
    super.key,
    required this.uid,
    this.service,
    this.serviceService,
  });

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late final TextEditingController _description;

  late ServiceCategory _category;
  late bool _isAvailable;

  String? _titleError;
  String? _priceError;
  String? _durationError;
  bool _saving = false;
  bool _deleting = false;

  bool get _editing => widget.service != null;
  MechanicServiceService get _service =>
      widget.serviceService ?? MechanicServiceService();

  static const _durationPresets = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _title = TextEditingController(text: s?.title ?? '');
    _price = TextEditingController(
        text: s == null ? '' : s.basePrice.toStringAsFixed(0));
    _duration = TextEditingController(
        text: s == null ? '30' : '${s.estimatedDurationMinutes}');
    _description = TextEditingController(text: s?.description ?? '');
    _category = s?.category ?? ServiceCategory.general;
    _isAvailable = s?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _duration.dispose();
    _description.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _validate() {
    final title = _title.text.trim();
    final price = double.tryParse(_price.text.trim());
    final duration = int.tryParse(_duration.text.trim());

    setState(() {
      _titleError = title.isEmpty ? 'Please enter a service title' : null;
      _priceError = price == null || price <= 0
          ? 'Enter a valid base price (e.g. 2500)'
          : null;
      _durationError = duration == null || duration <= 0
          ? 'Enter estimated time in minutes'
          : null;
    });

    return _titleError == null &&
        _priceError == null &&
        _durationError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    if (!firebaseReady && widget.serviceService == null) {
      _snack('Firebase not connected yet. Add google-services files first.');
      return;
    }

    setState(() => _saving = true);
    final price = double.parse(_price.text.trim());
    final duration = int.parse(_duration.text.trim());

    try {
      if (_editing) {
        final updated = widget.service!.copyWith(
          title: _title.text.trim(),
          category: _category,
          basePrice: price,
          estimatedDurationMinutes: duration,
          description: _description.text.trim(),
          isAvailable: _isAvailable,
        );
        await _service.updateService(widget.uid, updated);
        if (!mounted) return;
        _snack('Service updated successfully');
      } else {
        final newService = MechanicService(
          id: '',
          title: _title.text.trim(),
          category: _category,
          basePrice: price,
          estimatedDurationMinutes: duration,
          description: _description.text.trim(),
          isAvailable: _isAvailable,
        );
        await _service.addService(widget.uid, newService);
        if (!mounted) return;
        _snack('New service added');
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Service?'),
        content: Text(
            'Are you sure you want to remove "${widget.service!.title}" from your offered services?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!firebaseReady && widget.serviceService == null) {
      _snack('Firebase not connected yet.');
      return;
    }

    setState(() => _deleting = true);
    try {
      await _service.deleteService(widget.uid, widget.service!.id);
      if (!mounted) return;
      _snack('Service deleted');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _deleting = false);
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
              title: _editing ? 'Edit Service' : 'Add Service',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Title
                    const Text(
                      'Service Title',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _title,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'e.g. Battery Jumpstart, Tyre Puncture',
                        prefixIcon: const Icon(Icons.build_rounded,
                            color: AppColors.navy),
                        errorText: _titleError,
                        filled: true,
                        fillColor: AppColors.fieldFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Category Dropdown
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ServiceCategory>(
                          value: _category,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: AppColors.navy),
                          onChanged: (cat) {
                            if (cat != null) setState(() => _category = cat);
                          },
                          items: ServiceCategory.values
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Row(
                                    children: [
                                      Icon(c.icon,
                                          size: 20, color: AppColors.orange),
                                      const SizedBox(width: 10),
                                      Text(
                                        c.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.navy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Base Price
                    const Text(
                      'Base Price (LKR)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: 'e.g. 2500',
                        prefixText: 'Rs. ',
                        prefixStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                        errorText: _priceError,
                        filled: true,
                        fillColor: AppColors.fieldFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Estimated Duration
                    const Text(
                      'Estimated Duration (Minutes)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _duration,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: '30',
                        suffixText: 'mins',
                        errorText: _durationError,
                        filled: true,
                        fillColor: AppColors.fieldFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Duration Preset Chips
                    Wrap(
                      spacing: 8,
                      children: _durationPresets.map((m) {
                        final selected = _duration.text == '$m';
                        return ChoiceChip(
                          label: Text('$m m'),
                          selected: selected,
                          selectedColor: AppColors.orange,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.navy,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          onSelected: (_) {
                            setState(() => _duration.text = '$m');
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Description
                    const Text(
                      'Description & Inclusions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _description,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Describe what is included (e.g. On-site inspection, booster pack setup...)',
                        filled: true,
                        fillColor: AppColors.fieldFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Availability Switch
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
                              const Text(
                                'Available for Booking',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                              ),
                              Text(
                                _isAvailable
                                    ? 'Drivers can see and book this service'
                                    : 'Temporarily disabled',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.greyText,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isAvailable,
                            activeColor: AppColors.orange,
                            onChanged: (v) => setState(() => _isAvailable = v),
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
                            : Text(
                                _editing ? 'Update Service' : 'Save Service',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),

                    if (_editing) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton.icon(
                          onPressed: _deleting ? null : _delete,
                          icon: _deleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.red),
                                  ),
                                )
                              : const Icon(Icons.delete_outline_rounded,
                                  color: Colors.red),
                          label: const Text(
                            'Delete Service',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/vehicle.dart';
import '../services/auth_service.dart';
import '../services/vehicle_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/roadmate_top_bar.dart';

/// Add a vehicle, or edit [vehicle] when given. Not in the Figma set — built
/// with the same field/label widgets as the auth screens.
class VehicleFormScreen extends StatefulWidget {
  final AppUser user;
  final VehicleService vehicleService;
  final Vehicle? vehicle;

  const VehicleFormScreen({
    super.key,
    required this.user,
    required this.vehicleService,
    this.vehicle,
  });

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  late final _make = TextEditingController(text: widget.vehicle?.make);
  late final _model = TextEditingController(text: widget.vehicle?.model);
  late final _year = TextEditingController(
      text: (widget.vehicle?.year ?? 0) > 0 ? '${widget.vehicle!.year}' : '');
  late final _plate = TextEditingController(text: widget.vehicle?.plateNo);
  late final _color = TextEditingController(text: widget.vehicle?.color);
  late VehicleType _type = widget.vehicle?.type ?? VehicleType.car;
  late FuelType _fuel = widget.vehicle?.fuelType ?? FuelType.petrol;
  bool _saving = false;

  bool get _editing => widget.vehicle != null;

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _plate.dispose();
    _color.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _save() async {
    final make = _make.text.trim();
    final model = _model.text.trim();
    final plate = _plate.text.trim().toUpperCase();
    final year = int.tryParse(_year.text.trim());
    final maxYear = DateTime.now().year + 1;
    if (make.isEmpty || model.isEmpty || plate.isEmpty) {
      _snack('Please enter make, model and registration number.');
      return;
    }
    if (year == null || year < 1950 || year > maxYear) {
      _snack('Enter a valid year (1950–$maxYear).');
      return;
    }
    final v = Vehicle(
      id: widget.vehicle?.id ?? '',
      make: make,
      model: model,
      year: year,
      plateNo: plate,
      type: _type,
      fuelType: _fuel,
      color: _color.text.trim(),
      isDefault: widget.vehicle?.isDefault ?? false,
      photoUrl: widget.vehicle?.photoUrl ?? '',
    );
    setState(() => _saving = true);
    try {
      if (_editing) {
        await widget.vehicleService.updateVehicle(widget.user.uid, v);
      } else {
        await widget.vehicleService.addVehicle(widget.user.uid, v);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(AuthService.friendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RoadMateTopBar(),
              const SizedBox(height: 14),
              PageTitleRow(
                title: _editing ? 'Edit Vehicle' : 'Add Vehicle',
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFDDE3F2), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AuthLabel(text: 'Make'),
                    AuthTextField(
                      hint: 'e.g. Toyota',
                      prefix: Icons.directions_car_outlined,
                      controller: _make,
                    ),
                    const SizedBox(height: 14),
                    const AuthLabel(text: 'Model'),
                    AuthTextField(
                      hint: 'e.g. Corolla',
                      prefix: Icons.badge_outlined,
                      controller: _model,
                    ),
                    const SizedBox(height: 14),
                    const AuthLabel(text: 'Year'),
                    AuthTextField(
                      hint: 'e.g. 2020',
                      prefix: Icons.calendar_month_outlined,
                      controller: _year,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    const AuthLabel(text: 'Registration No'),
                    AuthTextField(
                      hint: 'e.g. CAK 1234',
                      prefix: Icons.pin_outlined,
                      controller: _plate,
                    ),
                    const SizedBox(height: 14),
                    const AuthLabel(text: 'Color'),
                    AuthTextField(
                      hint: 'e.g. Blue',
                      prefix: Icons.palette_outlined,
                      controller: _color,
                    ),
                    const SizedBox(height: 16),
                    const AuthLabel(text: 'Vehicle Type'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final t in VehicleType.values)
                          ChoiceChip(
                            label: Text(t.label),
                            selected: _type == t,
                            onSelected: (_) => setState(() => _type = t),
                            selectedColor: AppColors.peachBg,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const AuthLabel(text: 'Fuel Type'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final f in FuelType.values)
                          ChoiceChip(
                            label: Text(f.label),
                            selected: _fuel == f,
                            onSelected: (_) => setState(() => _fuel = f),
                            selectedColor: AppColors.peachBg,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    _editing ? 'Save Changes' : 'Save Vehicle',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.fieldFill,
                    foregroundColor: AppColors.navyDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

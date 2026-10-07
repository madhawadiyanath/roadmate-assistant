import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/firebase_state.dart';
import '../models/vehicle.dart';
import '../services/auth_service.dart';
import '../services/vehicle_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/roadmate_top_bar.dart';

const _fuelTypes = ['Petrol', 'Diesel', 'Hybrid', 'Electric', 'CNG'];

/// Add (no [vehicle]) or edit (with [vehicle]) a saved vehicle.
/// Pops `true` after a successful save.
class VehicleFormScreen extends StatefulWidget {
  final String uid;
  final Vehicle? vehicle;
  final VehicleService? service;

  const VehicleFormScreen({
    super.key,
    required this.uid,
    this.vehicle,
    this.service,
  });

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  late final TextEditingController _make;
  late final TextEditingController _model;
  late final TextEditingController _year;
  late final TextEditingController _plate;
  late final TextEditingController _color;
  late VehicleType _type;
  late String _fuel;

  String? _makeError, _modelError, _plateError, _yearError;
  bool _saving = false;

  bool get _editing => widget.vehicle != null;
  VehicleService get _service => widget.service ?? VehicleService();

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _make = TextEditingController(text: v?.make ?? '');
    _model = TextEditingController(text: v?.model ?? '');
    _year = TextEditingController(text: v == null ? '' : '${v.year}');
    _plate = TextEditingController(text: v?.plateNo ?? '');
    _color = TextEditingController(text: v?.color ?? '');
    _type = v?.type ?? VehicleType.car;
    _fuel = (v?.fuelType.isNotEmpty ?? false) ? v!.fuelType : _fuelTypes.first;
  }

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _plate.dispose();
    _color.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Returns the parsed year when everything is valid, else null (and
  /// shows the inline errors).
  int? _validate() {
    final maxYear = DateTime.now().year + 1;
    final year = int.tryParse(_year.text.trim());
    setState(() {
      _makeError = _make.text.trim().isEmpty ? 'Enter the make' : null;
      _modelError = _model.text.trim().isEmpty ? 'Enter the model' : null;
      _plateError =
          _plate.text.trim().isEmpty ? 'Enter the registration number' : null;
      _yearError = year == null || year < 1950 || year > maxYear
          ? 'Enter a year between 1950 and $maxYear'
          : null;
    });
    final ok = _makeError == null &&
        _modelError == null &&
        _plateError == null &&
        _yearError == null;
    return ok ? year : null;
  }

  Future<void> _save() async {
    final year = _validate();
    if (year == null) return;
    if (!firebaseReady && widget.service == null) {
      _snack('Firebase not connected yet. Add google-services files first.');
      return;
    }
    setState(() => _saving = true);
    try {
      final v = Vehicle(
        id: widget.vehicle?.id ?? '',
        make: _make.text.trim(),
        model: _model.text.trim(),
        year: year,
        plateNo: _plate.text.trim().toUpperCase(),
        type: _type,
        fuelType: _fuel,
        color: _color.text.trim(),
        photoUrl: widget.vehicle?.photoUrl,
      );
      if (_editing) {
        await _service.updateVehicle(widget.uid, v);
      } else {
        await _service.addVehicle(widget.uid, v);
      }
      if (!mounted) return;
      _snack(_editing ? 'Vehicle updated.' : 'Vehicle added.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _snack(AuthService.friendlyMessage(e));
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
              title: _editing ? 'Edit Vehicle' : 'Add Vehicle',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AuthLabel(text: 'Make'),
                    AuthTextField(
                      hint: 'Toyota',
                      prefix: Icons.directions_car_outlined,
                      controller: _make,
                      errorText: _makeError,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) {
                        if (_makeError != null) {
                          setState(() => _makeError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    const AuthLabel(text: 'Model'),
                    AuthTextField(
                      hint: 'Corolla',
                      prefix: Icons.badge_outlined,
                      controller: _model,
                      errorText: _modelError,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) {
                        if (_modelError != null) {
                          setState(() => _modelError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    const AuthLabel(text: 'Year'),
                    AuthTextField(
                      hint: '2020',
                      prefix: Icons.calendar_month_outlined,
                      controller: _year,
                      keyboardType: TextInputType.number,
                      errorText: _yearError,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onChanged: (_) {
                        if (_yearError != null) {
                          setState(() => _yearError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    const AuthLabel(text: 'Registration No'),
                    AuthTextField(
                      hint: 'CAK 1234',
                      prefix: Icons.pin_outlined,
                      controller: _plate,
                      errorText: _plateError,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) {
                        if (_plateError != null) {
                          setState(() => _plateError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    const AuthLabel(text: 'Vehicle Type'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in VehicleType.values)
                          _Choice(
                            label: t.label,
                            selected: _type == t,
                            onTap: () => setState(() => _type = t),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const AuthLabel(text: 'Color'),
                    AuthTextField(
                      hint: 'Blue',
                      prefix: Icons.palette_outlined,
                      controller: _color,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 14),
                    const AuthLabel(text: 'Fuel Type'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in {
                          ..._fuelTypes,
                          // Keep an unusual stored value selectable.
                          _fuel,
                        })
                          _Choice(
                            label: f,
                            selected: _fuel == f,
                            onTap: () => setState(() => _fuel = f),
                          ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _editing ? 'Save Changes' : 'Save Vehicle',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
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
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.fieldFill,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.navyDark,
            ),
          ),
        ),
      ),
    );
  }
}

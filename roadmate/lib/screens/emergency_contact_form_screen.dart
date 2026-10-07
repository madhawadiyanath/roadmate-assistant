import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/firebase_state.dart';
import '../models/emergency_contact.dart';
import '../services/auth_service.dart';
import '../services/emergency_contact_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/roadmate_top_bar.dart';

/// Add (no [contact]) or edit (with [contact]) an emergency contact.
/// Pops `true` after a successful save.
class EmergencyContactFormScreen extends StatefulWidget {
  final String uid;
  final EmergencyContact? contact;
  final EmergencyContactService? service;

  const EmergencyContactFormScreen({
    super.key,
    required this.uid,
    this.contact,
    this.service,
  });

  @override
  State<EmergencyContactFormScreen> createState() =>
      _EmergencyContactFormScreenState();
}

class _EmergencyContactFormScreenState
    extends State<EmergencyContactFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late ContactRelation _relation;
  String? _nameError, _phoneError;
  bool _saving = false;

  bool get _editing => widget.contact != null;
  EmergencyContactService get _service =>
      widget.service ?? EmergencyContactService();

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    _name = TextEditingController(text: c?.name ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _relation = c?.relation ?? ContactRelation.family;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _validate() {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '').length;
    setState(() {
      _nameError = _name.text.trim().isEmpty ? 'Enter a name' : null;
      _phoneError = _phone.text.trim().isEmpty
          ? 'Enter a phone number'
          : (digits < 7 || digits > 15)
              ? 'Enter a valid phone number'
              : null;
    });
    return _nameError == null && _phoneError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    if (!firebaseReady && widget.service == null) {
      _snack('Firebase not connected yet. Add google-services files first.');
      return;
    }
    setState(() => _saving = true);
    try {
      final c = EmergencyContact(
        id: widget.contact?.id ?? '',
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        relation: _relation,
      );
      if (_editing) {
        await _service.updateContact(widget.uid, c);
      } else {
        await _service.addContact(widget.uid, c);
      }
      if (!mounted) return;
      _snack(_editing ? 'Contact updated.' : 'Contact added.');
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
              title: _editing ? 'Edit Contact' : 'Add Contact',
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
                    const AuthLabel(text: 'Full Name'),
                    AuthTextField(
                      hint: 'Kamala Perera',
                      prefix: Icons.person_outline_rounded,
                      controller: _name,
                      errorText: _nameError,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) {
                        if (_nameError != null) {
                          setState(() => _nameError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    const AuthLabel(text: 'Phone Number'),
                    AuthTextField(
                      hint: '+94 77 123 4567',
                      prefix: Icons.phone_outlined,
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      errorText: _phoneError,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
                        LengthLimitingTextInputFormatter(20),
                      ],
                      onChanged: (_) {
                        if (_phoneError != null) {
                          setState(() => _phoneError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    const AuthLabel(text: 'Relation'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final r in ContactRelation.values)
                          _Choice(
                            label: r.label,
                            selected: _relation == r,
                            onTap: () => setState(() => _relation = r),
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
                                _editing ? 'Save Changes' : 'Save Contact',
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

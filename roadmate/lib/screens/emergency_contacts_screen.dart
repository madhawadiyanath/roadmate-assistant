import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/emergency_contact.dart';
import '../services/auth_service.dart';
import '../services/emergency_contact_service.dart';
import '../theme/app_colors.dart';
import '../widgets/contact_widgets.dart';
import '../widgets/roadmate_top_bar.dart';
import '../widgets/state_message.dart';
import 'emergency_contact_form_screen.dart';

/// People notified with the driver's live location in an emergency.
/// Add / edit / delete, with loading, error, empty and
/// "Firebase not connected" states.
class EmergencyContactsScreen extends StatefulWidget {
  final String uid;
  final EmergencyContactService? service;
  final VoidCallback? onAvatarTap;

  const EmergencyContactsScreen({
    super.key,
    required this.uid,
    this.service,
    this.onAvatarTap,
  });

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  Stream<List<EmergencyContact>>? _stream;

  /// An injected service (tests, previews) always counts as connected.
  bool get _connected => widget.service != null || firebaseReady;
  EmergencyContactService get _service =>
      widget.service ?? EmergencyContactService();

  @override
  void initState() {
    super.initState();
    if (_connected) _stream = _service.watchContacts(widget.uid);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openForm([EmergencyContact? contact]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmergencyContactFormScreen(
          uid: widget.uid,
          contact: contact,
          service: widget.service,
        ),
      ),
    );
  }

  Future<void> _delete(EmergencyContact c) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text('${c.name} will no longer be notified in an emergency.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    try {
      await _service.deleteContact(widget.uid, c.id);
      if (mounted) _snack('Contact deleted.');
    } catch (e) {
      if (mounted) _snack(AuthService.friendlyMessage(e));
    }
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
              title: 'Emergency Contacts',
              onBack: () => Navigator.pop(context),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'People we notify with your live location when you '
                  'request urgent help.',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.35,
                    color: AppColors.navyDark,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add_rounded, size: 24),
                  label: const Text(
                    'Add Emergency Contact',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final stream = _stream;
    if (stream == null) {
      return const StateMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Firebase not connected',
        message: 'Add your google-services files to save emergency contacts.',
      );
    }
    return StreamBuilder<List<EmergencyContact>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return StateMessage(
            icon: Icons.error_outline_rounded,
            color: const Color(0xFFB02A37),
            title: 'Could not load contacts',
            message: AuthService.friendlyMessage(snap.error!),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return const StateMessage(
            icon: Icons.contacts_outlined,
            title: 'No emergency contacts yet',
            message: 'Add someone we should alert when you need urgent help.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          itemCount: list.length,
          itemBuilder: (_, i) => ContactCard(
            contact: list[i],
            onEdit: () => _openForm(list[i]),
            onDelete: () => _delete(list[i]),
          ),
        );
      },
    );
  }
}

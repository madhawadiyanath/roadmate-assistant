import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/roadmate_top_bar.dart';
import '../widgets/state_message.dart';

/// Profile → Change Password for a signed-in user: confirm the current
/// password, then pick a new one. Accounts that only use Google Sign-In
/// have no password, so they get an explanation instead of the form.
class ChangePasswordScreen extends StatefulWidget {
  final AuthService? authService;
  const ChangePasswordScreen({super.key, this.authService});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  String? _currentError, _newError, _confirmError;
  bool _saving = false;

  /// An injected service (tests, previews) always counts as connected.
  bool get _connected => widget.authService != null || firebaseReady;
  AuthService get _auth => widget.authService ?? AuthService();

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _validate() {
    final cur = _current.text;
    final next = _new.text;
    setState(() {
      _currentError = cur.isEmpty ? 'Enter your current password' : null;
      _newError = next.length < 6
          ? 'Password should be at least 6 characters.'
          : (next == cur
              ? 'New password must be different from current password'
              : null);
      _confirmError = _confirm.text != next ? 'Passwords do not match' : null;
    });
    return _currentError == null && _newError == null && _confirmError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      await _auth.changePassword(
        currentPassword: _current.text,
        newPassword: _new.text,
      );
      if (!mounted) return;
      _snack('Password updated successfully');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      if (AuthService.isWrongPassword(e)) {
        setState(() => _currentError = 'Current password is incorrect');
      } else if (e is FirebaseAuthException && e.code == 'weak-password') {
        setState(() => _newError = 'Password should be at least 6 characters.');
      } else {
        _snack(AuthService.friendlyMessage(e));
      }
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
              title: 'Change Password',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (!_connected) {
      return const StateMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Firebase not connected',
        message: 'Add your google-services files to change your password.',
      );
    }
    if (!_auth.hasPassword) {
      return const StateMessage(
        icon: Icons.verified_user_outlined,
        title: 'No password to change',
        message: "Your account uses Google Sign-In, so there's no password "
            'to change.',
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthLabel(text: 'Current password'),
          AuthTextField(
            hint: 'Your current password',
            prefix: Icons.lock_outline_rounded,
            obscure: true,
            showToggle: true,
            controller: _current,
            errorText: _currentError,
            onChanged: (_) {
              if (_currentError != null) setState(() => _currentError = null);
            },
          ),
          const SizedBox(height: 14),
          const AuthLabel(text: 'New password'),
          AuthTextField(
            hint: 'At least 6 characters',
            prefix: Icons.lock_outline_rounded,
            obscure: true,
            showToggle: true,
            controller: _new,
            errorText: _newError,
            onChanged: (_) {
              if (_newError != null) setState(() => _newError = null);
            },
          ),
          const SizedBox(height: 14),
          const AuthLabel(text: 'Confirm new password'),
          AuthTextField(
            hint: 'Re-enter the new password',
            prefix: Icons.lock_outline_rounded,
            obscure: true,
            showToggle: true,
            controller: _confirm,
            errorText: _confirmError,
            onChanged: (_) {
              if (_confirmError != null) setState(() => _confirmError = null);
            },
          ),
          const SizedBox(height: 22),
          PrimaryAuthButton(
            text: 'Update Password',
            isLoading: _saving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

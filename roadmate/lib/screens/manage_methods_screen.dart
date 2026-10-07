import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/firebase_state.dart';
import '../models/payments.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../theme/app_colors.dart';

/// Saved cards: list, default, delete, add.
class ManageMethodsScreen extends StatefulWidget {
  final String uid;
  final PaymentService? paymentService;
  const ManageMethodsScreen({
    super.key,
    required this.uid,
    this.paymentService,
  });

  @override
  State<ManageMethodsScreen> createState() => _ManageMethodsScreenState();
}

class _ManageMethodsScreenState extends State<ManageMethodsScreen> {
  PaymentService get _pay => widget.paymentService ?? PaymentService();

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addCard() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 22,
          bottom: MediaQuery.of(context).viewInsets.bottom + 22,
        ),
        child: _AddCardSheet(
          onSave: (number, expiry) async {
            try {
              await _pay.addCard(
                uid: widget.uid,
                cardNumber: number,
                expiry: expiry,
              );
              if (!mounted) return;
              Navigator.pop(context, true);
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AuthService.friendlyMessage(e))),
              );
            }
          },
        ),
      ),
    );
    if (saved == true && mounted) _snack('Card added.');
  }

  Future<void> _confirmDelete(SavedMethod m) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove ${m.label}?'),
        content: const Text('Future payments cannot use this card.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _pay.deleteMethod(uid: widget.uid, methodId: m.id);
    } catch (e) {
      if (!mounted) return;
      _snack(AuthService.friendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        foregroundColor: AppColors.navy,
        title: const Text(
          'Payment Methods',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
      ),
      body: !firebaseReady
          ? const Center(
              child: Text(
                'Connect Firebase to manage cards.',
                style: TextStyle(color: AppColors.greyText),
              ),
            )
          : StreamBuilder<List<SavedMethod>>(
              stream: _pay.watchMethods(widget.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Could not load.\n${snap.error}'));
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No saved cards yet.',
                      style:
                          TextStyle(color: AppColors.greyText, fontSize: 13),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final m = items[i];
                    return _MethodTile(
                      method: m,
                      onDefault: m.isDefault
                          ? null
                          : () => _pay.setDefault(
                              uid: widget.uid, methodId: m.id),
                      onDelete: () => _confirmDelete(m),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: !firebaseReady
            ? () => _snack('Firebase not connected yet.')
            : _addCard,
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_card_rounded),
        label: const Text('Add Card'),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final SavedMethod method;
  final VoidCallback? onDefault;
  final VoidCallback onDelete;
  const _MethodTile({
    required this.method,
    required this.onDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: method.isDefault
              ? AppColors.navy
              : const Color(0xFFEDF1F7),
          width: method.isDefault ? 1.8 : 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.label,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                  ),
                ),
                Text(
                  method.detail,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.greyText,
                  ),
                ),
              ],
            ),
          ),
          if (method.isDefault)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7EE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Default',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF22B573),
                ),
              ),
            )
          else
            TextButton(
              onPressed: onDefault,
              child: const Text('Set default'),
            ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.red,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCardSheet extends StatefulWidget {
  final Future<void> Function(String number, String expiry) onSave;
  const _AddCardSheet({required this.onSave});

  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _holder = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _number.dispose();
    _expiry.dispose();
    _holder.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final digits = _number.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 16) {
      setState(() => _error = 'Card number must be 16 digits.');
      return;
    }
    if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(_expiry.text.trim())) {
      setState(() => _error = 'Expiry must look like MM/YY.');
      return;
    }
    if (_holder.text.trim().isEmpty) {
      setState(() => _error = 'Enter the name on the card.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await widget.onSave(digits, _expiry.text.trim());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Card',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Only the last 4 digits are stored.',
          style: TextStyle(fontSize: 12.5, color: AppColors.greyText),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _number,
          keyboardType: TextInputType.number,
          maxLength: 19,
          inputFormatters: [_CardNumberFormatter()],
          decoration: const InputDecoration(
            labelText: 'Card number',
            hintText: '4242 4242 4242 4242',
            border: OutlineInputBorder(),
            counterText: '',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiry,
                keyboardType: TextInputType.datetime,
                maxLength: 5,
                inputFormatters: [_ExpiryFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Expiry',
                  hintText: 'MM/YY',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _holder,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name on card',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 12.5),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                : const Text('Save Card',
                    style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

/// Groups digits in fours: 4242 4242 4242 4242.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.substring(0, digits.length.clamp(0, 16));
    final buf = StringBuffer();
    for (int i = 0; i < capped.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(capped[i]);
    }
    final out = buf.toString();
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

/// Auto slash: MM/YY.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    final out = digits.length > 2
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : digits;
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

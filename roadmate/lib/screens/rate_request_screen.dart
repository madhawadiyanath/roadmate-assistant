import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/service_request.dart';
import '../services/assistance_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/rating_widgets.dart';
import '../widgets/roadmate_top_bar.dart';
import 'payment_review_screen.dart' show feeFor, formatFee;

/// Rate a finished job: 1–5 stars (nothing pre-selected), optional
/// feedback and quick tags, with the payment summary shown as a receipt.
/// Pops `true` after the rating was saved.
class RateRequestScreen extends StatefulWidget {
  final ServiceRequest request;
  final AssistanceService? service;

  const RateRequestScreen({super.key, required this.request, this.service});

  @override
  State<RateRequestScreen> createState() => _RateRequestScreenState();
}

class _RateRequestScreenState extends State<RateRequestScreen> {
  final _feedback = TextEditingController();
  final _tags = <String>{};
  int _rating = 0; // deliberately empty: the driver has to choose
  bool _starError = false;
  bool _submitting = false;

  /// An injected service (tests, previews) always counts as connected.
  bool get _connected => widget.service != null || firebaseReady;
  AssistanceService get _service => widget.service ?? AssistanceService();

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      setState(() => _starError = true);
      return;
    }
    if (!_connected) {
      _snack('Firebase not connected yet. Add google-services files first.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _service.rateRequest(
        requestId: widget.request.id,
        rating: _rating,
        feedback: _feedback.text,
        // Keep the on-screen order, not the order they were tapped in.
        tags: [for (final t in ratingTags) if (_tags.contains(t)) t],
      );
      if (!mounted) return;
      _snack('Thanks for your feedback!');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final fee = feeFor(r.type);
    final total = r.totalFee > 0 ? r.totalFee : fee.total;
    final mechanic =
        r.mechanicName.trim().isEmpty ? 'Your mechanic' : r.mechanicName.trim();

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            const RoadMateTopBar(),
            RoadMatePageTitle(
              title: 'Rate Your Experience',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7EE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle,
                                  size: 8, color: Color(0xFF22B573)),
                              SizedBox(width: 6),
                              Text(
                                'COMPLETED',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF1C8C5A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'How was the service during your breakdown?',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: AppColors.greyText,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Mechanic + request id
                    _Card(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.fieldFill,
                            child: Text(
                              mechanic[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mechanic,
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                                ),
                                Text(
                                  r.type.label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.greyText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Request',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.greyText,
                                  ),
                                ),
                                Text(
                                  r.refCode,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Rating
                    _Card(
                      child: Column(
                        children: [
                          Text(
                            _rating == 0
                                ? ratingLabel(0)
                                : '${ratingLabel(_rating)} '
                                    '(${_rating.toStringAsFixed(1)})',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navyDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          StarRow(
                            rating: _rating,
                            onChanged: (v) => setState(() {
                              _rating = v;
                              _starError = false;
                            }),
                          ),
                          const SizedBox(height: 6),
                          if (_starError)
                            const Text(
                              'Please select a star rating',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE5484D),
                              ),
                            )
                          else
                            Text(
                              _rating == 0
                                  ? 'Tap a star to rate'
                                  : 'Tap to adjust rating',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.greyText,
                              ),
                            ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _feedback,
                            maxLines: 3,
                            maxLength: 500,
                            style: const TextStyle(
                                fontSize: 13.5, color: AppColors.navyDark),
                            decoration: InputDecoration(
                              hintText: 'Share your feedback (optional) — '
                                  '$mechanic and the dispatch team read every '
                                  'note…',
                              hintStyle: const TextStyle(
                                  color: AppColors.fieldHint, fontSize: 13),
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.fieldFill,
                              contentPadding: const EdgeInsets.all(14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.navy, width: 1.3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final t in ratingTags)
                                  RatingTagChip(
                                    label: t,
                                    selected: _tags.contains(t),
                                    onTap: () => setState(() =>
                                        _tags.contains(t)
                                            ? _tags.remove(t)
                                            : _tags.add(t)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Receipt (read-only)
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Payment Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.receipt_long_outlined,
                                      size: 15, color: AppColors.greyText),
                                  SizedBox(width: 4),
                                  Text(
                                    'Receipt',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.greyText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _FeeLine(fee.line1, formatFee(fee.fee1)),
                          const SizedBox(height: 6),
                          _FeeLine(fee.line2, formatFee(fee.fee2)),
                          const Divider(height: 22, color: Color(0xFFEDF1F7)),
                          const Text(
                            'TOTAL PAID',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navyDark,
                            ),
                          ),
                          const Text(
                            'Taxes & toll included',
                            style: TextStyle(
                                fontSize: 11.5, color: Color(0xFF1C8C5A)),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              formatFee(total),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit Rating',
                                style: TextStyle(
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

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
      ),
      child: child,
    );
  }
}

class _FeeLine extends StatelessWidget {
  final String label;
  final String value;
  const _FeeLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13.5, color: AppColors.greyText)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
          ),
        ),
      ],
    );
  }
}

import 'service_request.dart';

/// Average star rating over a mechanic's real, submitted ratings.
///
/// Only completed requests the driver actually rated count (`ratedAt` is
/// set and the rating is 1–5), so legacy docs that carry a default rating
/// from before the rating screen existed are ignored.
class RatingSummary {
  final double average;
  final int count;

  const RatingSummary({required this.average, required this.count});

  static const none = RatingSummary(average: 0, count: 0);

  factory RatingSummary.from(Iterable<ServiceRequest> requests) {
    var sum = 0;
    var n = 0;
    for (final r in requests) {
      if (r.status == RequestStatus.completed && r.isRated) {
        sum += r.rating;
        n++;
      }
    }
    return n == 0 ? none : RatingSummary(average: sum / n, count: n);
  }

  bool get hasRatings => count > 0;

  /// "4.8", or "—" when nobody has rated yet.
  String get averageText => hasRatings ? average.toStringAsFixed(1) : '—';

  /// "4.8 (12 reviews)" / "4.5 (1 review)" / "No ratings yet".
  String get label => !hasRatings
      ? 'No ratings yet'
      : '${average.toStringAsFixed(1)} ($count ${count == 1 ? 'review' : 'reviews'})';
}

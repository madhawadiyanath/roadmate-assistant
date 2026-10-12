import 'package:cloud_firestore/cloud_firestore.dart';

/// Earnings record for the service provider (mechanic) side.
class EarningsRecord {
  final String jobId;
  final String transactionId;
  final String serviceType;
  final String customerName;
  final double serviceCharge;
  final double platformFee;
  final double netEarnings;
  final String paymentStatus;
  final DateTime completedDate;
  final String mechanicUid;
  final String notes;
  final bool isReversed;
  final String? adjustmentReason;

  const EarningsRecord({
    required this.jobId,
    required this.transactionId,
    required this.serviceType,
    this.customerName = '',
    required this.serviceCharge,
    this.platformFee = 0,
    required this.netEarnings,
    this.paymentStatus = 'Completed',
    required this.completedDate,
    this.mechanicUid = '',
    this.notes = '',
    this.isReversed = false,
    this.adjustmentReason,
  });

  bool get isCompleted =>
      paymentStatus.toLowerCase() == 'completed' && !isReversed;

  EarningsRecord copyWith({
    String? jobId,
    String? transactionId,
    String? serviceType,
    String? customerName,
    double? serviceCharge,
    double? platformFee,
    double? netEarnings,
    String? paymentStatus,
    DateTime? completedDate,
    String? mechanicUid,
    String? notes,
    bool? isReversed,
    String? adjustmentReason,
  }) {
    return EarningsRecord(
      jobId: jobId ?? this.jobId,
      transactionId: transactionId ?? this.transactionId,
      serviceType: serviceType ?? this.serviceType,
      customerName: customerName ?? this.customerName,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      platformFee: platformFee ?? this.platformFee,
      netEarnings: netEarnings ?? this.netEarnings,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      completedDate: completedDate ?? this.completedDate,
      mechanicUid: mechanicUid ?? this.mechanicUid,
      notes: notes ?? this.notes,
      isReversed: isReversed ?? this.isReversed,
      adjustmentReason: adjustmentReason ?? this.adjustmentReason,
    );
  }

  Map<String, dynamic> toMap() => {
        'jobId': jobId,
        'transactionId': transactionId,
        'serviceType': serviceType,
        'customerName': customerName,
        'serviceCharge': serviceCharge,
        'platformFee': platformFee,
        'netEarnings': netEarnings,
        'paymentStatus': paymentStatus,
        'completedDate': Timestamp.fromDate(completedDate),
        'mechanicUid': mechanicUid,
        'notes': notes,
        'isReversed': isReversed,
        if (adjustmentReason != null) 'adjustmentReason': adjustmentReason,
      };

  factory EarningsRecord.fromMap(Map<String, dynamic> data, String id) {
    DateTime parsedDate = DateTime.now();
    final cdVal = data['completedDate'] ?? data['createdAt'] ?? data['dateTime'];
    if (cdVal is Timestamp) {
      parsedDate = cdVal.toDate();
    } else if (cdVal is String) {
      parsedDate = DateTime.tryParse(cdVal) ?? DateTime.now();
    }

    return EarningsRecord(
      jobId: data['jobId'] as String? ?? id,
      transactionId: data['transactionId'] as String? ?? '',
      serviceType: data['serviceType'] as String? ?? '',
      customerName: data['customerName'] as String? ??
          (data['payerName'] as String? ?? ''),
      serviceCharge: (data['serviceCharge'] as num?)?.toDouble() ?? 0.0,
      platformFee: (data['platformFee'] as num?)?.toDouble() ?? 0.0,
      netEarnings: (data['netEarnings'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: data['paymentStatus'] as String? ??
          (data['status'] as String? ?? 'Completed'),
      completedDate: parsedDate,
      mechanicUid: data['mechanicUid'] as String? ??
          (data['payeeUid'] as String? ?? ''),
      notes: data['notes'] as String? ?? '',
      isReversed: data['isReversed'] as bool? ?? false,
      adjustmentReason: data['adjustmentReason'] as String?,
    );
  }

  factory EarningsRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return EarningsRecord.fromMap(data, doc.id);
  }
}

/// Helper function to create relative mock date
DateTime _mockDate(int daysAgo, int hoursAgo) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, now.hour, now.minute)
      .subtract(Duration(days: daysAgo, hours: hoursAgo));
}

/// Mock earnings data with current period compatibility.
List<EarningsRecord> mockEarnings = [
  EarningsRecord(
    jobId: 'Job #RM1028',
    transactionId: 'TXN-89410284',
    serviceType: 'Tire & Wheel Service',
    customerName: 'Kasun J.',
    serviceCharge: 4500,
    platformFee: 450,
    netEarnings: 4050,
    paymentStatus: 'Completed',
    completedDate: _mockDate(0, 2), // Today
    notes: 'Completed on-site spare tire fitment',
  ),
  EarningsRecord(
    jobId: 'Job #RM1025',
    transactionId: 'TXN-89410198',
    serviceType: 'Car Service',
    customerName: 'Amaya D.',
    serviceCharge: 8000,
    platformFee: 800,
    netEarnings: 7200,
    paymentStatus: 'Completed',
    completedDate: _mockDate(1, 4), // Yesterday (This week)
    notes: 'Standard engine diagnostic & fluid top-up',
  ),
  EarningsRecord(
    jobId: 'Job #RM1022',
    transactionId: 'TXN-89410102',
    serviceType: 'Battery Jump Start',
    customerName: 'Pradeep R.',
    serviceCharge: 3500,
    platformFee: 350,
    netEarnings: 3150,
    paymentStatus: 'Completed',
    completedDate: _mockDate(2, 6), // 2 days ago (This week)
    notes: 'Heavy-duty booster pack jumpstart',
  ),
  EarningsRecord(
    jobId: '#RM-1012',
    transactionId: 'TXN-89409987',
    serviceType: 'Emergency Towing',
    customerName: 'Saman W.',
    serviceCharge: 8500,
    platformFee: 850,
    netEarnings: 7650,
    paymentStatus: 'Completed',
    completedDate: _mockDate(5, 3), // Earlier this week / month
    notes: 'Flatbed tow to authorized service center',
  ),
  EarningsRecord(
    jobId: '#RM-1005',
    transactionId: 'TXN-89409850',
    serviceType: 'Fuel Delivery',
    customerName: 'Lahiru M.',
    serviceCharge: 3000,
    platformFee: 300,
    netEarnings: 2700,
    paymentStatus: 'Completed',
    completedDate: _mockDate(12, 1), // Earlier this month
    notes: '5L octane 95 fuel delivered',
  ),
];

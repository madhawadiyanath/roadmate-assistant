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
  });

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
      };

  factory EarningsRecord.fromMap(Map<String, dynamic> data, String id) {
    DateTime parsedDate = DateTime.now();
    final cdVal = data['completedDate'];
    if (cdVal is Timestamp) {
      parsedDate = cdVal.toDate();
    } else if (cdVal is String) {
      parsedDate = DateTime.tryParse(cdVal) ?? DateTime.now();
    }

    return EarningsRecord(
      jobId: data['jobId'] as String? ?? id,
      transactionId: data['transactionId'] as String? ?? '',
      serviceType: data['serviceType'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      serviceCharge: (data['serviceCharge'] as num?)?.toDouble() ?? 0.0,
      platformFee: (data['platformFee'] as num?)?.toDouble() ?? 0.0,
      netEarnings: (data['netEarnings'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: data['paymentStatus'] as String? ?? 'Completed',
      completedDate: parsedDate,
      mechanicUid: data['mechanicUid'] as String? ?? '',
    );
  }

  factory EarningsRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return EarningsRecord.fromMap(data, doc.id);
  }
}

/// Mock earnings data.
List<EarningsRecord> mockEarnings = [
  EarningsRecord(
    jobId: 'Job #RM1028',
    transactionId: 'TXN-89410284',
    serviceType: 'Tire & Wheel Service',
    customerName: 'Kasun J.',
    serviceCharge: 3500,
    platformFee: 0,
    netEarnings: 3500,
    paymentStatus: 'Completed',
    completedDate: DateTime(2026, 7, 12, 10, 24),
  ),
  EarningsRecord(
    jobId: 'Job #RM1025',
    transactionId: 'TXN-89410198',
    serviceType: 'Car Service',
    customerName: 'Amaya D.',
    serviceCharge: 8000,
    platformFee: 0,
    netEarnings: 8000,
    paymentStatus: 'Completed',
    completedDate: DateTime(2026, 7, 11, 14, 15),
  ),
  EarningsRecord(
    jobId: 'Job #RM1022',
    transactionId: 'TXN-89410102',
    serviceType: 'Battery Jump Start',
    customerName: 'Pradeep R.',
    serviceCharge: 2500,
    platformFee: 0,
    netEarnings: 2500,
    paymentStatus: 'Completed',
    completedDate: DateTime(2026, 7, 10, 16, 45),
  ),
  EarningsRecord(
    jobId: '#RM-1012',
    transactionId: 'TXN-89409987',
    serviceType: 'Fuel Drop',
    customerName: 'Saman W.',
    serviceCharge: 4200,
    platformFee: 420,
    netEarnings: 3780,
    paymentStatus: 'Pending',
    completedDate: DateTime(2026, 6, 20, 14, 0),
  ),
  EarningsRecord(
    jobId: '#RM-1005',
    transactionId: 'TXN-89409850',
    serviceType: 'Jump Start',
    customerName: 'Lahiru M.',
    serviceCharge: 2700,
    platformFee: 270,
    netEarnings: 2430,
    paymentStatus: 'Completed',
    completedDate: DateTime(2026, 6, 15, 7, 30),
  ),
];

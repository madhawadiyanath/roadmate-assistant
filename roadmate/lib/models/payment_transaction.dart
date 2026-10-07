import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single payment / earning transaction.
enum TransactionStatus {
  completed,
  pending,
  failed,
  refunded;

  static TransactionStatus fromString(String? val) {
    return switch (val) {
      'pending' => TransactionStatus.pending,
      'failed' => TransactionStatus.failed,
      'refunded' => TransactionStatus.refunded,
      _ => TransactionStatus.completed,
    };
  }
}

class PaymentTransaction {
  final String transactionId;
  final String jobId;
  final String serviceType;
  final String serviceProvider;
  final double serviceCharge;
  final double additionalCharges;
  final double platformFee;
  final double totalAmount;
  final String paymentMethod;
  final TransactionStatus status;
  final DateTime dateTime;
  final String customerName;
  final String vehicleInfo;
  final double distance;
  final String driverUid;

  PaymentTransaction({
    required this.transactionId,
    required this.jobId,
    required this.serviceType,
    this.serviceProvider = '',
    this.serviceCharge = 0,
    this.additionalCharges = 0,
    this.platformFee = 0,
    required this.totalAmount,
    this.paymentMethod = 'Mastercard •••• 4242',
    required this.status,
    DateTime? dateTime,
    this.customerName = '',
    this.vehicleInfo = '',
    this.distance = 0,
    this.driverUid = '',
  }) : dateTime = dateTime ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'transactionId': transactionId,
        'jobId': jobId,
        'serviceType': serviceType,
        'serviceProvider': serviceProvider,
        'serviceCharge': serviceCharge,
        'additionalCharges': additionalCharges,
        'platformFee': platformFee,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'status': status.name,
        'dateTime': Timestamp.fromDate(dateTime),
        'customerName': customerName,
        'vehicleInfo': vehicleInfo,
        'distance': distance,
        'driverUid': driverUid,
      };

  factory PaymentTransaction.fromMap(Map<String, dynamic> data, String id) {
    DateTime parsedDate = DateTime.now();
    final dtVal = data['dateTime'];
    if (dtVal is Timestamp) {
      parsedDate = dtVal.toDate();
    } else if (dtVal is String) {
      parsedDate = DateTime.tryParse(dtVal) ?? DateTime.now();
    }

    return PaymentTransaction(
      transactionId: data['transactionId'] as String? ?? id,
      jobId: data['jobId'] as String? ?? '',
      serviceType: data['serviceType'] as String? ?? '',
      serviceProvider: data['serviceProvider'] as String? ?? '',
      serviceCharge: (data['serviceCharge'] as num?)?.toDouble() ?? 0.0,
      additionalCharges: (data['additionalCharges'] as num?)?.toDouble() ?? 0.0,
      platformFee: (data['platformFee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] as String? ?? 'Card',
      status: TransactionStatus.fromString(data['status'] as String?),
      dateTime: parsedDate,
      customerName: data['customerName'] as String? ?? '',
      vehicleInfo: data['vehicleInfo'] as String? ?? '',
      distance: (data['distance'] as num?)?.toDouble() ?? 0.0,
      driverUid: data['driverUid'] as String? ?? '',
    );
  }

  factory PaymentTransaction.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PaymentTransaction.fromMap(data, doc.id);
  }

  String get date {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final m = months[dateTime.month - 1];
    final d = dateTime.day.toString().padLeft(2, '0');
    final y = dateTime.year;
    final hr = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final min = dateTime.minute.toString().padLeft(2, '0');
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$m $d, $y • $hr:$min $ampm';
  }

  String get statusLabel => switch (status) {
        TransactionStatus.completed => 'Completed',
        TransactionStatus.pending => 'Pending',
        TransactionStatus.failed => 'Failed',
        TransactionStatus.refunded => 'Refunded',
      };
}

/// Mock transaction history data.
List<PaymentTransaction> mockTransactions = [
  PaymentTransaction(
    transactionId: 'TXN-89410284',
    jobId: '#RM-1029',
    serviceType: 'Battery Jump Start',
    serviceProvider: 'Nimal Bandara',
    serviceCharge: 2000,
    additionalCharges: 800,
    platformFee: 200,
    totalAmount: 3500,
    paymentMethod: 'Mastercard •••• 4242',
    status: TransactionStatus.completed,
    dateTime: DateTime(2026, 7, 14, 15, 45),
    customerName: 'Kasun Jayawardena',
    vehicleInfo: 'Toyota Aqua • WP CAB-8921',
    distance: 12.4,
  ),
  PaymentTransaction(
    transactionId: 'TXN-89410198',
    jobId: '#RM-1024',
    serviceType: 'Flat Tyre',
    serviceProvider: 'Suresh Perera',
    serviceCharge: 2800,
    additionalCharges: 500,
    platformFee: 200,
    totalAmount: 3500,
    paymentMethod: 'Visa •••• 8921',
    status: TransactionStatus.completed,
    dateTime: DateTime(2026, 7, 10, 9, 30),
    customerName: 'Kasun Jayawardena',
    vehicleInfo: 'Toyota Aqua • WP CAB-8921',
    distance: 8.2,
  ),
  PaymentTransaction(
    transactionId: 'TXN-89410102',
    jobId: '#RM-1018',
    serviceType: 'Towing Service',
    serviceProvider: 'Amal Fernando',
    serviceCharge: 2800,
    additionalCharges: 5700,
    platformFee: 300,
    totalAmount: 8800,
    paymentMethod: 'Cash on Service',
    status: TransactionStatus.completed,
    dateTime: DateTime(2026, 6, 28, 22, 15),
    customerName: 'Kasun Jayawardena',
    vehicleInfo: 'Toyota Aqua • WP CAB-8921',
    distance: 25.6,
  ),
  PaymentTransaction(
    transactionId: 'TXN-89409987',
    jobId: '#RM-1012',
    serviceType: 'Fuel Drop',
    serviceProvider: 'Ravindu Silva',
    serviceCharge: 3200,
    additionalCharges: 800,
    platformFee: 200,
    totalAmount: 4200,
    paymentMethod: 'RoadMate Wallet',
    status: TransactionStatus.pending,
    dateTime: DateTime(2026, 6, 20, 14, 0),
    customerName: 'Kasun Jayawardena',
    vehicleInfo: 'Toyota Aqua • WP CAB-8921',
    distance: 15.1,
  ),
  PaymentTransaction(
    transactionId: 'TXN-89409850',
    jobId: '#RM-1005',
    serviceType: 'Jump Start',
    serviceProvider: 'Dilshan Kumara',
    serviceCharge: 1800,
    additionalCharges: 700,
    platformFee: 200,
    totalAmount: 2700,
    paymentMethod: 'Mastercard •••• 4242',
    status: TransactionStatus.completed,
    dateTime: DateTime(2026, 6, 15, 7, 30),
    customerName: 'Kasun Jayawardena',
    vehicleInfo: 'Toyota Aqua • WP CAB-8921',
    distance: 5.3,
  ),
];

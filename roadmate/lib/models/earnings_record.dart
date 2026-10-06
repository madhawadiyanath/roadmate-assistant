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
  });
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

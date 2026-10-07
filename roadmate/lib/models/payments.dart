import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_transaction.dart';

/// Saved payment method in `users/{uid}/paymentMethods/{id}`.
/// Only metadata is stored — never full card numbers.
class SavedMethod {
  final String id;
  final String kind;
  final String label;
  final String detail;
  final bool isDefault;

  const SavedMethod({
    required this.id,
    required this.kind,
    required this.label,
    required this.detail,
    this.isDefault = false,
  });

  /// `cardNumber` keeps only the last 4 digits.
  factory SavedMethod.card({
    required String id,
    required String cardNumber,
    required String expiry,
    bool isDefault = false,
  }) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    final last4 = digits.length <= 4 ? digits : digits.substring(digits.length - 4);
    return SavedMethod(
      id: id,
      kind: 'card',
      label: 'Card •• $last4',
      detail: 'VISA Exp $expiry',
      isDefault: isDefault,
    );
  }

  Map<String, dynamic> toMap() => {
        'kind': kind,
        'label': label,
        'detail': detail,
        'isDefault': isDefault,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory SavedMethod.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return SavedMethod(
      id: doc.id,
      kind: (m['kind'] ?? 'card') as String,
      label: (m['label'] ?? '') as String,
      detail: (m['detail'] ?? '') as String,
      isDefault: (m['isDefault'] ?? false) as bool,
    );
  }
}

/// One line on a receipt/invoice.
class FeeLine {
  final String label;
  final double amount;
  const FeeLine(this.label, this.amount);

  Map<String, dynamic> toMap() => {'label': label, 'amount': amount};

  factory FeeLine.fromMap(Map<String, dynamic> m) => FeeLine(
        (m['label'] ?? '') as String,
        ((m['amount'] ?? 0) as num).toDouble(),
      );
}

/// Money movement in the top-level `transactions` collection.
/// Card payments are `paid` at once; cash stays `pending` until the
/// mechanic collects it on completion.
class TxnRecord {
  final String id;
  final String requestId;
  final String refCode;
  final String type;
  final String payerUid;
  final String payerName;
  final String payeeUid;
  final String payeeName;
  final double amount;
  final String method;
  final String status;
  final List<FeeLine> items;
  final DateTime? createdAt;

  const TxnRecord({
    required this.id,
    required this.requestId,
    required this.refCode,
    required this.type,
    required this.payerUid,
    required this.payerName,
    this.payeeUid = '',
    this.payeeName = '',
    required this.amount,
    required this.method,
    this.status = 'pending',
    this.items = const [],
    this.createdAt,
  });

  bool get isPaid => status == 'paid';

  Map<String, dynamic> toMap() => {
        'requestId': requestId,
        'refCode': refCode,
        'type': type,
        'payerUid': payerUid,
        'payerName': payerName,
        'payeeUid': payeeUid,
        'payeeName': payeeName,
        'amount': amount,
        'method': method,
        'status': status,
        'items': items.map((e) => e.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory TxnRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    final rawItems = (m['items'] as List?) ?? [];
    return TxnRecord(
      id: doc.id,
      requestId: (m['requestId'] ?? '') as String,
      refCode: (m['refCode'] ?? '') as String,
      type: (m['type'] ?? '') as String,
      payerUid: (m['payerUid'] ?? '') as String,
      payerName: (m['payerName'] ?? '') as String,
      payeeUid: (m['payeeUid'] ?? '') as String,
      payeeName: (m['payeeName'] ?? '') as String,
      amount: ((m['amount'] ?? 0) as num).toDouble(),
      method: (m['method'] ?? '') as String,
      status: (m['status'] ?? 'pending') as String,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(FeeLine.fromMap)
          .toList(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  PaymentTransaction toPaymentTransaction() {
    return PaymentTransaction(
      transactionId: id.isNotEmpty ? id : refCode,
      jobId: requestId.isNotEmpty ? requestId : refCode,
      serviceType: type,
      serviceProvider: payeeName.isNotEmpty ? payeeName : 'RoadMate Patrol Specialist',
      totalAmount: amount,
      paymentMethod: method,
      status: isPaid ? TransactionStatus.completed : TransactionStatus.pending,
      customerName: payerName,
      dateTime: createdAt ?? DateTime.now(),
      serviceCharge: items.isNotEmpty ? items.first.amount : amount,
      additionalCharges: items.length > 1
          ? items.sublist(1).fold(0.0, (s, i) => s + i.amount)
          : 0.0,
      driverUid: payerUid,
    );
  }
}

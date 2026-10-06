import 'package:cloud_firestore/cloud_firestore.dart';

/// A saved payment method (card, wallet, cash).
enum PaymentMethodType {
  card,
  wallet,
  cash;

  static PaymentMethodType fromString(String? val) {
    return switch (val) {
      'wallet' => PaymentMethodType.wallet,
      'cash' => PaymentMethodType.cash,
      _ => PaymentMethodType.card,
    };
  }
}

class PaymentMethod {
  final String id;
  final PaymentMethodType type;
  final String label;
  final String subtitle;
  final String last4;
  final String brand; // Visa, Mastercard, etc.
  final String expiryMonth;
  final String expiryYear;
  final String holderName;
  final bool isDefault;
  final double balance;

  const PaymentMethod({
    required this.id,
    required this.type,
    this.label = '',
    this.subtitle = '',
    this.last4 = '',
    this.brand = '',
    this.expiryMonth = '',
    this.expiryYear = '',
    this.holderName = '',
    this.isDefault = false,
    this.balance = 0.0,
  });

  String get maskedNumber => '•••• $last4';
  String get expiry => (expiryMonth.isNotEmpty && expiryYear.isNotEmpty)
      ? '${expiryMonth.padLeft(2, '0')}/$expiryYear'
      : '';

  double get walletBalance {
    if (balance > 0) return balance;
    final match = RegExp(r'Rs\.?\s*([\d,]+(?:\.\d+)?)').firstMatch(subtitle);
    if (match != null) {
      final str = match.group(1)!.replaceAll(',', '');
      return double.tryParse(str) ?? 0.0;
    }
    return balance;
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'label': label,
        'subtitle': subtitle,
        'last4': last4,
        'brand': brand,
        'expiryMonth': expiryMonth,
        'expiryYear': expiryYear,
        'holderName': holderName,
        'isDefault': isDefault,
        'balance': balance > 0 ? balance : walletBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory PaymentMethod.fromMap(Map<String, dynamic> data, String id) {
    return PaymentMethod(
      id: id,
      type: PaymentMethodType.fromString(data['type'] as String?),
      label: data['label'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      last4: data['last4'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
      expiryMonth: data['expiryMonth'] as String? ?? '',
      expiryYear: data['expiryYear'] as String? ?? '',
      holderName: data['holderName'] as String? ?? '',
      isDefault: data['isDefault'] as bool? ?? false,
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory PaymentMethod.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PaymentMethod.fromMap(data, doc.id);
  }

  PaymentMethod copyWith({
    String? id,
    PaymentMethodType? type,
    String? label,
    String? subtitle,
    String? last4,
    String? brand,
    String? expiryMonth,
    String? expiryYear,
    String? holderName,
    bool? isDefault,
    double? balance,
  }) =>
      PaymentMethod(
        id: id ?? this.id,
        type: type ?? this.type,
        label: label ?? this.label,
        subtitle: subtitle ?? this.subtitle,
        last4: last4 ?? this.last4,
        brand: brand ?? this.brand,
        expiryMonth: expiryMonth ?? this.expiryMonth,
        expiryYear: expiryYear ?? this.expiryYear,
        holderName: holderName ?? this.holderName,
        isDefault: isDefault ?? this.isDefault,
        balance: balance ?? this.balance,
      );
}

/// Action result returned when returning from EditCardScreen.
enum CardActionType { updated, removed }

class CardActionResult {
  final CardActionType type;
  final PaymentMethod? card;
  final String cardId;

  CardActionResult.updated(PaymentMethod this.card)
      : type = CardActionType.updated,
        cardId = card.id;

  const CardActionResult.removed(this.cardId)
      : type = CardActionType.removed,
        card = null;
}

/// Mock data for payment methods.
List<PaymentMethod> mockPaymentMethods = [
  const PaymentMethod(
    id: 'card_1',
    type: PaymentMethodType.card,
    label: 'Mastercard',
    last4: '4242',
    brand: 'Mastercard',
    expiryMonth: '12',
    expiryYear: '28',
    holderName: 'Kasun Jayawardena',
    isDefault: true,
  ),
  const PaymentMethod(
    id: 'card_2',
    type: PaymentMethodType.card,
    label: 'Visa',
    last4: '8921',
    brand: 'Visa',
    expiryMonth: '08',
    expiryYear: '27',
    holderName: 'Kasun Jayawardena',
    isDefault: false,
  ),
  const PaymentMethod(
    id: 'card_3',
    type: PaymentMethodType.card,
    label: 'Mastercard',
    last4: '1111',
    brand: 'Mastercard',
    expiryMonth: '03',
    expiryYear: '29',
    holderName: 'Kasun Jayawardena',
    isDefault: false,
  ),
  const PaymentMethod(
    id: 'wallet_1',
    type: PaymentMethodType.wallet,
    label: 'RoadMate In-App Wallet',
    subtitle: 'Available Balance: Rs. 2,450.00',
    balance: 2450.00,
    isDefault: false,
  ),
  const PaymentMethod(
    id: 'cash_1',
    type: PaymentMethodType.cash,
    label: 'Cash on Service',
    subtitle: 'Pay directly to patrol specialist',
    isDefault: false,
  ),
];

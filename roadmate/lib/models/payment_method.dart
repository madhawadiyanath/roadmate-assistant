/// A saved payment method (card, wallet, cash).
enum PaymentMethodType { card, wallet, cash }

class PaymentMethod {
  final String id;
  final PaymentMethodType type;
  final String label;
  final String subtitle;
  final String last4;
  final String brand;       // Visa, Mastercard, etc.
  final String expiryMonth;
  final String expiryYear;
  final String holderName;
  final bool isDefault;

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
  });

  String get maskedNumber => '•••• $last4';
  String get expiry => '$expiryMonth/$expiryYear';

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
      );
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
    id: 'wallet_1',
    type: PaymentMethodType.wallet,
    label: 'RoadMate In-App Wallet',
    subtitle: 'Available Balance: Rs. 2,450.00',
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

import 'package:equatable/equatable.dart';

enum PaymentMethodType {
  razorpayFull('razorpay_full', 'Online Full Payment (Razorpay)'),
  codWithAdvance('cod_with_advance', 'Cash on Delivery (Minimum Advance)');

  final String value;
  final String label;
  const PaymentMethodType(this.value, this.label);

  static PaymentMethodType fromString(String val) {
    if (val == 'cod_with_advance') {
      return PaymentMethodType.codWithAdvance;
    }
    return PaymentMethodType.razorpayFull;
  }
}

class CreateOrderResponse extends Equatable {
  final String razorpayOrderId;
  final double amount;
  final int amountInPaise;
  final String currency;
  final String keyId;
  final String paymentId;
  final String bookingId;
  final String bookingCode;
  final String paymentMethod;
  final double advanceAmount;
  final double remainingCashAmount;
  final double totalBookingAmount;

  const CreateOrderResponse({
    required this.razorpayOrderId,
    required this.amount,
    required this.amountInPaise,
    required this.currency,
    required this.keyId,
    required this.paymentId,
    required this.bookingId,
    required this.bookingCode,
    required this.paymentMethod,
    required this.advanceAmount,
    required this.remainingCashAmount,
    required this.totalBookingAmount,
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) {
    return CreateOrderResponse(
      razorpayOrderId: json['razorpay_order_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      amountInPaise: (json['amount_in_paise'] as num).toInt(),
      currency: json['currency'] as String? ?? 'INR',
      keyId: json['key_id'] as String,
      paymentId: json['payment_id'] as String,
      bookingId: json['booking_id'] as String,
      bookingCode: json['booking_code'] as String,
      paymentMethod: json['payment_method'] as String,
      advanceAmount: (json['advance_amount'] as num).toDouble(),
      remainingCashAmount: (json['remaining_cash_amount'] as num).toDouble(),
      totalBookingAmount: (json['total_booking_amount'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        razorpayOrderId,
        amount,
        amountInPaise,
        currency,
        keyId,
        paymentId,
        bookingId,
        bookingCode,
        paymentMethod,
        advanceAmount,
        remainingCashAmount,
        totalBookingAmount,
      ];
}

class VerifyPaymentRequest {
  final String paymentId;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  const VerifyPaymentRequest({
    required this.paymentId,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    };
  }
}

class VerifyPaymentResponse extends Equatable {
  final bool success;
  final String message;
  final String paymentId;
  final String paymentStatus;
  final String bookingStatus;
  final double totalAmount;
  final double advanceAmount;
  final double remainingAmount;

  const VerifyPaymentResponse({
    required this.success,
    required this.message,
    required this.paymentId,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.totalAmount,
    required this.advanceAmount,
    required this.remainingAmount,
  });

  factory VerifyPaymentResponse.fromJson(Map<String, dynamic> json) {
    return VerifyPaymentResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? 'Payment verified successfully.',
      paymentId: json['payment_id'] as String,
      paymentStatus: json['payment_status'] as String,
      bookingStatus: json['booking_status'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      advanceAmount: (json['advance_amount'] as num).toDouble(),
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        success,
        message,
        paymentId,
        paymentStatus,
        bookingStatus,
        totalAmount,
        advanceAmount,
        remainingAmount,
      ];
}

class CashCollectionResponse extends Equatable {
  final bool success;
  final String message;
  final String bookingId;
  final String bookingCode;
  final bool cashCollected;
  final DateTime cashCollectedAt;
  final double remainingAmount;
  final String paymentStatus;

  const CashCollectionResponse({
    required this.success,
    required this.message,
    required this.bookingId,
    required this.bookingCode,
    required this.cashCollected,
    required this.cashCollectedAt,
    required this.remainingAmount,
    required this.paymentStatus,
  });

  factory CashCollectionResponse.fromJson(Map<String, dynamic> json) {
    return CashCollectionResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String,
      bookingId: json['booking_id'] as String,
      bookingCode: json['booking_code'] as String,
      cashCollected: json['cash_collected'] as bool? ?? true,
      cashCollectedAt: json['cash_collected_at'] != null
          ? DateTime.parse(json['cash_collected_at'] as String)
          : DateTime.now(),
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['payment_status'] as String? ?? 'paid',
    );
  }

  @override
  List<Object?> get props => [
        success,
        message,
        bookingId,
        bookingCode,
        cashCollected,
        cashCollectedAt,
        remainingAmount,
        paymentStatus,
      ];
}

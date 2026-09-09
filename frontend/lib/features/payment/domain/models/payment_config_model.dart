import 'package:equatable/equatable.dart';

class PaymentConfigModel extends Equatable {
  final bool codEnabled;
  final double codMinimumAdvance;
  final String currency;

  const PaymentConfigModel({
    required this.codEnabled,
    required this.codMinimumAdvance,
    this.currency = 'INR',
  });

  factory PaymentConfigModel.fromJson(Map<String, dynamic> json) {
    return PaymentConfigModel(
      codEnabled: json['cod_enabled'] as bool? ?? true,
      codMinimumAdvance: (json['cod_minimum_advance'] as num?)?.toDouble() ?? 100.0,
      currency: json['currency'] as String? ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cod_enabled': codEnabled,
      'cod_minimum_advance': codMinimumAdvance,
      'currency': currency,
    };
  }

  @override
  List<Object?> get props => [codEnabled, codMinimumAdvance, currency];
}

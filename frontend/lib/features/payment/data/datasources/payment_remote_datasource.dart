import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/core/constants/api_endpoints.dart';
import 'package:instant_reel/core/network/api_client.dart';
import 'package:instant_reel/features/payment/domain/models/payment_config_model.dart';
import 'package:instant_reel/features/payment/domain/models/payment_models.dart';

final paymentRemoteDataSourceProvider = Provider<PaymentRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PaymentRemoteDataSourceImpl(apiClient: apiClient);
});

abstract class PaymentRemoteDataSource {
  Future<PaymentConfigModel> fetchPaymentConfig();
  Future<CreateOrderResponse> createPaymentOrder({
    required String bookingId,
    required String paymentMethod,
  });
  Future<VerifyPaymentResponse> verifyPayment(VerifyPaymentRequest request);
  Future<CashCollectionResponse> collectCash({required String bookingId});
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final ApiClient _apiClient;

  PaymentRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<PaymentConfigModel> fetchPaymentConfig() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.paymentConfig,
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? response.data ?? {};
    return PaymentConfigModel.fromJson(data);
  }

  @override
  Future<CreateOrderResponse> createPaymentOrder({
    required String bookingId,
    required String paymentMethod,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.createPaymentOrder,
      data: {
        'booking_id': bookingId,
        'payment_method': paymentMethod,
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? response.data ?? {};
    return CreateOrderResponse.fromJson(data);
  }

  @override
  Future<VerifyPaymentResponse> verifyPayment(VerifyPaymentRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.verifyPayment,
      data: request.toJson(),
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? response.data ?? {};
    return VerifyPaymentResponse.fromJson(data);
  }

  @override
  Future<CashCollectionResponse> collectCash({required String bookingId}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.collectCash,
      data: {'booking_id': bookingId},
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? response.data ?? {};
    return CashCollectionResponse.fromJson(data);
  }
}

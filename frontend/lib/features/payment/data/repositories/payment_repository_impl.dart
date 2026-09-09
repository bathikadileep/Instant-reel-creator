import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:instant_reel/features/payment/domain/models/payment_config_model.dart';
import 'package:instant_reel/features/payment/domain/models/payment_models.dart';
import 'package:instant_reel/features/payment/domain/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final remoteDataSource = ref.watch(paymentRemoteDataSourceProvider);
  return PaymentRepositoryImpl(remoteDataSource: remoteDataSource);
});

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource _remoteDataSource;

  PaymentRepositoryImpl({required PaymentRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<PaymentConfigModel> getPaymentConfig() {
    return _remoteDataSource.fetchPaymentConfig();
  }

  @override
  Future<CreateOrderResponse> createPaymentOrder({
    required String bookingId,
    required String paymentMethod,
  }) {
    return _remoteDataSource.createPaymentOrder(
      bookingId: bookingId,
      paymentMethod: paymentMethod,
    );
  }

  @override
  Future<VerifyPaymentResponse> verifyPayment(VerifyPaymentRequest request) {
    return _remoteDataSource.verifyPayment(request);
  }

  @override
  Future<CashCollectionResponse> collectCash({required String bookingId}) {
    return _remoteDataSource.collectCash(bookingId: bookingId);
  }
}

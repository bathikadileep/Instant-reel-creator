import 'package:instant_reel/features/payment/domain/models/payment_config_model.dart';
import 'package:instant_reel/features/payment/domain/models/payment_models.dart';

abstract class PaymentRepository {
  Future<PaymentConfigModel> getPaymentConfig();
  Future<CreateOrderResponse> createPaymentOrder({
    required String bookingId,
    required String paymentMethod,
  });
  Future<VerifyPaymentResponse> verifyPayment(VerifyPaymentRequest request);
  Future<CashCollectionResponse> collectCash({required String bookingId});
}

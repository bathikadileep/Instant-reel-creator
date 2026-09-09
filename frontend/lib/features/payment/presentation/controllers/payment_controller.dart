import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/core/utils/logger.dart';
import 'package:instant_reel/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:instant_reel/features/payment/domain/models/payment_config_model.dart';
import 'package:instant_reel/features/payment/domain/models/payment_models.dart';
import 'package:instant_reel/features/payment/domain/repositories/payment_repository.dart';

class PaymentState extends Equatable {
  final bool isLoadingConfig;
  final PaymentConfigModel config;
  final PaymentMethodType selectedMethod;
  final bool isProcessingPayment;
  final CreateOrderResponse? activeOrder;
  final VerifyPaymentResponse? verificationResult;
  final CashCollectionResponse? cashCollectionResult;
  final String? errorMessage;
  final String? successMessage;

  const PaymentState({
    this.isLoadingConfig = false,
    this.config = const PaymentConfigModel(codEnabled: true, codMinimumAdvance: 100.0),
    this.selectedMethod = PaymentMethodType.razorpayFull,
    this.isProcessingPayment = false,
    this.activeOrder,
    this.verificationResult,
    this.cashCollectionResult,
    this.errorMessage,
    this.successMessage,
  });

  PaymentState copyWith({
    bool? isLoadingConfig,
    PaymentConfigModel? config,
    PaymentMethodType? selectedMethod,
    bool? isProcessingPayment,
    CreateOrderResponse? activeOrder,
    VerifyPaymentResponse? verificationResult,
    CashCollectionResponse? cashCollectionResult,
    String? errorMessage,
    String? successMessage,
    bool clearActiveOrder = false,
  }) {
    return PaymentState(
      isLoadingConfig: isLoadingConfig ?? this.isLoadingConfig,
      config: config ?? this.config,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      isProcessingPayment: isProcessingPayment ?? this.isProcessingPayment,
      activeOrder: clearActiveOrder ? null : (activeOrder ?? this.activeOrder),
      verificationResult: verificationResult ?? this.verificationResult,
      cashCollectionResult: cashCollectionResult ?? this.cashCollectionResult,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoadingConfig,
        config,
        selectedMethod,
        isProcessingPayment,
        activeOrder,
        verificationResult,
        cashCollectionResult,
        errorMessage,
        successMessage,
      ];
}

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, PaymentState>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return PaymentController(repository: repository);
});

class PaymentController extends StateNotifier<PaymentState> {
  final PaymentRepository _repository;

  PaymentController({required PaymentRepository repository})
      : _repository = repository,
        super(const PaymentState()) {
    loadConfig();
  }

  Future<void> loadConfig() async {
    state = state.copyWith(isLoadingConfig: true, errorMessage: null);
    try {
      final config = await _repository.getPaymentConfig();
      state = state.copyWith(
        isLoadingConfig: false,
        config: config,
      );
    } catch (e) {
      AppLogger.w('Using fallback payment config: $e');
      state = state.copyWith(
        isLoadingConfig: false,
      );
    }
  }

  void selectPaymentMethod(PaymentMethodType method) {
    state = state.copyWith(selectedMethod: method, errorMessage: null);
  }

  Future<CreateOrderResponse?> initiatePaymentOrder({
    required String bookingId,
  }) async {
    state = state.copyWith(
      isProcessingPayment: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      final order = await _repository.createPaymentOrder(
        bookingId: bookingId,
        paymentMethod: state.selectedMethod.value,
      );
      state = state.copyWith(
        isProcessingPayment: false,
        activeOrder: order,
      );
      return order;
    } catch (e) {
      AppLogger.e('Failed to create payment order: $e');
      state = state.copyWith(
        isProcessingPayment: false,
        errorMessage: 'Failed to initiate payment: $e',
      );
      return null;
    }
  }

  Future<VerifyPaymentResponse?> verifyPayment({
    required String paymentId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    state = state.copyWith(
      isProcessingPayment: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      final verifyResp = await _repository.verifyPayment(
        VerifyPaymentRequest(
          paymentId: paymentId,
          razorpayOrderId: razorpayOrderId,
          razorpayPaymentId: razorpayPaymentId,
          razorpaySignature: razorpaySignature,
        ),
      );
      state = state.copyWith(
        isProcessingPayment: false,
        verificationResult: verifyResp,
        successMessage: verifyResp.message,
        clearActiveOrder: true,
      );
      return verifyResp;
    } catch (e) {
      AppLogger.e('Payment verification failed: $e');
      state = state.copyWith(
        isProcessingPayment: false,
        errorMessage: 'Payment verification failed: $e',
      );
      return null;
    }
  }

  Future<CashCollectionResponse?> collectCash({
    required String bookingId,
  }) async {
    state = state.copyWith(
      isProcessingPayment: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      final response = await _repository.collectCash(bookingId: bookingId);
      state = state.copyWith(
        isProcessingPayment: false,
        cashCollectionResult: response,
        successMessage: response.message,
      );
      return response;
    } catch (e) {
      AppLogger.e('Cash collection failed: $e');
      state = state.copyWith(
        isProcessingPayment: false,
        errorMessage: 'Cash collection failed: $e',
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/core/utils/logger.dart';
import 'package:instant_reel/features/customer/data/repositories/customer_booking_repository_impl.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';
import 'package:instant_reel/features/customer/domain/repositories/customer_booking_repository.dart';

class CustomerDashboardState extends Equatable {
  final int selectedTabIndex;
  final bool isLoading;
  final List<BookingModel> activeBookings;
  final List<BookingModel> bookingHistory;
  final String? errorMessage;

  const CustomerDashboardState({
    this.selectedTabIndex = 0,
    this.isLoading = false,
    this.activeBookings = const [],
    this.bookingHistory = const [],
    this.errorMessage,
  });

  CustomerDashboardState copyWith({
    int? selectedTabIndex,
    bool? isLoading,
    List<BookingModel>? activeBookings,
    List<BookingModel>? bookingHistory,
    String? errorMessage,
  }) {
    return CustomerDashboardState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      isLoading: isLoading ?? this.isLoading,
      activeBookings: activeBookings ?? this.activeBookings,
      bookingHistory: bookingHistory ?? this.bookingHistory,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        selectedTabIndex,
        isLoading,
        activeBookings,
        bookingHistory,
        errorMessage,
      ];
}

final customerDashboardControllerProvider = StateNotifierProvider<
    CustomerDashboardController, CustomerDashboardState>((ref) {
  final repository = ref.watch(customerBookingRepositoryProvider);
  return CustomerDashboardController(repository: repository);
});

class CustomerDashboardController
    extends StateNotifier<CustomerDashboardState> {
  final CustomerBookingRepository _repository;

  CustomerDashboardController({required CustomerBookingRepository repository})
      : _repository = repository,
        super(const CustomerDashboardState()) {
    refreshData();
  }

  void setTab(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }

  Future<void> refreshData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final active = await _repository.getActiveBookings();
      final history = await _repository.getBookingHistory();

      state = state.copyWith(
        isLoading: false,
        activeBookings: active,
        bookingHistory: history,
      );
    } catch (e) {
      AppLogger.e('Failed to load dashboard bookings: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to refresh bookings. Please retry.',
      );
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _repository.cancelBooking(bookingId);
      await refreshData();
      return true;
    } catch (e) {
      AppLogger.e('Failed to cancel booking: $e');
      return false;
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/features/booking_management/data/repositories/booking_management_repository_impl.dart';
import 'package:instant_reel/features/booking_management/domain/models/booking_filter_params.dart';
import 'package:instant_reel/features/booking_management/domain/repositories/booking_management_repository.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';

class BookingHistoryState {
  final AsyncValue<List<BookingModel>> bookings;
  final String activeTab; // 'all', 'active', 'completed', 'cancelled'
  final String? selectedCity;
  final String searchQuery;

  const BookingHistoryState({
    required this.bookings,
    this.activeTab = 'all',
    this.selectedCity,
    this.searchQuery = '',
  });

  BookingHistoryState copyWith({
    AsyncValue<List<BookingModel>>? bookings,
    String? activeTab,
    String? selectedCity,
    String? searchQuery,
  }) {
    return BookingHistoryState(
      bookings: bookings ?? this.bookings,
      activeTab: activeTab ?? this.activeTab,
      selectedCity: selectedCity ?? this.selectedCity,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final bookingHistoryControllerProvider =
    StateNotifierProvider.autoDispose<BookingHistoryController, BookingHistoryState>((ref) {
  final repository = ref.watch(bookingManagementRepositoryProvider);
  return BookingHistoryController(repository);
});

class BookingHistoryController extends StateNotifier<BookingHistoryState> {
  final BookingManagementRepository _repository;

  BookingHistoryController(this._repository)
      : super(const BookingHistoryState(bookings: AsyncValue.loading())) {
    loadBookings();
  }

  Future<void> loadBookings() async {
    state = state.copyWith(bookings: const AsyncValue.loading());
    try {
      String? statusFilter;
      if (state.activeTab == 'active') {
        // Handled by active bookings or status filter
      } else if (state.activeTab == 'completed') {
        statusFilter = 'delivered';
      } else if (state.activeTab == 'cancelled') {
        statusFilter = 'cancelled';
      }

      final params = BookingFilterParams(
        status: statusFilter,
        city: state.selectedCity,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      final list = await _repository.listBookings(params: params);
      state = state.copyWith(bookings: AsyncValue.data(list));
    } catch (e, st) {
      state = state.copyWith(bookings: AsyncValue.error(e, st));
    }
  }

  void setTab(String tab) {
    if (state.activeTab == tab) return;
    state = state.copyWith(activeTab: tab);
    loadBookings();
  }

  void setCity(String? city) {
    if (state.selectedCity == city) return;
    state = state.copyWith(selectedCity: city);
    loadBookings();
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
    loadBookings();
  }

  Future<void> refresh() async {
    await loadBookings();
  }
}

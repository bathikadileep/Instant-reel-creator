import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/features/booking_management/data/repositories/booking_management_repository_impl.dart';
import 'package:instant_reel/features/booking_management/domain/models/booking_timeline_model.dart';
import 'package:instant_reel/features/booking_management/domain/repositories/booking_management_repository.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';

class BookingDetailState {
  final AsyncValue<BookingModel> booking;
  final AsyncValue<BookingTimelineModel> timeline;
  final bool isCancelling;
  final bool isAssigning;
  final String? errorMessage;
  final String? successMessage;

  const BookingDetailState({
    required this.booking,
    required this.timeline,
    this.isCancelling = false,
    this.isAssigning = false,
    this.errorMessage,
    this.successMessage,
  });

  BookingDetailState copyWith({
    AsyncValue<BookingModel>? booking,
    AsyncValue<BookingTimelineModel>? timeline,
    bool? isCancelling,
    bool? isAssigning,
    String? errorMessage,
    String? successMessage,
  }) {
    return BookingDetailState(
      booking: booking ?? this.booking,
      timeline: timeline ?? this.timeline,
      isCancelling: isCancelling ?? this.isCancelling,
      isAssigning: isAssigning ?? this.isAssigning,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

final bookingDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<BookingDetailController, BookingDetailState, String>((ref, bookingId) {
  final repository = ref.watch(bookingManagementRepositoryProvider);
  return BookingDetailController(repository, bookingId);
});

class BookingDetailController extends StateNotifier<BookingDetailState> {
  final BookingManagementRepository _repository;
  final String _bookingId;

  BookingDetailController(this._repository, this._bookingId)
      : super(const BookingDetailState(
          booking: AsyncValue.loading(),
          timeline: AsyncValue.loading(),
        )) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(
      booking: const AsyncValue.loading(),
      timeline: const AsyncValue.loading(),
      errorMessage: null,
    );

    try {
      final bookingFuture = _repository.getBookingDetail(_bookingId);
      final timelineFuture = _repository.getTimeline(_bookingId);

      final results = await Future.wait([bookingFuture, timelineFuture]);
      state = state.copyWith(
        booking: AsyncValue.data(results[0] as BookingModel),
        timeline: AsyncValue.data(results[1] as BookingTimelineModel),
      );
    } catch (e, st) {
      state = state.copyWith(
        booking: AsyncValue.error(e, st),
        timeline: AsyncValue.error(e, st),
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> cancelBooking({required String reason, String? note}) async {
    state = state.copyWith(isCancelling: true, errorMessage: null);
    try {
      final updated = await _repository.cancelBooking(
        _bookingId,
        reason: reason,
        note: note,
      );
      final timeline = await _repository.getTimeline(_bookingId);
      state = state.copyWith(
        booking: AsyncValue.data(updated),
        timeline: AsyncValue.data(timeline),
        isCancelling: false,
        successMessage: 'Booking cancelled successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isCancelling: false,
        errorMessage: 'Failed to cancel booking: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> assignCreator({required String creatorId, String? note}) async {
    state = state.copyWith(isAssigning: true, errorMessage: null);
    try {
      final updated = await _repository.assignCreator(
        _bookingId,
        creatorId: creatorId,
        note: note,
      );
      final timeline = await _repository.getTimeline(_bookingId);
      state = state.copyWith(
        booking: AsyncValue.data(updated),
        timeline: AsyncValue.data(timeline),
        isAssigning: false,
        successMessage: 'Creator assigned successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isAssigning: false,
        errorMessage: 'Failed to assign creator: ${e.toString()}',
      );
      return false;
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/features/creator/data/repositories/creator_repository_impl.dart';
import 'package:instant_reel/features/creator/domain/models/creator_booking_status.dart';
import 'package:instant_reel/features/creator/domain/repositories/creator_repository.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';

class CreatorWorkflowState {
  final AsyncValue<BookingModel> booking;
  final bool isActionLoading;
  final String? successMessage;
  final String? error;

  const CreatorWorkflowState({
    required this.booking,
    this.isActionLoading = false,
    this.successMessage,
    this.error,
  });

  CreatorWorkflowState copyWith({
    AsyncValue<BookingModel>? booking,
    bool? isActionLoading,
    String? successMessage,
    String? error,
  }) {
    return CreatorWorkflowState(
      booking: booking ?? this.booking,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      successMessage: successMessage,
      error: error,
    );
  }
}

final creatorWorkflowControllerProvider = StateNotifierProvider.autoDispose
    .family<CreatorWorkflowController, CreatorWorkflowState, String>((ref, bookingId) {
  final repository = ref.watch(creatorRepositoryProvider);
  return CreatorWorkflowController(repository, bookingId);
});

class CreatorWorkflowController extends StateNotifier<CreatorWorkflowState> {
  final CreatorRepository _repository;
  final String _bookingId;

  CreatorWorkflowController(this._repository, this._bookingId)
      : super(const CreatorWorkflowState(booking: AsyncValue.loading())) {
    loadBooking();
  }

  Future<void> loadBooking() async {
    state = state.copyWith(booking: const AsyncValue.loading(), error: null);
    try {
      final booking = await _repository.getBookingDetail(_bookingId);
      state = state.copyWith(booking: AsyncValue.data(booking));
    } catch (e, st) {
      state = state.copyWith(
        booking: AsyncValue.error(e, st),
        error: e.toString(),
      );
    }
  }

  Future<bool> acceptBooking() async {
    state = state.copyWith(isActionLoading: true, error: null);
    try {
      final updated = await _repository.acceptBooking(_bookingId);
      state = state.copyWith(
        booking: AsyncValue.data(updated),
        isActionLoading: false,
        successMessage: 'Booking accepted! Prepare for the shoot.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        error: 'Failed to accept booking: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> rejectBooking({String? reason}) async {
    state = state.copyWith(isActionLoading: true, error: null);
    try {
      final updated = await _repository.rejectBooking(_bookingId, reason: reason);
      state = state.copyWith(
        booking: AsyncValue.data(updated),
        isActionLoading: false,
        successMessage: 'Booking declined and released back to available pool.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        error: 'Failed to decline booking: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> advanceToNextStatus({String? note, String? reelUrl}) async {
    final current = state.booking.valueOrNull;
    if (current == null) return false;

    final currentWorkflow = CreatorWorkflowStatus.fromString(current.status.toApiString());
    final nextWorkflow = currentWorkflow.nextStatus;
    if (nextWorkflow == null) return false;

    state = state.copyWith(isActionLoading: true, error: null);
    try {
      final updated = await _repository.updateStatus(
        _bookingId,
        status: nextWorkflow.value,
        note: note,
        reelUrl: reelUrl,
      );
      state = state.copyWith(
        booking: AsyncValue.data(updated),
        isActionLoading: false,
        successMessage: 'Status updated to ${nextWorkflow.title}',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        error: 'Failed to advance status: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> deliverReel({required String reelUrl, String? note}) async {
    state = state.copyWith(isActionLoading: true, error: null);
    try {
      final updated = await _repository.deliverReel(
        _bookingId,
        reelUrl: reelUrl,
        note: note,
      );
      state = state.copyWith(
        booking: AsyncValue.data(updated),
        isActionLoading: false,
        successMessage: 'Reel delivered successfully to customer!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        error: 'Failed to deliver reel: ${e.toString()}',
      );
      return false;
    }
  }

  Future<Map<String, dynamic>?> sendReelOnWhatsApp() async {
    state = state.copyWith(isActionLoading: true, error: null);
    try {
      final res = await _repository.sendReel(_bookingId);
      final refreshed = await _repository.getBookingDetail(_bookingId);
      state = state.copyWith(
        booking: AsyncValue.data(refreshed),
        isActionLoading: false,
        successMessage: 'Opening WhatsApp chat to send 4K reel...',
      );
      return res;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        error: 'Failed to initiate WhatsApp delivery: ${e.toString()}',
      );
      return null;
    }
  }

  Future<bool> markDelivered({String? note}) async {
    state = state.copyWith(isActionLoading: true, error: null);
    try {
      final updated = await _repository.markDelivered(_bookingId, note: note);
      state = state.copyWith(
        booking: AsyncValue.data(updated),
        isActionLoading: false,
        successMessage: 'Reel delivery confirmed! Booking marked as delivered.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        error: 'Failed to mark delivered: ${e.toString()}',
      );
      return false;
    }
  }
}

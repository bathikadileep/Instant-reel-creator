import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/core/utils/logger.dart';
import 'package:instant_reel/features/customer/data/repositories/customer_booking_repository_impl.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';
import 'package:instant_reel/features/customer/domain/models/event_type.dart';
import 'package:instant_reel/features/customer/domain/models/package_model.dart';
import 'package:instant_reel/features/customer/domain/repositories/customer_booking_repository.dart';

class BookingFlowState extends Equatable {
  final int currentStep; // 1 to 5
  final bool isLoadingPackages;
  final List<PackageModel> packages;
  final EventType? selectedEventType;
  final PackageModel? selectedPackage;
  final String selectedCity;
  final String locationAddress;
  final DateTime? scheduledDate;
  final String? scheduledTimeSlot;
  final String customerWhatsapp;
  final String notes;
  final bool isSubmitting;
  final BookingModel? createdBooking;
  final String? errorMessage;

  const BookingFlowState({
    this.currentStep = 1,
    this.isLoadingPackages = false,
    this.packages = const [],
    this.selectedEventType = EventType.shopPromotion,
    this.selectedPackage,
    this.selectedCity = 'Khammam',
    this.locationAddress = '',
    this.scheduledDate,
    this.scheduledTimeSlot = '11:00 AM',
    this.customerWhatsapp = '',
    this.notes = '',
    this.isSubmitting = false,
    this.createdBooking,
    this.errorMessage,
  });

  bool get canProceedStep1 => selectedEventType != null;
  bool get canProceedStep2 => selectedPackage != null;
  bool get canProceedStep3 =>
      selectedCity.isNotEmpty && locationAddress.trim().length >= 5;
  bool get canProceedStep4 =>
      scheduledDate != null &&
      scheduledTimeSlot != null &&
      customerWhatsapp.trim().length >= 10;

  BookingFlowState copyWith({
    int? currentStep,
    bool? isLoadingPackages,
    List<PackageModel>? packages,
    EventType? selectedEventType,
    PackageModel? selectedPackage,
    String? selectedCity,
    String? locationAddress,
    DateTime? scheduledDate,
    String? scheduledTimeSlot,
    String? customerWhatsapp,
    String? notes,
    bool? isSubmitting,
    BookingModel? createdBooking,
    String? errorMessage,
  }) {
    return BookingFlowState(
      currentStep: currentStep ?? this.currentStep,
      isLoadingPackages: isLoadingPackages ?? this.isLoadingPackages,
      packages: packages ?? this.packages,
      selectedEventType: selectedEventType ?? this.selectedEventType,
      selectedPackage: selectedPackage ?? this.selectedPackage,
      selectedCity: selectedCity ?? this.selectedCity,
      locationAddress: locationAddress ?? this.locationAddress,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTimeSlot: scheduledTimeSlot ?? this.scheduledTimeSlot,
      customerWhatsapp: customerWhatsapp ?? this.customerWhatsapp,
      notes: notes ?? this.notes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      createdBooking: createdBooking ?? this.createdBooking,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        isLoadingPackages,
        packages,
        selectedEventType,
        selectedPackage,
        selectedCity,
        locationAddress,
        scheduledDate,
        scheduledTimeSlot,
        customerWhatsapp,
        notes,
        isSubmitting,
        createdBooking,
        errorMessage,
      ];
}

final bookingFlowControllerProvider =
    StateNotifierProvider.autoDispose<BookingFlowController, BookingFlowState>((ref) {
  final repository = ref.watch(customerBookingRepositoryProvider);
  return BookingFlowController(repository: repository);
});

class BookingFlowController extends StateNotifier<BookingFlowState> {
  final CustomerBookingRepository _repository;

  BookingFlowController({required CustomerBookingRepository repository})
      : _repository = repository,
        super(BookingFlowState(scheduledDate: DateTime.now().add(const Duration(days: 1)))) {
    loadPackages();
  }

  Future<void> loadPackages() async {
    state = state.copyWith(isLoadingPackages: true, errorMessage: null);
    try {
      final pkgs = await _repository.getPackages();
      PackageModel? defaultPkg;
      if (pkgs.isNotEmpty) {
        defaultPkg = pkgs.first;
      }
      state = state.copyWith(
        isLoadingPackages: false,
        packages: pkgs,
        selectedPackage: defaultPkg,
      );
    } catch (e) {
      AppLogger.e('Failed to load packages: $e');
      state = state.copyWith(
        isLoadingPackages: false,
        errorMessage: 'Unable to load packages. Please check connection.',
      );
    }
  }

  void selectEventType(EventType type) {
    state = state.copyWith(selectedEventType: type, errorMessage: null);
  }

  void selectPackage(PackageModel package) {
    state = state.copyWith(selectedPackage: package, errorMessage: null);
  }

  void selectCity(String city) {
    state = state.copyWith(selectedCity: city, errorMessage: null);
  }

  void setLocationAddress(String address) {
    state = state.copyWith(locationAddress: address, errorMessage: null);
  }

  void setScheduleDate(DateTime date) {
    state = state.copyWith(scheduledDate: date, errorMessage: null);
  }

  void setTimeSlot(String slot) {
    state = state.copyWith(scheduledTimeSlot: slot, errorMessage: null);
  }

  void setWhatsapp(String whatsapp) {
    state = state.copyWith(customerWhatsapp: whatsapp, errorMessage: null);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes, errorMessage: null);
  }

  void nextStep() {
    if (state.currentStep == 1 && !state.canProceedStep1) {
      state = state.copyWith(errorMessage: 'Please select an event type');
      return;
    }
    if (state.currentStep == 2 && !state.canProceedStep2) {
      state = state.copyWith(errorMessage: 'Please select a package');
      return;
    }
    if (state.currentStep == 3 && !state.canProceedStep3) {
      state = state.copyWith(errorMessage: 'Please enter a valid street address (min 5 characters)');
      return;
    }
    if (state.currentStep == 4 && !state.canProceedStep4) {
      state = state.copyWith(errorMessage: 'Please provide complete date, time slot, and WhatsApp number');
      return;
    }

    if (state.currentStep < 5) {
      state = state.copyWith(currentStep: state.currentStep + 1, errorMessage: null);
    }
  }

  void prevStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1, errorMessage: null);
    }
  }

  void goToStep(int step) {
    if (step >= 1 && step <= 5) {
      state = state.copyWith(currentStep: step, errorMessage: null);
    }
  }

  Future<bool> confirmAndSubmit() async {
    if (state.selectedPackage == null ||
        state.selectedEventType == null ||
        state.scheduledDate == null) {
      state = state.copyWith(errorMessage: 'Incomplete booking details.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      // Parse scheduled datetime
      final date = state.scheduledDate!;
      // Default scheduled hour based on time slot
      int hour = 11;
      if (state.scheduledTimeSlot?.contains('PM') == true) {
        if (state.scheduledTimeSlot?.startsWith('12') == true) {
          hour = 12;
        } else if (state.scheduledTimeSlot?.startsWith('02') == true ||
            state.scheduledTimeSlot?.startsWith('2') == true) {
          hour = 14;
        } else if (state.scheduledTimeSlot?.startsWith('05') == true ||
            state.scheduledTimeSlot?.startsWith('5') == true) {
          hour = 17;
        }
      }
      final scheduledAt = DateTime.utc(date.year, date.month, date.day, hour, 0);

      final booking = await _repository.createBooking(
        eventType: state.selectedEventType!,
        packageId: state.selectedPackage!.id,
        city: state.selectedCity,
        locationAddress: state.locationAddress,
        scheduledAt: scheduledAt,
        customerWhatsapp: state.customerWhatsapp,
        notes: state.notes,
      );

      state = state.copyWith(
        isSubmitting: false,
        createdBooking: booking,
      );
      return true;
    } catch (e) {
      AppLogger.e('Failed to submit booking: $e');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to create booking: $e',
      );
      return false;
    }
  }
}

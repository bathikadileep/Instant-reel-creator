import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:instant_reel/core/constants/app_constants.dart';
import 'package:instant_reel/core/router/route_names.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/core/utils/responsive_layout.dart';
import 'package:instant_reel/features/auth/presentation/controllers/auth_controller.dart';
import 'package:instant_reel/features/customer/domain/models/event_type.dart';
import 'package:instant_reel/features/customer/domain/models/package_model.dart';
import 'package:instant_reel/features/customer/presentation/controllers/booking_flow_controller.dart';
import 'package:instant_reel/features/customer/presentation/widgets/step_indicator.dart';
import 'package:instant_reel/features/payment/domain/models/payment_models.dart';
import 'package:instant_reel/features/payment/presentation/controllers/payment_controller.dart';
import 'package:instant_reel/features/payment/presentation/widgets/payment_method_selector.dart';
import 'package:instant_reel/features/payment/presentation/widgets/razorpay_checkout_dialog.dart';

class BookingFlowView extends ConsumerStatefulWidget {
  const BookingFlowView({Key? key}) : super(key: key);

  @override
  ConsumerState<BookingFlowView> createState() => _BookingFlowViewState();
}

class _BookingFlowViewState extends ConsumerState<BookingFlowView> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userMobile = ref.read(authControllerProvider).user?.mobile;
      if (userMobile != null && userMobile.isNotEmpty) {
        _whatsappController.text = userMobile;
        ref.read(bookingFlowControllerProvider.notifier).setWhatsapp(userMobile);
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _whatsappController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final success =
        await ref.read(bookingFlowControllerProvider.notifier).confirmAndSubmit();
    if (success && mounted) {
      final booking = ref.read(bookingFlowControllerProvider).createdBooking;
      if (booking != null) {
        // Create payment order (Full or COD Advance based on user selection)
        final paymentNotifier = ref.read(paymentControllerProvider.notifier);
        final order = await paymentNotifier.initiatePaymentOrder(
          bookingId: booking.id,
        );

        if (order != null && mounted) {
          // Open interactive Razorpay checkout sheet with HMAC verification
          final verified = await RazorpayCheckoutDialog.show(context, order);
          if (verified == true && mounted) {
            context.pushReplacement(
              '${RoutePaths.bookingSuccess}/${booking.id}',
              extra: booking,
            );
          }
        } else if (mounted) {
          final err = ref.read(paymentControllerProvider).errorMessage ?? 'Payment initialization failed.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(bookingFlowControllerProvider);
    final flowNotifier = ref.read(bookingFlowControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Book a Reel Creator'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (flowState.currentStep > 1) {
              flowNotifier.prevStep();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildWizardBody(context, flowState, flowNotifier, isMobile: true),
          desktop: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: _buildWizardBody(context, flowState, flowNotifier, isMobile: false),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, flowState, flowNotifier),
    );
  }

  Widget _buildWizardBody(
    BuildContext context,
    BookingFlowState state,
    BookingFlowController notifier, {
    required bool isMobile,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20.0 : 32.0,
        vertical: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Progress Bar
          StepIndicator(
            currentStep: state.currentStep,
            onStepTapped: (step) => notifier.goToStep(step),
          ),
          const SizedBox(height: 20),

          // Error banner
          if (state.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Step Content Switcher
          if (state.currentStep == 1) _buildStep1EventType(context, state, notifier),
          if (state.currentStep == 2) _buildStep2Package(context, state, notifier),
          if (state.currentStep == 3) _buildStep3Location(context, state, notifier),
          if (state.currentStep == 4) _buildStep4DateTime(context, state, notifier),
          if (state.currentStep == 5) _buildStep5Confirm(context, state, notifier),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 1: SELECT EVENT TYPE
  // ===========================================================================
  Widget _buildStep1EventType(
    BuildContext context,
    BookingFlowState state,
    BookingFlowController notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What is the occasion?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select the event type so our creator prepares the right lenses & hook script.',
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
        ),
        const SizedBox(height: 20),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemCount: EventType.values.length,
          itemBuilder: (context, index) {
            final type = EventType.values[index];
            final isSelected = state.selectedEventType == type;

            return InkWell(
              onTap: () => notifier.selectEventType(type),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surfaceDark : AppColors.cardDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderDark,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.2)
                            : AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        type.icon,
                        color: isSelected ? AppColors.primaryLight : Colors.white70,
                        size: 24,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type.description,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondaryDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 2: SELECT PACKAGE
  // ===========================================================================
  Widget _buildStep2Package(
    BuildContext context,
    BookingFlowState state,
    BookingFlowController notifier,
  ) {
    if (state.isLoadingPackages) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Reel Package',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'All packages include professional shooting + 10-minute on-site edit guarantee.',
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
        ),
        const SizedBox(height: 20),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.packages.length,
          itemBuilder: (context, index) {
            final pkg = state.packages[index];
            final isSelected = state.selectedPackage?.id == pkg.id;

            return InkWell(
              onTap: () => notifier.selectPackage(pkg),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surfaceDark : AppColors.cardDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderDark,
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pkg.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${pkg.deliveryTimeMinutes}-Min SLA',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${pkg.reelsCount} Reel • ${pkg.shootDurationMinutes}m shoot',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${pkg.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      pkg.description,
                      style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.borderDark, height: 1),
                    const SizedBox(height: 12),

                    // Feature checklist
                    ...pkg.features.map(
                      (feat) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 14, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feat,
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 3: SELECT LOCATION
  // ===========================================================================
  Widget _buildStep3Location(
    BuildContext context,
    BookingFlowState state,
    BookingFlowController notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where should we shoot?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select your city and provide the street address for creator arrival.',
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
        ),
        const SizedBox(height: 24),

        // City Selector Chips
        const Text(
          'Service Hub (Telangana)',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppConstants.supportedRegions.map((city) {
            final isSelected = state.selectedCity == city;
            return ChoiceChip(
              label: Text(city),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) notifier.selectCity(city);
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceDark,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondaryDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.borderDark,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

        // Detailed Address Field
        const Text(
          'Street Address / Venue Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'e.g. Shop #4, Main Bazaar, Near Old Bus Stand, Khammam',
            hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
            fillColor: AppColors.surfaceDark,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.borderDark),
            ),
          ),
          onChanged: (val) => notifier.setLocationAddress(val),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 4: DATE, TIME & WHATSAPP
  // ===========================================================================
  Widget _buildStep4DateTime(
    BuildContext context,
    BookingFlowState state,
    BookingFlowController notifier,
  ) {
    final slots = ['10:00 AM', '12:00 PM', '02:00 PM', '04:00 PM', '06:00 PM'];
    final selectedDateStr = state.scheduledDate != null
        ? DateFormat('EEE, d MMMM yyyy').format(state.scheduledDate!)
        : 'Select Date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule & Delivery',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pick shoot timing and the WhatsApp number where the finished reel will be sent in 10 minutes.',
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
        ),
        const SizedBox(height: 24),

        // Date Picker Button
        const Text(
          'Shoot Date',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: state.scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (picked != null) {
              notifier.setScheduleDate(picked);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDateStr,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const Icon(Icons.calendar_month_rounded, color: AppColors.primaryLight, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Time Slot Selector
        const Text(
          'Preferred Time Slot',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = state.scheduledTimeSlot == slot;
            return ChoiceChip(
              label: Text(slot),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) notifier.setTimeSlot(slot);
              },
              selectedColor: AppColors.secondary,
              backgroundColor: AppColors.surfaceDark,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppColors.textSecondaryDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.secondary : AppColors.borderDark,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Customer WhatsApp Number for Delivery
        const Text(
          'Delivery WhatsApp Number (+91)',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _whatsappController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          style: const TextStyle(color: Colors.white, fontSize: 15, letterSpacing: 1.2),
          decoration: InputDecoration(
            hintText: '9876543210',
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.centerLeft,
              width: 70,
              child: const Text(
                '+91',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            fillColor: AppColors.surfaceDark,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderDark),
            ),
          ),
          onChanged: (val) => notifier.setWhatsapp(val),
        ),
        const SizedBox(height: 20),

        // Optional Notes
        const Text(
          'Special Requests / Notes (Optional)',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'e.g. Bring extra wireless mic, food showcase',
            fillColor: AppColors.surfaceDark,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderDark),
            ),
          ),
          onChanged: (val) => notifier.setNotes(val),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 5: REVIEW & CONFIRM
  // ===========================================================================
  Widget _buildStep5Confirm(
    BuildContext context,
    BookingFlowState state,
    BookingFlowController notifier,
  ) {
    final formattedDate = state.scheduledDate != null
        ? DateFormat('EEE, d MMM yyyy').format(state.scheduledDate!)
        : '';
    final pkgPrice = state.selectedPackage?.price ?? 0.0;
    final paymentState = ref.watch(paymentControllerProvider);
    final isCod = paymentState.selectedMethod == PaymentMethodType.codWithAdvance;
    final minAdvance = paymentState.config.codMinimumAdvance;
    final remainingCash = (pkgPrice - minAdvance).clamp(0.0, pkgPrice);
    final dueNow = isCod ? minAdvance : pkgPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Your Booking',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Review details and choose payment method to dispatch your creator.',
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
        ),
        const SizedBox(height: 20),

        // 10-Minute SLA Highlight Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withOpacity(0.2),
                AppColors.surfaceDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: AppColors.secondary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Instant Reel 10-Minute Guarantee',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Your reel will be shot, professionally color-graded, and sent to your WhatsApp on-site in 10 minutes.',
                      style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Occasion', state.selectedEventType?.displayName ?? 'Event'),
              const Divider(color: AppColors.borderDark, height: 20),
              _buildSummaryRow('Package', state.selectedPackage?.name ?? ''),
              const Divider(color: AppColors.borderDark, height: 20),
              _buildSummaryRow('Location', '${state.selectedCity} • ${state.locationAddress}'),
              const Divider(color: AppColors.borderDark, height: 20),
              _buildSummaryRow('Schedule', '$formattedDate at ${state.scheduledTimeSlot}'),
              const Divider(color: AppColors.borderDark, height: 20),
              _buildSummaryRow('WhatsApp Delivery', state.customerWhatsapp),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Payment Method Selector
        PaymentMethodSelector(
          selectedMethod: paymentState.selectedMethod,
          onMethodSelected: (method) {
            ref.read(paymentControllerProvider.notifier).selectPaymentMethod(method);
          },
          totalAmount: pkgPrice,
          config: paymentState.config,
        ),
        const SizedBox(height: 24),

        // Pricing Breakdown Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Package Rate', style: TextStyle(color: AppColors.textSecondaryDark)),
                  Text('₹${pkgPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Convenience & Travel', style: TextStyle(color: AppColors.textSecondaryDark)),
                  Text('FREE', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                ],
              ),
              if (isCod) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mandatory Online Advance (Due Now)',
                        style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600)),
                    Text('₹${minAdvance.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cash Due to Videographer on Delivery',
                        style: TextStyle(color: Colors.white70)),
                    Text('₹${remainingCash.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
              const Divider(color: AppColors.borderDark, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCod ? 'Pay Online Now' : 'Total Amount Due Now',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      if (isCod)
                        Text(
                          'Remaining ₹${remainingCash.toStringAsFixed(0)} cash on-site',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                        ),
                    ],
                  ),
                  Text(
                    '₹${dueNow.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // BOTTOM NAVIGATION CONTROLS
  // ===========================================================================
  Widget _buildBottomNav(
    BuildContext context,
    BookingFlowState state,
    BookingFlowController notifier,
  ) {
    final isLastStep = state.currentStep == 5;
    final paymentState = ref.watch(paymentControllerProvider);
    final pkgPrice = state.selectedPackage?.price ?? 0.0;
    final isCod = paymentState.selectedMethod == PaymentMethodType.codWithAdvance;
    final dueNow = isCod ? paymentState.config.codMinimumAdvance : pkgPrice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.borderDark)),
      ),
      child: Row(
        children: [
          if (state.currentStep > 1) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => notifier.prevStep(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderDark),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: state.isSubmitting
                  ? null
                  : (isLastStep ? _handleConfirm : () => notifier.nextStep()),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastStep ? AppColors.secondary : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isLastStep
                          ? 'Pay ₹${dueNow.toStringAsFixed(0)} & Confirm'
                          : 'Continue',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

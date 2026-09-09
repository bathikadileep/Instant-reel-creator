import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/core/utils/responsive_layout.dart';
import 'package:instant_reel/features/creator/domain/models/creator_booking_status.dart';
import 'package:instant_reel/features/creator/presentation/controllers/creator_workflow_controller.dart';
import 'package:instant_reel/features/creator/presentation/widgets/deliver_reel_dialog.dart';
import 'package:instant_reel/features/creator/presentation/widgets/editing_countdown_timer.dart';
import 'package:instant_reel/features/creator/presentation/widgets/whatsapp_delivery_card.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';
import 'package:instant_reel/features/payment/presentation/widgets/creator_cod_collection_card.dart';
import 'package:url_launcher/url_launcher.dart';

class CreatorBookingWorkflowView extends ConsumerWidget {
  final String bookingId;

  const CreatorBookingWorkflowView({super.key, required this.bookingId});

  Future<void> _openPhone(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone, String bookingCode) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent('Hi! I am your Instant Reel creator for booking $bookingCode.');
    final uri = Uri.parse('https://wa.me/$clean?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(creatorWorkflowControllerProvider(bookingId));
    final controller = ref.read(creatorWorkflowControllerProvider(bookingId).notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Shoot Workflow & SLA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () => controller.loadBooking(),
          ),
        ],
      ),
      body: state.booking.when(
        data: (booking) => SafeArea(
          child: ResponsiveLayout(
            mobile: _buildContent(context, ref, booking, state, controller, isMobile: true),
            desktop: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: _buildContent(context, ref, booking, state, controller, isMobile: false),
              ),
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error: $err', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadBooking(),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.black),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
    CreatorWorkflowState state,
    CreatorWorkflowController controller, {
    required bool isMobile,
  }) {
    final workflow = CreatorWorkflowStatus.fromString(booking.status);
    final currentStep = workflow.stepIndex;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 20),
      children: [
        // Feedback messages
        if (state.successMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.successMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        if (state.error != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

        // Header Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.bookingCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: workflow.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: workflow.color.withOpacity(0.5)),
                    ),
                    child: Text(
                      workflow.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: workflow.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                booking.packageName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                '${booking.city} • ${booking.locationAddress}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
              ),
              const SizedBox(height: 4),
              Text(
                booking.formattedSchedule,
                style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 8-Stage Interactive Stepper Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.linear_scale_rounded, color: AppColors.secondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '8-Stage Shoot Progression',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 8 Steps List
              _buildStepItem(1, 'Assigned', 'Booking allocated to you', currentStep, workflow),
              _buildStepItem(2, 'On The Way', 'Traveling to client location', currentStep, workflow),
              _buildStepItem(3, 'Reached Venue', 'Arrived on location', currentStep, workflow),
              _buildStepItem(4, 'Shooting Started', 'Rolling 4K footage & b-roll', currentStep, workflow),
              _buildStepItem(5, 'Shooting Completed', 'Footage wrapped & verified', currentStep, workflow),
              _buildStepItem(6, '10-Min Rapid Edit', 'Editing on location with timer', currentStep, workflow),
              _buildStepItem(7, 'Editing Completed', 'Final cut ready for delivery', currentStep, workflow),
              _buildStepItem(8, 'Delivered', 'Sent directly to client WhatsApp', currentStep, workflow, isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 10-Minute Rapid Edit Timer (Active when editing_started)
        if (workflow == CreatorWorkflowStatus.editingStarted) ...[
          EditingCountdownTimer(
            totalMinutes: 10,
            onTimerFinished: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('10-Minute Rapid Edit SLA reached! Ready to export.'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],

        // Cash on Delivery Settlement Card
        CreatorCodCollectionCard(
          booking: booking,
          onCashCollected: () => controller.loadBooking(),
        ),
        const SizedBox(height: 20),

        // WhatsApp Peer-to-Peer Delivery Card
        if (workflow == CreatorWorkflowStatus.editingCompleted ||
            workflow == CreatorWorkflowStatus.delivered ||
            workflow == CreatorWorkflowStatus.completed ||
            booking.isDelivered) ...[
          WhatsAppDeliveryCard(
            booking: booking,
            controller: controller,
            isActionLoading: state.isActionLoading,
          ),
          const SizedBox(height: 20),
        ],

        // Active Action Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                workflow.color.withOpacity(0.15),
                AppColors.surfaceDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: workflow.color.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(workflow.icon, color: workflow.color, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Current Phase: ${workflow.title}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                workflow.description,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, height: 1.4),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              if (workflow == CreatorWorkflowStatus.pending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.isActionLoading
                            ? null
                            : () async {
                                await controller.rejectBooking(reason: 'Videographer schedule conflict');
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: state.isActionLoading ? null : () => controller.acceptBooking(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: state.isActionLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Accept Booking', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              else if (workflow == CreatorWorkflowStatus.editingCompleted)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: state.isActionLoading
                            ? null
                            : () async {
                                final res = await controller.sendReelOnWhatsApp();
                                if (res != null && res['whatsapp_url'] != null) {
                                  final uri = Uri.parse(res['whatsapp_url'] as String);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                }
                              },
                        icon: const Icon(Icons.send_rounded, size: 20),
                        label: const Text(
                          '1. Send Reel via WhatsApp',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: state.isActionLoading
                            ? null
                            : () async {
                                await controller.markDelivered(
                                  note: 'Vertical 4K reel delivered directly to customer via WhatsApp.',
                                );
                              },
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: const Text(
                          '2. Mark Booking Delivered',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                )
              else if (workflow == CreatorWorkflowStatus.delivered || workflow == CreatorWorkflowStatus.completed)
                Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded, color: AppColors.success, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Reel Delivered Successfully!',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ],
                    ),
                    if (booking.reelUrl != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _openLink(booking.reelUrl!),
                        icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.secondary),
                        label: const Text('View Delivered Reel Video'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.secondary),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: state.isActionLoading ? null : () => controller.advanceToNextStatus(),
                    icon: state.isActionLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: Text(
                      workflow.nextActionLabel ?? 'Advance Status',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: workflow.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Client Contact Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Client Contact & Location',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.cardDark,
                    child: const Icon(Icons.person, color: Colors.white70),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.customerName ?? 'Customer',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          booking.customerWhatsapp,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_rounded, color: AppColors.primary),
                    onPressed: () => _openPhone(booking.customerWhatsapp),
                    tooltip: 'Call Client',
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366)),
                    onPressed: () => _openWhatsApp(booking.customerWhatsapp, booking.bookingCode),
                    tooltip: 'WhatsApp Client',
                  ),
                ],
              ),
              const Divider(color: AppColors.cardDark, height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.city,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.locationAddress,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note_alt_outlined, size: 16, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Client Note: ${booking.notes}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Status History Audit Timeline
        if (booking.statusHistory.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_rounded, color: AppColors.textSecondaryDark, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Status Transition Audit Log',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...booking.statusHistory.map((h) {
                  final histWorkflow = CreatorWorkflowStatus.fromString(h.status);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 5, right: 12),
                          decoration: BoxDecoration(
                            color: histWorkflow.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                histWorkflow.title,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              if (h.note != null)
                                Text(
                                  h.note!,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          h.formattedTime,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildStepItem(
    int stepNum,
    String title,
    String desc,
    int currentStep,
    CreatorWorkflowStatus currentWorkflow, {
    bool isLast = false,
  }) {
    final isDone = stepNum < currentStep || currentWorkflow == CreatorWorkflowStatus.completed;
    final isCurrent = stepNum == currentStep && currentWorkflow != CreatorWorkflowStatus.completed;

    Color circleColor;
    Widget iconWidget;

    if (isDone) {
      circleColor = AppColors.success;
      iconWidget = const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (isCurrent) {
      circleColor = currentWorkflow.color;
      iconWidget = Text(
        stepNum.toString(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    } else {
      circleColor = AppColors.cardDark;
      iconWidget = Text(
        stepNum.toString(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: circleColor.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: iconWidget,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? AppColors.success.withOpacity(0.5) : AppColors.cardDark,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                      color: isCurrent ? Colors.white : (isDone ? Colors.white70 : AppColors.textSecondaryDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 11,
                      color: isCurrent ? AppColors.secondary : AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

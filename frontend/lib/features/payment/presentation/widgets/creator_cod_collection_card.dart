import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';
import 'package:instant_reel/features/payment/presentation/controllers/payment_controller.dart';

class CreatorCodCollectionCard extends ConsumerStatefulWidget {
  final BookingModel booking;
  final VoidCallback onCashCollected;

  const CreatorCodCollectionCard({
    super.key,
    required this.booking,
    required this.onCashCollected,
  });

  @override
  ConsumerState<CreatorCodCollectionCard> createState() => _CreatorCodCollectionCardState();
}

class _CreatorCodCollectionCardState extends ConsumerState<CreatorCodCollectionCard> {
  bool _isCollecting = false;

  Future<void> _handleCollectCash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Cash Receipt', style: TextStyle(color: Colors.white)),
        content: Text(
          'Have you physically received ₹${widget.booking.remainingAmount.toStringAsFixed(0)} in cash from the customer?',
          style: const TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Receipt'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCollecting = true);
    final result = await ref
        .read(paymentControllerProvider.notifier)
        .collectCash(bookingId: widget.booking.id);

    if (mounted) {
      setState(() => _isCollecting = false);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onCashCollected();
      } else {
        final err = ref.read(paymentControllerProvider).errorMessage ?? 'Cash collection failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isCod = booking.isCod;
    final hasOutstandingCash = booking.hasOutstandingCash;

    // If Razorpay Full Payment was made online
    if (!isCod) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prepaid via Razorpay Full Payment',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total ₹${booking.price.toStringAsFixed(0)} paid online. Do NOT collect any cash from client.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // If COD and cash is already collected
    if (booking.cashCollected || !hasOutstandingCash) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.payments_rounded, color: Colors.black, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cash Collected & Account Settled',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Online Advance: ₹${booking.advanceAmount.toStringAsFixed(0)} • Cash Collected On-Site: ₹${((booking.totalAmount ?? booking.price) - booking.advanceAmount).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // COD Outstanding Balance to Collect
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.currency_rupee_rounded, color: AppColors.warning, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Cash On Delivery Balance',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ACTION REQUIRED',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The client paid ₹${booking.advanceAmount.toStringAsFixed(0)} online advance. You must collect the remaining ₹${booking.remainingAmount.toStringAsFixed(0)} in cash upon delivering the reel.',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, height: 1.35),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CASH TO COLLECT',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondaryDark, letterSpacing: 0.8),
                  ),
                  Text(
                    '₹${booking.remainingAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isCollecting ? null : _handleCollectCash,
                icon: _isCollecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  _isCollecting ? 'Recording...' : 'Collect Cash ₹${booking.remainingAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

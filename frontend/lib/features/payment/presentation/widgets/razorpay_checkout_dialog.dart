import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/features/payment/domain/models/payment_models.dart';
import 'package:instant_reel/features/payment/presentation/controllers/payment_controller.dart';

class RazorpayCheckoutDialog extends ConsumerStatefulWidget {
  final CreateOrderResponse order;

  const RazorpayCheckoutDialog({super.key, required this.order});

  static Future<bool?> show(BuildContext context, CreateOrderResponse order) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RazorpayCheckoutDialog(order: order),
    );
  }

  @override
  ConsumerState<RazorpayCheckoutDialog> createState() => _RazorpayCheckoutDialogState();
}

class _RazorpayCheckoutDialogState extends ConsumerState<RazorpayCheckoutDialog> {
  int _selectedTab = 0; // 0: UPI, 1: Card, 2: NetBanking
  bool _isProcessing = false;
  String? _errorMsg;

  // Compute mock HMAC-SHA256 test signature using secret matching backend test suite
  String _computeSignature(String orderId, String paymentId, String secret) {
    final payload = '$orderId|$paymentId';
    final hmac = Hmac(sha256, utf8.encode(secret));
    final digest = hmac.convert(utf8.encode(payload));
    return digest.toString();
  }

  Future<void> _processPayment({bool simulateSuccess = true}) async {
    setState(() {
      _isProcessing = true;
      _errorMsg = null;
    });

    try {
      if (!simulateSuccess) {
        throw Exception('Payment was cancelled or rejected by issuing bank.');
      }

      // Generate a mock payment ID for simulation/testing
      final mockPaymentId = 'pay_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';
      
      // Default key secret for local test verification
      const secret = 'rzp_test_secret_dev999';
      final signature = _computeSignature(widget.order.razorpayOrderId, mockPaymentId, secret);

      // Verify server-side via PaymentController
      final result = await ref.read(paymentControllerProvider.notifier).verifyPayment(
            paymentId: widget.order.paymentId,
            razorpayOrderId: widget.order.razorpayOrderId,
            razorpayPaymentId: mockPaymentId,
            razorpaySignature: signature,
          );

      if (result != null && mounted) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isProcessing = false;
          _errorMsg = ref.read(paymentControllerProvider).errorMessage ??
              'Payment verification failed. Please contact support.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMsg = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isCod = order.paymentMethod == 'cod_with_advance';

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.borderDark)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Razorpay Header & Branding
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C2340),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Color(0xFF3399CC), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Razorpay Secure',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Instant Reel • ${order.bookingCode}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'AMOUNT TO PAY',
                    style: TextStyle(fontSize: 10, letterSpacing: 1, color: AppColors.textSecondaryDark),
                  ),
                  Text(
                    '₹${order.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Advance banner if COD
          if (isCod)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cash on Delivery: Paying ₹${order.advanceAmount.toStringAsFixed(0)} advance online. Remaining ₹${order.remainingCashAmount.toStringAsFixed(0)} will be paid in cash after 10-min delivery.',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Payment Mode Selector Tabs
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTab(0, 'UPI (GPay/PhonePe)', Icons.account_balance_wallet_rounded),
                _buildTab(1, 'Card', Icons.credit_card_rounded),
                _buildTab(2, 'NetBanking', Icons.account_balance_rounded),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tab Content
          if (_selectedTab == 0) _buildUpiView(order),
          if (_selectedTab == 1) _buildCardView(order),
          if (_selectedTab == 2) _buildNetBankingView(order),

          if (_errorMsg != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Pay Button
          ElevatedButton(
            onPressed: _isProcessing ? null : () => _processPayment(simulateSuccess: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            child: _isProcessing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Verifying with Razorpay...', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )
                : Text(
                    'Pay ₹${order.amount.toStringAsFixed(0)} via Razorpay',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 10),

          // Simulated Failure for testing edge cases
          TextButton(
            onPressed: _isProcessing ? null : () => _processPayment(simulateSuccess: false),
            child: const Text(
              'Simulate Failed Payment',
              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: AppColors.secondary) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.secondary : AppColors.textSecondaryDark,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpiView(CreateOrderResponse order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildUpiAppIcon('Google Pay', Icons.account_balance_wallet_rounded, const Color(0xFF4285F4)),
              _buildUpiAppIcon('PhonePe', Icons.phone_android_rounded, const Color(0xFF5F259F)),
              _buildUpiAppIcon('Paytm', Icons.payment_rounded, const Color(0xFF00BAF2)),
              _buildUpiAppIcon('BHIM UPI', Icons.qr_code_rounded, const Color(0xFF00A859)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Order ID: verified server-side via HMAC-SHA256 signature',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiAppIcon(String name, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCardView(CreateOrderResponse order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cards Accepted: Visa, MasterCard, RuPay, Maestro',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Saved test card credentials will be auto-filled for instant sandbox approval.',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNetBankingView(CreateOrderResponse order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: const Text(
        'Supported Banks: SBI, HDFC, ICICI, Axis, Kotak, Punjab National Bank',
        style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
      ),
    );
  }
}

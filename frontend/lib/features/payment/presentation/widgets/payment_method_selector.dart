import 'package:flutter/material.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/features/payment/domain/models/payment_config_model.dart';
import 'package:instant_reel/features/payment/domain/models/payment_models.dart';

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethodType selectedMethod;
  final ValueChanged<PaymentMethodType> onMethodSelected;
  final double totalAmount;
  final PaymentConfigModel config;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
    required this.totalAmount,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final minAdvance = config.codMinimumAdvance;
    final remainingCash = (totalAmount - minAdvance).clamp(0.0, totalAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Payment Option',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.secondary),
                  SizedBox(width: 4),
                  Text(
                    '256-bit Encrypted',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Option 1: Full Payment Online via Razorpay
        _buildMethodCard(
          context: context,
          method: PaymentMethodType.razorpayFull,
          isSelected: selectedMethod == PaymentMethodType.razorpayFull,
          title: 'Pay Full Amount Online',
          badgeText: 'RECOMMENDED • ZERO CASH',
          badgeColor: AppColors.success,
          payNowAmount: totalAmount,
          balanceAmount: 0.0,
          description:
              'Pay total ₹${totalAmount.toStringAsFixed(0)} now via UPI, Cards, or NetBanking. Hassle-free delivery with no cash exchange.',
          icon: Icons.flash_on_rounded,
        ),
        const SizedBox(height: 12),

        // Option 2: Cash on Delivery with Minimum Advance (if enabled)
        if (config.codEnabled)
          _buildMethodCard(
            context: context,
            method: PaymentMethodType.codWithAdvance,
            isSelected: selectedMethod == PaymentMethodType.codWithAdvance,
            title: 'Cash on Delivery (Advance Required)',
            badgeText: '₹${minAdvance.toStringAsFixed(0)} ADVANCE NOW',
            badgeColor: AppColors.warning,
            payNowAmount: minAdvance,
            balanceAmount: remainingCash,
            description:
                'Pay ₹${minAdvance.toStringAsFixed(0)} advance online to confirm creator visit. Pay balance ₹${remainingCash.toStringAsFixed(0)} in cash after reel is delivered.',
            icon: Icons.payments_rounded,
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.textSecondaryDark),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cash on Delivery is currently disabled by admin. Please pay online.',
                    style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMethodCard({
    required BuildContext context,
    required PaymentMethodType method,
    required bool isSelected,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required double payNowAmount,
    required double balanceAmount,
    required String description,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => onMethodSelected(method),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary.withOpacity(0.08) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.borderDark,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.secondary : AppColors.cardDark,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.black : Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.white70,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: badgeColor.withOpacity(0.6)),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? AppColors.secondary : AppColors.textSecondaryDark,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.borderDark, height: 1),
            const SizedBox(height: 10),

            // Due Now vs Due Later summary bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Pay Online Now: ',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                    ),
                    Text(
                      '₹${payNowAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                if (balanceAmount > 0)
                  Row(
                    children: [
                      const Text(
                        'Cash on Delivery: ',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                      ),
                      Text(
                        '₹${balanceAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Balance: ₹0.00',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

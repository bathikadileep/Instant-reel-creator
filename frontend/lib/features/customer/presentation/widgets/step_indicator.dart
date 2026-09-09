import 'package:flutter/material.dart';
import 'package:instant_reel/core/theme/app_colors.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Function(int)? onStepTapped;

  const StepIndicator({
    Key? key,
    required this.currentStep,
    this.totalSteps = 5,
    this.onStepTapped,
  }) : super(key: key);

  static const List<String> stepLabels = [
    'Event',
    'Package',
    'Location',
    'Schedule',
    'Confirm',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(totalSteps, (index) {
          final stepNum = index + 1;
          final isCompleted = stepNum < currentStep;
          final isCurrent = stepNum == currentStep;

          return InkWell(
            onTap: onStepTapped != null && stepNum <= currentStep
                ? () => onStepTapped!(stepNum)
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.success
                          : (isCurrent ? AppColors.primary : AppColors.cardDark),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.primaryLight
                            : (isCompleted
                                ? AppColors.success
                                : AppColors.borderDark),
                        width: isCurrent ? 2 : 1,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text(
                              '$stepNum',
                              style: TextStyle(
                                color: isCurrent ? Colors.white : AppColors.textSecondaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stepLabels[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Colors.white : AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

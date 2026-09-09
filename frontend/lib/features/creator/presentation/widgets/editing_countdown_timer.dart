import 'dart:async';
import 'package:flutter/material.dart';
import 'package:instant_reel/core/theme/app_colors.dart';

class EditingCountdownTimer extends StatefulWidget {
  final int totalMinutes;
  final VoidCallback onTimerFinished;

  const EditingCountdownTimer({
    super.key,
    this.totalMinutes = 10,
    required this.onTimerFinished,
  });

  @override
  State<EditingCountdownTimer> createState() => _EditingCountdownTimerState();
}

class _EditingCountdownTimerState extends State<EditingCountdownTimer> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.totalMinutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        widget.onTimerFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _progress {
    final totalSeconds = widget.totalMinutes * 60;
    return _remainingSeconds / totalSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _remainingSeconds < 120; // less than 2 mins
    final progressColor = isUrgent ? AppColors.warning : AppColors.secondary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent ? AppColors.warning.withOpacity(0.5) : AppColors.secondary.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: progressColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, color: progressColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '10-Minute Rapid Edit Mode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ON-SITE SLA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 8,
                  backgroundColor: AppColors.cardDark,
                  color: progressColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _remainingSeconds > 0 ? 'Remaining' : "Time's Up!",
                    style: TextStyle(
                      fontSize: 11,
                      color: isUrgent ? AppColors.warning : AppColors.textSecondaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Keep it fast and punchy! Assemble clips, apply colour grade, add trending beat, and export 9:16 vertical.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

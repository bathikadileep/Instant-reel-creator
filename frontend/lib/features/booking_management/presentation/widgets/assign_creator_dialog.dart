import 'package:flutter/material.dart';
import 'package:instant_reel/core/theme/app_colors.dart';

class AssignCreatorDialog extends StatefulWidget {
  final String bookingCode;
  final String city;
  final Future<bool> Function(String creatorId, String? note) onAssign;

  const AssignCreatorDialog({
    super.key,
    required this.bookingCode,
    required this.city,
    required this.onAssign,
  });

  @override
  State<AssignCreatorDialog> createState() => _AssignCreatorDialogState();
}

class _AssignCreatorDialogState extends State<AssignCreatorDialog> {
  final _creatorIdController = TextEditingController();
  final _noteController = TextEditingController(text: 'Assigned via dispatch engine');
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _creatorIdController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleAssign() async {
    final creatorId = _creatorIdController.text.trim();
    if (creatorId.isEmpty) {
      setState(() => _error = 'Please enter Creator UUID or ID');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await widget.onAssign(creatorId, _noteController.text.trim());
    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Failed to assign creator. Ensure valid creator UUID.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign Reel Videographer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Booking ${widget.bookingCode} • Hub: ${widget.city}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Creator User UUID *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _creatorIdController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter registered creator UUID...',
                hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.cardDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ],
            const SizedBox(height: 16),

            const Text(
              'Assignment Notes',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Bring Sony A7SIII & gimbal for outdoor daylight shoot',
                hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                filled: true,
                fillColor: AppColors.cardDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleAssign,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Confirm Assignment',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

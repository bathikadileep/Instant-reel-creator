import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:instant_reel/core/router/route_names.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/core/utils/responsive_layout.dart';
import 'package:instant_reel/features/auth/domain/models/user_model.dart';
import 'package:instant_reel/features/auth/presentation/controllers/auth_controller.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole _selectedRole = UserRole.customer;

  Future<void> _handleContinue() async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .selectRole(_selectedRole);

    if (success && mounted) {
      if (_selectedRole == UserRole.creator) {
        context.go(RoutePaths.creatorDashboard);
      } else {
        context.go(RoutePaths.customerDashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildContent(context, isLoading, isMobile: true),
          desktop: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Card(
                elevation: 0,
                color: AppColors.surfaceDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: AppColors.cardDark),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(36.0),
                  child: _buildContent(context, isLoading, isMobile: false),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isLoading, {required bool isMobile}) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 0,
        vertical: 32.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Role',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us how you would like to use Instant Reel.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
          ),
          const SizedBox(height: 32),

          // Role 1: Customer Card
          _buildRoleCard(
            role: UserRole.customer,
            title: 'I Want to Book Creators',
            subtitle: 'Book local professional videographers to shoot & deliver viral reels to your WhatsApp in 10 minutes.',
            icon: Icons.person_search_rounded,
            badgeColor: AppColors.primary,
          ),
          const SizedBox(height: 16),

          // Role 2: Creator Card
          _buildRoleCard(
            role: UserRole.creator,
            title: 'I Am a Reel Creator',
            subtitle: 'Accept local shooting gigs in Maripeda, Mahabubabad, Khammam, or Warangal. Shoot, edit, and earn.',
            icon: Icons.video_camera_front_rounded,
            badgeColor: AppColors.secondary,
          ),
          const SizedBox(height: 36),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Continue as ${_selectedRole.displayName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color badgeColor,
  }) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceDark : AppColors.surfaceDark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? badgeColor : AppColors.cardDark,
            width: isSelected ? 2.2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: badgeColor.withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: badgeColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: isSelected ? badgeColor : AppColors.textSecondaryDark,
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryDark,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

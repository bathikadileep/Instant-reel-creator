import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/core/constants/app_constants.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/core/utils/responsive_layout.dart';
import 'package:instant_reel/features/splash/presentation/controllers/health_controller.dart';

class SplashView extends ConsumerWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthControllerProvider);
    final healthNotifier = ref.read(healthControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildContent(context, healthState, healthNotifier, isMobile: true),
          desktop: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _buildContent(context, healthState, healthNotifier, isMobile: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    HealthState state,
    HealthController controller, {
    required bool isMobile,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 48.0,
        vertical: 32.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo / Icon Badge
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.videocam_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Title & Tagline
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppConstants.appTagline,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Operating Regions Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Service Regions (Telangana)',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.supportedRegions.map((region) {
                    return Chip(
                      label: Text(
                        region,
                        style: const TextStyle(fontSize: 13, color: Colors.white),
                      ),
                      backgroundColor: AppColors.cardDark,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // System Health & Neon PostgreSQL Connection Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardDark),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Backend & Neon DB Status',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    _buildStatusPill(state.status),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'API Service',
                  state.apiVersion != null
                      ? 'FastAPI v${state.apiVersion}'
                      : 'Connecting...',
                ),
                const Divider(color: AppColors.cardDark, height: 16),
                _buildInfoRow(
                  'Database',
                  state.dbStatus ?? 'Neon PostgreSQL',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Refresh Button
          ElevatedButton.icon(
            onPressed: state.status == HealthStatus.loading
                ? null
                : () => controller.checkSystemStatus(),
            icon: state.status == HealthStatus.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Test Connection'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(HealthStatus status) {
    Color color;
    String label;

    switch (status) {
      case HealthStatus.connected:
        color = AppColors.success;
        label = 'Connected';
        break;
      case HealthStatus.loading:
        color = AppColors.warning;
        label = 'Checking...';
        break;
      case HealthStatus.disconnected:
      case HealthStatus.initial:
        color = AppColors.error;
        label = 'Offline';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondaryDark,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

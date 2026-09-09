import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:instant_reel/core/router/route_names.dart';
import 'package:instant_reel/features/auth/domain/models/user_model.dart';
import 'package:instant_reel/features/auth/presentation/controllers/auth_controller.dart';
import 'package:instant_reel/features/auth/presentation/views/home_screen.dart';
import 'package:instant_reel/features/auth/presentation/views/login_screen.dart';
import 'package:instant_reel/features/auth/presentation/views/otp_screen.dart';
import 'package:instant_reel/features/auth/presentation/views/role_selection_screen.dart';
import 'package:instant_reel/features/auth/presentation/views/splash_screen.dart';
import 'package:instant_reel/features/creator/presentation/views/creator_booking_workflow_view.dart';
import 'package:instant_reel/features/creator/presentation/views/creator_dashboard_view.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';
import 'package:instant_reel/features/customer/presentation/views/booking_detail_view.dart';
import 'package:instant_reel/features/customer/presentation/views/booking_flow_view.dart';
import 'package:instant_reel/features/customer/presentation/views/booking_success_view.dart';
import 'package:instant_reel/features/customer/presentation/views/customer_dashboard_view.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.otp,
        name: RouteNames.otp,
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: RoutePaths.roleSelection,
        name: RouteNames.roleSelection,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) {
          final user = ref.watch(currentUserProvider);
          if (user?.role == UserRole.creator) {
            return const CreatorDashboardView();
          }
          return const CustomerDashboardView();
        },
      ),
      GoRoute(
        path: RoutePaths.customerDashboard,
        name: RouteNames.customerDashboard,
        builder: (context, state) => const CustomerDashboardView(),
      ),
      GoRoute(
        path: RoutePaths.creatorDashboard,
        name: RouteNames.creatorDashboard,
        builder: (context, state) => const CreatorDashboardView(),
      ),
      GoRoute(
        path: '${RoutePaths.creatorBooking}/:id',
        name: RouteNames.creatorBooking,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CreatorBookingWorkflowView(bookingId: id);
        },
      ),
      GoRoute(
        path: RoutePaths.bookingFlow,
        name: RouteNames.bookingFlow,
        builder: (context, state) => const BookingFlowView(),
      ),
      GoRoute(
        path: '${RoutePaths.bookingSuccess}/:id',
        name: RouteNames.bookingSuccess,
        builder: (context, state) {
          final booking = state.extra as BookingModel?;
          return BookingSuccessView(booking: booking);
        },
      ),
      GoRoute(
        path: '${RoutePaths.bookingDetail}/:id',
        name: RouteNames.bookingDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return BookingDetailView(bookingId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page Not Found: ${state.uri}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.customerDashboard),
              child: const Text('Return to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});

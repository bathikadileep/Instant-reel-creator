import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/features/creator/data/repositories/creator_repository_impl.dart';
import 'package:instant_reel/features/creator/domain/models/creator_dashboard_model.dart';
import 'package:instant_reel/features/creator/domain/repositories/creator_repository.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';

class CreatorDashboardState {
  final AsyncValue<CreatorDashboardModel> stats;
  final String activeTab; // 'today', 'active', 'completed', 'all'
  final List<BookingModel> tabBookings;
  final bool isLoadingTab;
  final String? error;

  const CreatorDashboardState({
    required this.stats,
    this.activeTab = 'today',
    this.tabBookings = const [],
    this.isLoadingTab = false,
    this.error,
  });

  CreatorDashboardState copyWith({
    AsyncValue<CreatorDashboardModel>? stats,
    String? activeTab,
    List<BookingModel>? tabBookings,
    bool? isLoadingTab,
    String? error,
  }) {
    return CreatorDashboardState(
      stats: stats ?? this.stats,
      activeTab: activeTab ?? this.activeTab,
      tabBookings: tabBookings ?? this.tabBookings,
      isLoadingTab: isLoadingTab ?? this.isLoadingTab,
      error: error,
    );
  }
}

final creatorDashboardControllerProvider =
    StateNotifierProvider.autoDispose<CreatorDashboardController, CreatorDashboardState>((ref) {
  final repository = ref.watch(creatorRepositoryProvider);
  return CreatorDashboardController(repository);
});

class CreatorDashboardController extends StateNotifier<CreatorDashboardState> {
  final CreatorRepository _repository;

  CreatorDashboardController(this._repository)
      : super(const CreatorDashboardState(stats: AsyncValue.loading())) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(stats: const AsyncValue.loading(), error: null);
    try {
      final statsData = await _repository.getDashboardStats();
      state = state.copyWith(
        stats: AsyncValue.data(statsData),
        tabBookings: statsData.todayBookings,
        activeTab: 'today',
      );
    } catch (e, st) {
      state = state.copyWith(
        stats: AsyncValue.error(e, st),
        error: e.toString(),
      );
    }
  }

  Future<void> selectTab(String tab) async {
    if (state.activeTab == tab && state.tabBookings.isNotEmpty) return;
    state = state.copyWith(activeTab: tab, isLoadingTab: true);
    try {
      final bookings = await _repository.getCreatorBookings(tab: tab);
      state = state.copyWith(
        tabBookings: bookings,
        isLoadingTab: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingTab: false,
        error: e.toString(),
      );
    }
  }

  Future<void> toggleAvailability(bool isAvailable) async {
    final currentStats = state.stats.valueOrNull;
    if (currentStats == null) return;

    // Optimistic UI update
    state = state.copyWith(
      stats: AsyncValue.data(currentStats.copyWith(isAvailable: isAvailable)),
    );

    try {
      final updated = await _repository.toggleAvailability(isAvailable);
      state = state.copyWith(
        stats: AsyncValue.data(currentStats.copyWith(isAvailable: updated)),
      );
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        stats: AsyncValue.data(currentStats),
        error: 'Failed to update availability: ${e.toString()}',
      );
    }
  }

  Future<void> refresh() async {
    await loadDashboard();
    if (state.activeTab != 'today') {
      await selectTab(state.activeTab);
    }
  }
}

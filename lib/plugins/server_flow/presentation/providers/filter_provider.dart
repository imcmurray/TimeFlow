import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/providers/server_flow_providers.dart';

/// Filter state for ServerFlow events.
class ServerFlowFilter {
  final Set<String> selectedHosts;
  final Set<String> selectedCategories;
  final Set<String> selectedUsers;
  final double? timeRangeStartHour;
  final double? timeRangeEndHour;

  const ServerFlowFilter({
    this.selectedHosts = const {},
    this.selectedCategories = const {},
    this.selectedUsers = const {},
    this.timeRangeStartHour,
    this.timeRangeEndHour,
  });

  bool get isActive =>
      selectedHosts.isNotEmpty ||
      selectedCategories.isNotEmpty ||
      selectedUsers.isNotEmpty ||
      timeRangeStartHour != null ||
      timeRangeEndHour != null;

  ServerFlowFilter copyWith({
    Set<String>? selectedHosts,
    Set<String>? selectedCategories,
    Set<String>? selectedUsers,
    double? Function()? timeRangeStartHour,
    double? Function()? timeRangeEndHour,
  }) {
    return ServerFlowFilter(
      selectedHosts: selectedHosts ?? this.selectedHosts,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedUsers: selectedUsers ?? this.selectedUsers,
      timeRangeStartHour: timeRangeStartHour != null
          ? timeRangeStartHour()
          : this.timeRangeStartHour,
      timeRangeEndHour: timeRangeEndHour != null
          ? timeRangeEndHour()
          : this.timeRangeEndHour,
    );
  }
}

/// Manages the filter state for ServerFlow events.
class ServerFlowFilterNotifier extends Notifier<ServerFlowFilter> {
  @override
  ServerFlowFilter build() => const ServerFlowFilter();

  void toggleHost(String host) {
    final hosts = Set<String>.from(state.selectedHosts);
    if (hosts.contains(host)) {
      hosts.remove(host);
    } else {
      hosts.add(host);
    }
    state = state.copyWith(selectedHosts: hosts);
  }

  void toggleCategory(String category) {
    final categories = Set<String>.from(state.selectedCategories);
    if (categories.contains(category)) {
      categories.remove(category);
    } else {
      categories.add(category);
    }
    state = state.copyWith(selectedCategories: categories);
  }

  void toggleUser(String user) {
    final users = Set<String>.from(state.selectedUsers);
    if (users.contains(user)) {
      users.remove(user);
    } else {
      users.add(user);
    }
    state = state.copyWith(selectedUsers: users);
  }

  void setTimeRange(double startHour, double endHour) {
    state = state.copyWith(
      timeRangeStartHour: () => startHour,
      timeRangeEndHour: () => endHour,
    );
  }

  void clearTimeRange() {
    state = state.copyWith(
      timeRangeStartHour: () => null,
      timeRangeEndHour: () => null,
    );
  }

  void reset() {
    state = const ServerFlowFilter();
  }
}

final serverFlowFilterProvider =
    NotifierProvider<ServerFlowFilterNotifier, ServerFlowFilter>(
  ServerFlowFilterNotifier.new,
);

/// Available hosts from imported cron jobs.
final availableHostsProvider = FutureProvider<List<String>>((ref) async {
  ref.watch(cronJobNotifierProvider);
  final repo = ref.read(cronJobRepositoryProvider);
  return repo.getDistinctHosts();
});

/// Available categories from imported cron jobs.
final availableCategoriesProvider = FutureProvider<List<String>>((ref) async {
  ref.watch(cronJobNotifierProvider);
  final repo = ref.read(cronJobRepositoryProvider);
  return repo.getDistinctCategories();
});

/// Available users from imported cron jobs.
final availableUsersProvider = FutureProvider<List<String>>((ref) async {
  ref.watch(cronJobNotifierProvider);
  final repo = ref.read(cronJobRepositoryProvider);
  return repo.getDistinctUsers();
});

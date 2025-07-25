import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medication_log.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

// Health filter state
class HealthFilterState {
  final String statusFilter;
  final String medicationFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<MedicationLog> filteredLogs;
  final bool isLoading;

  const HealthFilterState({
    this.statusFilter = 'all',
    this.medicationFilter = 'all',
    this.startDate,
    this.endDate,
    this.filteredLogs = const [],
    this.isLoading = false,
  });

  HealthFilterState copyWith({
    String? statusFilter,
    String? medicationFilter,
    DateTime? startDate,
    DateTime? endDate,
    List<MedicationLog>? filteredLogs,
    bool? isLoading,
  }) {
    return HealthFilterState(
      statusFilter: statusFilter ?? this.statusFilter,
      medicationFilter: medicationFilter ?? this.medicationFilter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      filteredLogs: filteredLogs ?? this.filteredLogs,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Health filter notifier
class HealthFilterNotifier extends StateNotifier<HealthFilterState> {
  final DatabaseService _databaseService;
  final AuthService _authService;

  HealthFilterNotifier(this._databaseService, this._authService) : super(const HealthFilterState()) {
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    state = state.copyWith(isLoading: true);
    try {
      // Get current user ID from auth service
      final userId = _authService.currentUserId;
      if (userId == null) {
        state = state.copyWith(
          filteredLogs: [],
          isLoading: false,
        );
        return;
      }

      // Get user's medication logs by filtering for their medications
      final userMedications = await _databaseService.getUserMedications(userId);
      final userMedicationIds = userMedications.map((med) => med['id'] as String).toList();
      
      final allLogs = await _databaseService.getMedicationLogs(
        startDate: state.startDate,
        endDate: state.endDate,
      );
      
      // Filter logs to only include those from user's medications
      final userLogs = allLogs.where((log) => userMedicationIds.contains(log.medicationId)).toList();
      final filteredLogs = _applyFilters(userLogs);
      
      state = state.copyWith(
        filteredLogs: filteredLogs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  List<MedicationLog> _applyFilters(List<MedicationLog> logs) {
    var filtered = logs;

    // Apply status filter
    if (state.statusFilter != 'all') {
      filtered = filtered.where((log) {
        return log.status.toString().split('.').last == state.statusFilter;
      }).toList();
    }

    // Apply medication filter
    if (state.medicationFilter != 'all') {
      filtered = filtered.where((log) {
        return log.medicationName.toLowerCase().contains(state.medicationFilter.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  void setStatusFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
    _loadLogs();
  }

  void setMedicationFilter(String filter) {
    state = state.copyWith(medicationFilter: filter);
    _loadLogs();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
    _loadLogs();
  }

  void clearFilters() {
    state = const HealthFilterState();
    _loadLogs();
  }

  void refreshLogs() {
    _loadLogs();
  }

  void clearUserData() {
    state = const HealthFilterState();
  }

  // Method to refresh logs from external triggers (e.g., when MedicationProvider updates logs)
  void refreshFromExternalUpdate() {
    _loadLogs();
  }
}

// Providers
final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final healthFilterProvider = StateNotifierProvider<HealthFilterNotifier, HealthFilterState>(
  (ref) => HealthFilterNotifier(
    ref.read(databaseServiceProvider),
    ref.read(authServiceProvider)
  ),
);

// Computed providers
final filteredHealthLogsProvider = Provider<List<MedicationLog>>((ref) {
  final filterState = ref.watch(healthFilterProvider);
  return filterState.filteredLogs;
});

final healthStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final logs = ref.watch(filteredHealthLogsProvider);
  
  final total = logs.length;
  final taken = logs.where((log) => log.status == MedicationStatus.taken).length;
  final missed = logs.where((log) => log.status == MedicationStatus.missed).length;
  final late = logs.where((log) => log.status == MedicationStatus.late).length;
  final pending = logs.where((log) => log.status == MedicationStatus.pending).length;
  final skipped = logs.where((log) => log.status == MedicationStatus.skipped).length;
  
  final adherenceRate = total > 0 ? (taken / total) * 100 : 0.0;
  
  return {
    'total': total,
    'taken': taken,
    'missed': missed,
    'late': late,
    'pending': pending,
    'skipped': skipped,
    'adherenceRate': adherenceRate,
  };
});

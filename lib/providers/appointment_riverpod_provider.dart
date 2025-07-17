import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment.dart';
import '../services/database_service.dart';
import 'health_filter_provider.dart';

// Appointment editing state
class AppointmentEditingState {
  final Appointment? currentAppointment;
  final bool isEditing;
  final bool isLoading;
  final String? error;

  const AppointmentEditingState({
    this.currentAppointment,
    this.isEditing = false,
    this.isLoading = false,
    this.error,
  });

  AppointmentEditingState copyWith({
    Appointment? currentAppointment,
    bool? isEditing,
    bool? isLoading,
    String? error,
  }) {
    return AppointmentEditingState(
      currentAppointment: currentAppointment ?? this.currentAppointment,
      isEditing: isEditing ?? this.isEditing,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Appointment editing notifier
class AppointmentEditingNotifier extends StateNotifier<AppointmentEditingState> {
  final DatabaseService _databaseService;

  AppointmentEditingNotifier(this._databaseService) : super(const AppointmentEditingState());

  void startEditing(Appointment appointment) {
    state = state.copyWith(
      currentAppointment: appointment,
      isEditing: true,
      error: null,
    );
  }

  void cancelEditing() {
    state = const AppointmentEditingState();
  }

  Future<bool> saveAppointment(Appointment appointment) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final appointmentMap = appointment.toMap();
      await _databaseService.updateUserAppointment(appointment.id, appointmentMap);
      state = const AppointmentEditingState();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save appointment: $e',
      );
      return false;
    }
  }

  Future<bool> deleteAppointment(String appointmentId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _databaseService.deleteUserAppointment(appointmentId);
      state = const AppointmentEditingState();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete appointment: $e',
      );
      return false;
    }
  }

  Future<bool> updateAppointmentStatus(String appointmentId, AppointmentStatus status) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final appointment = state.currentAppointment?.copyWith(status: status);
      if (appointment != null) {
        final appointmentMap = appointment.toMap();
        await _databaseService.updateUserAppointment(appointment.id, appointmentMap);
      }
      state = const AppointmentEditingState();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update appointment status: $e',
      );
      return false;
    }
  }
}

// Appointment filter state
class AppointmentFilterState {
  final String statusFilter;
  final String doctorFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<Appointment> filteredAppointments;
  final bool isLoading;

  const AppointmentFilterState({
    this.statusFilter = 'all',
    this.doctorFilter = 'all',
    this.startDate,
    this.endDate,
    this.filteredAppointments = const [],
    this.isLoading = false,
  });

  AppointmentFilterState copyWith({
    String? statusFilter,
    String? doctorFilter,
    DateTime? startDate,
    DateTime? endDate,
    List<Appointment>? filteredAppointments,
    bool? isLoading,
  }) {
    return AppointmentFilterState(
      statusFilter: statusFilter ?? this.statusFilter,
      doctorFilter: doctorFilter ?? this.doctorFilter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      filteredAppointments: filteredAppointments ?? this.filteredAppointments,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Appointment filter notifier
class AppointmentFilterNotifier extends StateNotifier<AppointmentFilterState> {
  final DatabaseService _databaseService;

  AppointmentFilterNotifier(this._databaseService) : super(const AppointmentFilterState()) {
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    state = state.copyWith(isLoading: true);
    try {
      final appointmentMaps = await _databaseService.getUserAppointments('current_user');
      final appointments = appointmentMaps.map((map) => Appointment.fromMap(map)).toList();
      final filteredAppointments = _applyFilters(appointments);
      state = state.copyWith(
        filteredAppointments: filteredAppointments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  List<Appointment> _applyFilters(List<Appointment> appointments) {
    var filtered = appointments;

    // Apply status filter
    if (state.statusFilter != 'all') {
      filtered = filtered.where((appointment) {
        return appointment.status.toString().split('.').last == state.statusFilter;
      }).toList();
    }

    // Apply doctor filter
    if (state.doctorFilter != 'all') {
      filtered = filtered.where((appointment) {
        return appointment.doctorName.toLowerCase().contains(state.doctorFilter.toLowerCase());
      }).toList();
    }

    // Apply date range filter
    if (state.startDate != null) {
      filtered = filtered.where((appointment) {
        return appointment.dateTime.isAfter(state.startDate!) || 
               appointment.dateTime.isAtSameMomentAs(state.startDate!);
      }).toList();
    }

    if (state.endDate != null) {
      filtered = filtered.where((appointment) {
        return appointment.dateTime.isBefore(state.endDate!) || 
               appointment.dateTime.isAtSameMomentAs(state.endDate!);
      }).toList();
    }

    return filtered;
  }

  void setStatusFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
    _loadAppointments();
  }

  void setDoctorFilter(String filter) {
    state = state.copyWith(doctorFilter: filter);
    _loadAppointments();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
    _loadAppointments();
  }

  void clearFilters() {
    state = const AppointmentFilterState();
    _loadAppointments();
  }

  void refreshAppointments() {
    _loadAppointments();
  }
}

// Providers
final appointmentEditingProvider = StateNotifierProvider<AppointmentEditingNotifier, AppointmentEditingState>(
  (ref) => AppointmentEditingNotifier(ref.read(databaseServiceProvider)),
);

final appointmentFilterProvider = StateNotifierProvider<AppointmentFilterNotifier, AppointmentFilterState>(
  (ref) => AppointmentFilterNotifier(ref.read(databaseServiceProvider)),
);

// Computed providers
final filteredAppointmentsProvider = Provider<List<Appointment>>((ref) {
  final filterState = ref.watch(appointmentFilterProvider);
  return filterState.filteredAppointments;
});

final upcomingAppointmentsProvider = Provider<List<Appointment>>((ref) {
  final appointments = ref.watch(filteredAppointmentsProvider);
  final now = DateTime.now();
  
  return appointments.where((appointment) {
    return appointment.dateTime.isAfter(now) && 
           appointment.status == AppointmentStatus.scheduled;
  }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
});

final appointmentStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final appointments = ref.watch(filteredAppointmentsProvider);
  
  final total = appointments.length;
  final scheduled = appointments.where((apt) => apt.status == AppointmentStatus.scheduled).length;
  final completed = appointments.where((apt) => apt.status == AppointmentStatus.completed).length;
  final missed = appointments.where((apt) => apt.status == AppointmentStatus.missed).length;
  final cancelled = appointments.where((apt) => apt.status == AppointmentStatus.cancelled).length;
  
  final now = DateTime.now();
  final upcoming = appointments.where((apt) => 
    apt.dateTime.isAfter(now) && apt.status == AppointmentStatus.scheduled
  ).length;
  
  final overdue = appointments.where((apt) => 
    apt.dateTime.isBefore(now) && apt.status == AppointmentStatus.scheduled
  ).length;
  
  return {
    'total': total,
    'scheduled': scheduled,
    'completed': completed,
    'missed': missed,
    'cancelled': cancelled,
    'upcoming': upcoming,
    'overdue': overdue,
  };
});

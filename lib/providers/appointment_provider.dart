import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;
  bool _hasLoadedAppointments = false;

  // Filters
  String _searchQuery = '';
  String _typeFilter = '';
  AppointmentStatus? _statusFilter;
  String _sortBy = 'date'; // date, doctor, type

  List<Appointment> get appointments {
    // Auto-load appointments if not already loaded
    if (!_hasLoadedAppointments && !_isLoading) {
      // Use Future.microtask to avoid calling notifyListeners during build
      Future.microtask(() => loadAppointments());
    }
    return _filteredAppointments;
  }
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get typeFilter => _typeFilter;
  AppointmentStatus? get statusFilter => _statusFilter;
  String get sortBy => _sortBy;

  List<Appointment> get _filteredAppointments {
    var filtered = List<Appointment>.from(_appointments);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((apt) =>
        apt.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        apt.doctorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        apt.location.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Apply type filter
    if (_typeFilter.isNotEmpty) {
      filtered = filtered.where((apt) => apt.type == _typeFilter).toList();
    }

    // Apply status filter
    if (_statusFilter != null) {
      filtered = filtered.where((apt) => apt.status == _statusFilter).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'date':
        filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        break;
      case 'doctor':
        filtered.sort((a, b) => a.doctorName.compareTo(b.doctorName));
        break;
      case 'type':
        filtered.sort((a, b) => a.type.compareTo(b.type));
        break;
    }

    return filtered;
  }

  List<String> get appointmentTypes {
    return _appointments.map((apt) => apt.type).toSet().toList()..sort();
  }

  List<Appointment> get upcomingAppointments {
    final now = DateTime.now();
    return _appointments
        .where((apt) => apt.dateTime.isAfter(now) && apt.status == AppointmentStatus.scheduled)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Get next appointments for dashboard display (shows today's appointments and upcoming ones)
  List<Appointment> get nextAppointments {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _appointments
        .where((apt) => 
          apt.status == AppointmentStatus.scheduled && 
          (apt.dateTime.isAfter(today) || _isToday(apt.dateTime))
        )
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Helper method to check if a date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  List<Appointment> get todaysAppointments {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _appointments
        .where((apt) => 
          apt.dateTime.isAfter(startOfDay) && 
          apt.dateTime.isBefore(endOfDay)
        )
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Appointment? get nextAppointment {
    final upcoming = upcomingAppointments;
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  Future<void> loadAppointments() async {
    if (_hasLoadedAppointments) return;
    
    _setLoading(true);
    try {
      // Check if user is authenticated
      if (!_authService.isLoggedIn) {
        _appointments = [];
        _error = 'User not authenticated';
        _hasLoadedAppointments = true;
        return;
      }

      final userId = _authService.currentUserId!;
      
      // Load user-specific appointments from database
      final dbResults = await _databaseService.getUserAppointments(userId);
      
      // Convert database results to Appointment objects
      _appointments = dbResults.map((data) {
        return Appointment(
          id: data['id'] as String,
          title: data['title'] as String,
          description: data['description'] as String? ?? '',
          dateTime: DateTime.parse(data['dateTime'] as String),
          doctorName: data['doctorName'] as String? ?? '',
          location: data['location'] as String? ?? '',
          type: data['type'] as String,
          status: AppointmentStatus.values.firstWhere(
            (e) => e.toString().split('.').last == data['status'],
            orElse: () => AppointmentStatus.scheduled,
          ),
          notes: null, // Can be added from database later
        );
      }).toList();
      
      _error = null;
      _hasLoadedAppointments = true;
    } catch (e) {
      _error = e.toString();
      _appointments = [];
      _hasLoadedAppointments = true; // Mark as loaded even if error to prevent infinite retries
    } finally {
      _setLoading(false);
    }
  }

  // Method to refresh appointments (force reload)
  Future<void> refreshAppointments() async {
    _hasLoadedAppointments = false;
    await loadAppointments();
  }

  Future<void> addAppointment(Appointment appointment) async {
    _setLoading(true);
    try {
      if (!_authService.isLoggedIn) {
        throw Exception('User not authenticated');
      }

      final userId = _authService.currentUserId!;
      
      // Add appointment to database
      await _databaseService.addUserAppointment({
        'id': appointment.id,
        'userId': userId,
        'title': appointment.title,
        'description': appointment.description,
        'dateTime': appointment.dateTime.toIso8601String(),
        'doctorName': appointment.doctorName,
        'location': appointment.location,
        'type': appointment.type,
        'status': appointment.status.toString().split('.').last,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      // Schedule notification reminders
      await _notificationService.scheduleAppointmentReminder(
        id: appointment.id.hashCode,
        title: 'Appointment Reminder',
        body: 'You have an appointment with ${appointment.doctorName} tomorrow',
        scheduledTime: appointment.dateTime,
        payload: appointment.id,
      );

      await loadAppointments();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAppointment(Appointment appointment) async {
    _setLoading(true);
    try {
      if (!_authService.isLoggedIn) {
        throw Exception('User not authenticated');
      }

      final userId = _authService.currentUserId!;
      
      // Update appointment in database
      await _databaseService.updateUserAppointment(appointment.id, {
        'userId': userId,
        'title': appointment.title,
        'description': appointment.description,
        'dateTime': appointment.dateTime.toIso8601String(),
        'doctorName': appointment.doctorName,
        'location': appointment.location,
        'type': appointment.type,
        'status': appointment.status.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Reschedule notification reminders
      await _notificationService.scheduleAppointmentReminder(
        id: appointment.id.hashCode,
        title: 'Appointment Reminder',
        body: 'You have an appointment with ${appointment.doctorName} tomorrow',
        scheduledTime: appointment.dateTime,
        payload: appointment.id,
      );

      await loadAppointments();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    _setLoading(true);
    try {
      if (!_authService.isLoggedIn) {
        throw Exception('User not authenticated');
      }

      // Delete appointment from database
      await _databaseService.deleteUserAppointment(appointmentId);
      
      // Cancel notification reminders (use the appointment ID hash as notification ID)
      await _notificationService.cancelMedicationNotifications(appointmentId);
      
      await loadAppointments();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markAsCompleted(String appointmentId) async {
    final appointment = _appointments.firstWhere((apt) => apt.id == appointmentId);
    final updatedAppointment = appointment.copyWith(status: AppointmentStatus.completed);
    await updateAppointment(updatedAppointment);
  }

  Future<void> markAsMissed(String appointmentId) async {
    final appointment = _appointments.firstWhere((apt) => apt.id == appointmentId);
    final updatedAppointment = appointment.copyWith(status: AppointmentStatus.missed);
    await updateAppointment(updatedAppointment);
  }

  Future<void> rescheduleAppointment(String appointmentId, DateTime newDateTime) async {
    final appointment = _appointments.firstWhere((apt) => apt.id == appointmentId);
    final updatedAppointment = appointment.copyWith(
      dateTime: newDateTime,
      status: AppointmentStatus.scheduled,
    );
    await updateAppointment(updatedAppointment);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTypeFilter(String type) {
    _typeFilter = type;
    notifyListeners();
  }

  void setStatusFilter(AppointmentStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _typeFilter = '';
    _statusFilter = null;
    _sortBy = 'date';
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Statistics
  int get totalAppointments => _appointments.length;
  int get completedAppointments => _appointments.where((apt) => apt.status == AppointmentStatus.completed).length;
  int get missedAppointments => _appointments.where((apt) => apt.status == AppointmentStatus.missed).length;
  int get scheduledAppointments => _appointments.where((apt) => apt.status == AppointmentStatus.scheduled).length;

  double get attendanceRate {
    final total = completedAppointments + missedAppointments;
    if (total == 0) return 0.0;
    return (completedAppointments / total) * 100;
  }
}

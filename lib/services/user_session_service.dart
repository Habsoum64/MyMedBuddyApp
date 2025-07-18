import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/health_filter_provider.dart';
import '../providers/appointment_riverpod_provider.dart';
import 'auth_service.dart';

class UserSessionService {
  static final UserSessionService _instance = UserSessionService._internal();
  factory UserSessionService() => _instance;
  UserSessionService._internal();

  // Method to clear all user-specific data from Riverpod providers on logout
  void clearAllUserData(WidgetRef ref) {
    // Clear health filter data
    ref.read(healthFilterProvider.notifier).clearUserData();
    
    // Clear appointment data
    ref.read(appointmentFilterProvider.notifier).clearUserData();
    ref.read(appointmentEditingProvider.notifier).cancelEditing();
  }

  // Method to refresh all user data on login
  void refreshUserData(WidgetRef ref) {
    // Refresh health filter data
    ref.read(healthFilterProvider.notifier).refreshLogs();
    
    // Refresh appointment data
    ref.read(appointmentFilterProvider.notifier).refreshAppointments();
  }

  // Method to check if user is authenticated and clear data if not
  void validateUserSession(WidgetRef ref) {
    final authService = AuthService();
    if (!authService.isLoggedIn) {
      clearAllUserData(ref);
    }
  }
}

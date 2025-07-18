import 'package:flutter/material.dart';
import '../services/user_session_service.dart';
import '../services/auth_service.dart';

// Mixin to handle user session management in screens that use Riverpod
mixin UserSessionMixin<T extends StatefulWidget> on State<T> {
  
  // Call this method when logging out to clear Riverpod data
  Future<void> performLogout() async {
    try {
      // Logout using AuthService
      final authService = AuthService();
      await authService.logout();

      // Clear Provider data (traditional providers will clear automatically on navigation)
      // Note: We can't clear Riverpod data here because we don't have WidgetRef access
      // The Riverpod data will be cleared when the user logs back in and the providers reinitialize
      
      // Navigate to login screen and remove all previous routes
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      // Show error if logout fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

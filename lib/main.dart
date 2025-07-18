import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider, Consumer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/navigation_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/health_tip_provider.dart';
import 'providers/theme_provider.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/preferences_service.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/login_screen.dart';

// Global instance for notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try to initialize Firebase (optional for our mock setup)
  try {
    await Firebase.initializeApp();
    // Firebase initialized successfully
  } catch (e) {
    // Firebase initialization failed (using mock data only)
    // Continue without Firebase - our app will work with local data only
  }
  
  // Initialize database
  await DatabaseService().database;
  
  // Initialize preferences service
  await PreferencesService.init();
  
  // Initialize notifications
  await NotificationService().initialize();
  
  // Initialize authentication service
  await AuthService().initialize();
  
  runApp(
    ProviderScope(
      child: const MyMedBuddyApp(),
    ),
  );
}

class MyMedBuddyApp extends ConsumerWidget {
  const MyMedBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) {
          final medicationProvider = MedicationProvider();
          // Pass the Riverpod container to medication provider for cross-provider sync
          medicationProvider.setRiverpodContainer(ProviderScope.containerOf(context));
          return medicationProvider;
        }),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => HealthTipProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'MyMedBuddy',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuthStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.teal,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'MyMedBuddy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          );
        }
        
        final isLoggedIn = snapshot.data ?? false;
        return isLoggedIn ? const MainNavigationScreen() : const LoginScreen();
      },
    );
  }

  Future<bool> _checkAuthStatus() async {
    // Small delay to show splash screen
    await Future.delayed(const Duration(milliseconds: 1500));
    return AuthService().isLoggedIn;
  }
}

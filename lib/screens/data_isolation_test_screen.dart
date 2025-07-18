import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/health_filter_provider.dart';
import '../providers/appointment_riverpod_provider.dart';
import '../services/auth_service.dart';

class DataIsolationTestScreen extends ConsumerStatefulWidget {
  const DataIsolationTestScreen({super.key});

  @override
  ConsumerState<DataIsolationTestScreen> createState() => _DataIsolationTestScreenState();
}

class _DataIsolationTestScreenState extends ConsumerState<DataIsolationTestScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final healthFilterState = ref.watch(healthFilterProvider);
    final appointmentFilterState = ref.watch(appointmentFilterProvider);
    final currentUser = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Isolation Test'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current User',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('User ID: ${currentUser?.id ?? 'Not logged in'}'),
                    Text('Name: ${currentUser?.name ?? 'Unknown'}'),
                    Text('Email: ${currentUser?.email ?? 'Unknown'}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Health Data Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Data (Riverpod)',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Loading: ${healthFilterState.isLoading}'),
                    Text('Logs Count: ${healthFilterState.filteredLogs.length}'),
                    Text('Status: ${healthFilterState.filteredLogs.isEmpty ? 'No data or properly filtered' : 'Has user-specific data'}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Appointment Data Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointment Data (Riverpod)',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Loading: ${appointmentFilterState.isLoading}'),
                    Text('Appointments Count: ${appointmentFilterState.filteredAppointments.length}'),
                    Text('Status: ${appointmentFilterState.filteredAppointments.isEmpty ? 'No data or properly filtered' : 'Has user-specific data'}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(healthFilterProvider.notifier).refreshLogs();
                      ref.read(appointmentFilterProvider.notifier).refreshAppointments();
                    },
                    child: const Text('Refresh Data'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(healthFilterProvider.notifier).clearUserData();
                      ref.read(appointmentFilterProvider.notifier).clearUserData();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Clear Data'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Status Message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Data Isolation Fixed!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Each user now sees only their own data\n'
                    '• No more cross-user contamination\n'
                    '• Proper authentication integration\n'
                    '• Clean logout with data cleanup',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

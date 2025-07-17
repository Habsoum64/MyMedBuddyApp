import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/appointment_provider.dart';
import '../models/appointment.dart';
import 'custom_cards.dart';

class OptimizedAppointmentList extends StatelessWidget {
  final Function(Appointment) onEdit;
  final Function(Appointment) onDelete;
  final Function(Appointment) onMarkCompleted;
  final Function(Appointment) onMarkMissed;
  final VoidCallback onRetry;

  const OptimizedAppointmentList({
    super.key,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkCompleted,
    required this.onMarkMissed,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<AppointmentProvider, AppointmentListData>(
      selector: (_, provider) => AppointmentListData(
        appointments: provider.appointments,
        isLoading: provider.isLoading,
        error: provider.error,
      ),
      builder: (context, data, child) {
        if (data.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (data.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading appointments',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  data.error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (data.appointments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No appointments found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Add your first appointment to get started',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.appointments.length,
          itemBuilder: (context, index) {
            final appointment = data.appointments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppointmentCard(
                title: appointment.title,
                doctorName: appointment.doctorName,
                location: appointment.location,
                dateTime: appointment.dateTime,
                type: appointment.type,
                statusColor: _getStatusColor(appointment.status),
                onTap: () => onEdit(appointment),
                onEdit: () => onEdit(appointment),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.orange;
      case AppointmentStatus.missed:
        return Colors.red;
    }
  }
}

class AppointmentListData {
  final List<Appointment> appointments;
  final bool isLoading;
  final String? error;

  AppointmentListData({
    required this.appointments,
    required this.isLoading,
    this.error,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentListData &&
          runtimeType == other.runtimeType &&
          appointments.length == other.appointments.length &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => appointments.length.hashCode ^ isLoading.hashCode ^ error.hashCode;
}

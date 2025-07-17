import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/appointment_provider.dart';
import '../widgets/custom_cards.dart';
import '../widgets/custom_forms.dart';
import '../models/appointment.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load appointments when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().loadAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and add button
        Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    context.read<AppointmentProvider>().setSearchQuery(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search appointments...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[100],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilters,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _showAddAppointmentDialog,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Appointments list
        Expanded(
          child: Consumer<AppointmentProvider>(
            builder: (context, appointmentProvider, child) {
              if (appointmentProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (appointmentProvider.error != null) {
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
                        appointmentProvider.error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => appointmentProvider.loadAppointments(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final appointments = appointmentProvider.appointments;
              
              if (appointments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No appointments found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text('Add your first appointment to get started'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddAppointmentDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Appointment'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await appointmentProvider.loadAppointments();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    final statusColor = _getStatusColor(appointment.status);
                    
                    return AppointmentCard(
                      title: appointment.title,
                      doctorName: appointment.doctorName,
                      location: appointment.location,
                      dateTime: appointment.dateTime,
                      type: appointment.type,
                      statusColor: statusColor,
                      onTap: () => _showAppointmentDetail(appointment),
                      onEdit: () => _showEditAppointmentDialog(appointment),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
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

  void _showFilters() {
    final appointmentProvider = context.read<AppointmentProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Appointments'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Type'),
              value: appointmentProvider.typeFilter.isEmpty 
                ? null 
                : appointmentProvider.typeFilter,
              items: ['', ...appointmentProvider.appointmentTypes].map((type) {
                return DropdownMenuItem<String>(
                  value: type.isEmpty ? null : type,
                  child: Text(type.isEmpty ? 'All Types' : type),
                );
              }).toList(),
              onChanged: (value) => appointmentProvider.setTypeFilter(value ?? ''),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AppointmentStatus?>(
              decoration: const InputDecoration(labelText: 'Status'),
              value: appointmentProvider.statusFilter,
              items: [null, ...AppointmentStatus.values].map((status) {
                return DropdownMenuItem<AppointmentStatus?>(
                  value: status,
                  child: Text(status == null ? 'All Statuses' : status.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) => appointmentProvider.setStatusFilter(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              appointmentProvider.clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Appointment',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: AppointmentForm(
                    onSave: (appointment) {
                      context.read<AppointmentProvider>().addAppointment(appointment);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Appointment added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditAppointmentDialog(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Appointment',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: AppointmentForm(
                    appointment: appointment,
                    onSave: (updatedAppointment) {
                      context.read<AppointmentProvider>().updateAppointment(updatedAppointment);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Appointment updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppointmentDetail(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appointment.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow(label: 'Doctor', value: appointment.doctorName),
              _DetailRow(label: 'Location', value: appointment.location),
              _DetailRow(label: 'Type', value: appointment.type),
              _DetailRow(label: 'Date & Time', value: DateFormat('MMM d, y • h:mm a').format(appointment.dateTime)),
              _DetailRow(label: 'Status', value: appointment.status.toString().split('.').last),
              if (appointment.description.isNotEmpty)
                _DetailRow(label: 'Description', value: appointment.description),
              if (appointment.notes != null && appointment.notes!.isNotEmpty)
                _DetailRow(label: 'Notes', value: appointment.notes!),
            ],
          ),
        ),
        actions: [
          if (appointment.status == AppointmentStatus.scheduled) ...[
            TextButton(
              onPressed: () => _markAsCompleted(appointment),
              child: const Text('Mark Completed'),
            ),
            TextButton(
              onPressed: () => _markAsMissed(appointment),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Mark Missed'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditAppointmentDialog(appointment);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () => _showDeleteConfirmation(appointment),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: Text('Are you sure you want to delete this appointment with ${appointment.doctorName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppointmentProvider>().deleteAppointment(appointment.id);
              Navigator.pop(context); // Close confirmation
              Navigator.pop(context); // Close detail dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appointment deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _markAsCompleted(Appointment appointment) {
    context.read<AppointmentProvider>().markAsCompleted(appointment.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appointment marked as completed'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _markAsMissed(Appointment appointment) {
    context.read<AppointmentProvider>().markAsMissed(appointment.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appointment marked as missed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

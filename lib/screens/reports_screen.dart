import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../providers/appointment_provider.dart';
import '../models/appointment.dart';
import '../models/medication_log.dart';
import '../services/export_service.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final ExportService _exportService = ExportService();
  String _selectedReportType = 'medication_adherence';
  DateTimeRange? _selectedDateRange;
  List<MedicationLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _databaseService.getMedicationLogs();
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  List<MedicationLog> get _filteredLogs {
    if (_selectedDateRange == null) return _logs;
    
    return _logs.where((log) {
      return log.scheduledTime.isAfter(_selectedDateRange!.start) &&
             log.scheduledTime.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportCurrentReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildReportControls(),
                Expanded(
                  child: _buildReportContent(),
                ),
              ],
            ),
    );
  }

  Widget _buildReportControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[600]!
                : Colors.grey[300]!,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedReportType,
                  decoration: const InputDecoration(
                    labelText: 'Report Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'medication_adherence',
                      child: Text('Medication Adherence'),
                    ),
                    DropdownMenuItem(
                      value: 'appointment_summary',
                      child: Text('Appointment Summary'),
                    ),
                    DropdownMenuItem(
                      value: 'health_overview',
                      child: Text('Health Overview'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedReportType = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: _selectDateRange,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    _selectedDateRange == null
                        ? 'Date Range'
                        : '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          if (_selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Range: ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDateRange = null;
                      });
                    },
                    style: TextButton.styleFrom(
                      minimumSize: const Size(50, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    switch (_selectedReportType) {
      case 'medication_adherence':
        return _buildMedicationAdherenceReport();
      case 'appointment_summary':
        return _buildAppointmentSummaryReport();
      case 'health_overview':
        return _buildHealthOverviewReport();
      default:
        return const Center(child: Text('Select a report type'));
    }
  }

  Widget _buildMedicationAdherenceReport() {
    final logs = _filteredLogs;
    if (logs.isEmpty) {
      return const Center(
        child: Text('No medication logs found for the selected period'),
      );
    }

    final total = logs.length;
    final taken = logs.where((log) => log.status == MedicationStatus.taken).length;
    final missed = logs.where((log) => log.status == MedicationStatus.missed).length;
    final skipped = logs.where((log) => log.status == MedicationStatus.skipped).length;
    final adherenceRate = total > 0 ? (taken / total) * 100 : 0.0;

    // Group by medication
    final medicationGroups = <String, List<MedicationLog>>{};
    for (final log in logs) {
      medicationGroups.putIfAbsent(log.medicationName, () => []).add(log);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Adherence',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('Total', total.toString(), Colors.blue),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildStatCard('Taken', taken.toString(), Colors.green),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildStatCard('Missed', missed.toString(), Colors.red),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildStatCard('Skipped', skipped.toString(), Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: adherenceRate / 100,
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      adherenceRate >= 80 ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adherence Rate: ${adherenceRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: adherenceRate >= 80 ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Per Medication Breakdown
          Text(
            'Medication Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...medicationGroups.entries.map((entry) {
            final medicationLogs = entry.value;
            final medTotal = medicationLogs.length;
            final medTaken = medicationLogs.where((log) => log.status == MedicationStatus.taken).length;
            final medAdherence = medTotal > 0 ? (medTaken / medTotal) * 100 : 0.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(entry.key),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$medTaken/$medTotal doses taken'),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: medAdherence / 100,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]
                          : Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        medAdherence >= 80 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  '${medAdherence.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: medAdherence >= 80 ? Colors.green : Colors.orange,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Individual Logs',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...medicationLogs.map((log) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(log.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getStatusColor(log.status).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(log.status).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  _getStatusIcon(log.status),
                                  color: _getStatusColor(log.status),
                                  size: 16,
                                ),
                              ),
                              title: Text(
                                DateFormat('MMM dd, yyyy').format(log.scheduledTime),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scheduled: ${DateFormat('h:mm a').format(log.scheduledTime)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (log.takenTime != null)
                                    Text(
                                      'Taken: ${DateFormat('h:mm a').format(log.takenTime!)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  if (log.notes != null && log.notes!.isNotEmpty)
                                    Text(
                                      'Notes: ${log.notes}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(log.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(log.status),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAppointmentSummaryReport() {
    return Consumer<AppointmentProvider>(
      builder: (context, appointmentProvider, child) {
        var appointments = appointmentProvider.appointments;
        
        if (_selectedDateRange != null) {
          appointments = appointments.where((apt) {
            return apt.dateTime.isAfter(_selectedDateRange!.start) &&
                   apt.dateTime.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
          }).toList();
        }

        if (appointments.isEmpty) {
          return const Center(
            child: Text('No appointments found for the selected period'),
          );
        }

        final completed = appointments.where((apt) => apt.status == AppointmentStatus.completed).length;
        final upcoming = appointments.where((apt) => apt.dateTime.isAfter(DateTime.now()) && apt.status == AppointmentStatus.scheduled).length;
        final overdue = appointments.where((apt) => apt.dateTime.isBefore(DateTime.now()) && apt.status == AppointmentStatus.scheduled).length;

        // Group by doctor
        final doctorGroups = <String, List<Appointment>>{};
        for (final apt in appointments) {
          doctorGroups.putIfAbsent(apt.doctorName, () => []).add(apt);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Statistics
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointment Summary',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('Total', appointments.length.toString(), Colors.blue),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildStatCard('Done', completed.toString(), Colors.green),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildStatCard('Coming', upcoming.toString(), Colors.orange),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildStatCard('Overdue', overdue.toString(), Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Doctor Breakdown
              Text(
                'Appointments by Doctor',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...doctorGroups.entries.map((entry) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Text(entry.key),
                    subtitle: Text('${entry.value.length} appointments'),
                    children: entry.value.map((apt) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getAppointmentStatusColor(apt.status, apt.dateTime).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getAppointmentStatusColor(apt.status, apt.dateTime).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _getAppointmentStatusColor(apt.status, apt.dateTime).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              _getAppointmentStatusIcon(apt.status, apt.dateTime),
                              color: _getAppointmentStatusColor(apt.status, apt.dateTime),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            apt.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('MMM dd, yyyy - hh:mm a').format(apt.dateTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getAppointmentStatusColor(apt.status, apt.dateTime),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getAppointmentStatusText(apt.status, apt.dateTime),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthOverviewReport() {
    return Consumer2<MedicationProvider, AppointmentProvider>(
      builder: (context, medicationProvider, appointmentProvider, child) {
        final medications = medicationProvider.medications;
        final appointments = appointmentProvider.appointments;
        final logs = _filteredLogs;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Health Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('Active Meds', medications.length.toString(), Colors.blue),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildStatCard('Appointments', appointments.length.toString(), Colors.green),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildStatCard('Med Logs', logs.length.toString(), Colors.orange),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Medication Status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medication Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (medications.isEmpty)
                        const Text('No active medications')
                      else
                        ...medications.map((med) {
                          return ListTile(
                            leading: const Icon(Icons.medication),
                            title: Text(med.name),
                            subtitle: Text('${med.dosage} - ${med.frequency}'),
                            trailing: Chip(
                              label: Text(med.isActive ? 'Active' : 'Inactive'),
                              backgroundColor: med.isActive ? Colors.green[100] : Colors.grey[300],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Recent Activity
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (logs.isEmpty)
                        const Text('No recent medication logs')
                      else
                        ...logs.take(5).map((log) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(log.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getStatusColor(log.status).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(log.status).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  _getStatusIcon(log.status),
                                  color: _getStatusColor(log.status),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                log.medicationName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat('MMM dd, yyyy - hh:mm a').format(log.scheduledTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(log.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(log.status),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _exportCurrentReport() async {
    try {
      String filename;
      switch (_selectedReportType) {
        case 'medication_adherence':
          filename = await _exportService.exportMedicationLogsToPDF();
          break;
        case 'appointment_summary':
          filename = await _exportService.exportAppointmentSummaryToPDF();
          break;
        case 'health_overview':
          filename = await _exportService.exportHealthOverviewToPDF();
          break;
        default:
          throw Exception('Unknown report type');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report exported: $filename')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  // Helper methods for status styling
  Color _getStatusColor(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.taken:
        return Colors.green;
      case MedicationStatus.missed:
        return Colors.red;
      case MedicationStatus.skipped:
        return Colors.orange;
      case MedicationStatus.pending:
        return Colors.blue;
      case MedicationStatus.late:
        return Colors.amber;
    }
  }

  IconData _getStatusIcon(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.taken:
        return Icons.check_circle;
      case MedicationStatus.missed:
        return Icons.error;
      case MedicationStatus.skipped:
        return Icons.cancel;
      case MedicationStatus.pending:
        return Icons.schedule;
      case MedicationStatus.late:
        return Icons.warning;
    }
  }

  String _getStatusText(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.taken:
        return 'TAKEN';
      case MedicationStatus.missed:
        return 'MISSED';
      case MedicationStatus.skipped:
        return 'SKIPPED';
      case MedicationStatus.pending:
        return 'PENDING';
      case MedicationStatus.late:
        return 'LATE';
    }
  }

  // Helper methods for appointment status styling
  Color _getAppointmentStatusColor(AppointmentStatus status, DateTime dateTime) {
    switch (status) {
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.missed:
        return Colors.red;
      case AppointmentStatus.scheduled:
        return dateTime.isBefore(DateTime.now()) ? Colors.orange : Colors.blue;
    }
  }

  IconData _getAppointmentStatusIcon(AppointmentStatus status, DateTime dateTime) {
    switch (status) {
      case AppointmentStatus.completed:
        return Icons.check_circle;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      case AppointmentStatus.missed:
        return Icons.error;
      case AppointmentStatus.scheduled:
        return dateTime.isBefore(DateTime.now()) ? Icons.schedule_outlined : Icons.schedule;
    }
  }

  String _getAppointmentStatusText(AppointmentStatus status, DateTime dateTime) {
    switch (status) {
      case AppointmentStatus.completed:
        return 'COMPLETED';
      case AppointmentStatus.cancelled:
        return 'CANCELLED';
      case AppointmentStatus.missed:
        return 'MISSED';
      case AppointmentStatus.scheduled:
        return dateTime.isBefore(DateTime.now()) ? 'OVERDUE' : 'SCHEDULED';
    }
  }
}

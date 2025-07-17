import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../widgets/custom_cards.dart';
import '../widgets/medication_selection_form.dart';
import '../models/medication.dart';
import '../models/medication_log.dart';
import 'package:intl/intl.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    context.read<MedicationProvider>().setSearchQuery(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search medications...',
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
            ],
          ),
        ),
        
        // Medications list
        Expanded(
          child: Consumer<MedicationProvider>(
            builder: (context, medicationProvider, child) {
              if (medicationProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (medicationProvider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading medications',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        medicationProvider.error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => medicationProvider.refreshAllMedicationData(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final medications = medicationProvider.medications;
              
              if (medications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No medications found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text('Add your first medication to get started'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddMedicationDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Medication'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await medicationProvider.refreshAllMedicationData();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: medications.length,
                  itemBuilder: (context, index) {
                    final medication = medications[index];
                    final nextDose = _getNextDose(medication);
                    final isOverdue = _isOverdue(medication);
                    final nextDoseStatus = _getNextDoseStatus(medication);
                    
                    return MedicationCard(
                      name: medication.name,
                      dosage: medication.dosage,
                      frequency: medication.frequency,
                      nextDose: nextDose,
                      isOverdue: isOverdue,
                      nextDoseStatus: nextDoseStatus,
                      onTap: () => _showMedicationDetail(medication),
                      onEdit: () => _showEditMedicationDialog(medication),
                      onTaken: () => _markMedicationTaken(medication),
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

  void _showFilters() {
    final medicationProvider = context.read<MedicationProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Medications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
              value: medicationProvider.categoryFilter.isEmpty 
                ? null 
                : medicationProvider.categoryFilter,
              items: ['', ...medicationProvider.categories].map((category) {
                return DropdownMenuItem<String>(
                  value: category.isEmpty ? null : category,
                  child: Text(category.isEmpty ? 'All Categories' : category),
                );
              }).toList(),
              onChanged: (value) => medicationProvider.setCategoryFilter(value ?? ''),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Status'),
              value: medicationProvider.statusFilter.isEmpty 
                ? null 
                : medicationProvider.statusFilter,
              items: const ['', 'active', 'inactive', 'expired'].map((status) {
                return DropdownMenuItem<String>(
                  value: status.isEmpty ? null : status,
                  child: Text(status.isEmpty ? 'All Statuses' : status),
                );
              }).toList(),
              onChanged: (value) => medicationProvider.setStatusFilter(value ?? ''),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              medicationProvider.clearFilters();
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

  void _showAddMedicationDialog() {
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
                'Add Medication',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: MedicationSelectionForm(
                    onSave: (medication, catalogId) {
                      context.read<MedicationProvider>().addMedication(medication, catalogId);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Medication added successfully!'),
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

  void _showEditMedicationDialog(Medication medication) {
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
                'Edit Medication',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: MedicationSelectionForm(
                    medication: medication,
                    onSave: (updatedMedication, catalogId) {
                      context.read<MedicationProvider>().updateMedication(updatedMedication);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Medication updated successfully!'),
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

  void _showMedicationDetail(Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(medication.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow(label: 'Dosage', value: medication.dosage),
              _DetailRow(label: 'Frequency', value: medication.frequency),
              _DetailRow(label: 'Category', value: medication.category),
              _DetailRow(label: 'Start Date', value: DateFormat('MMM d, y').format(medication.startDate)),
              if (medication.endDate != null)
                _DetailRow(label: 'End Date', value: DateFormat('MMM d, y').format(medication.endDate!)),
              if (medication.instructions.isNotEmpty)
                _DetailRow(label: 'Instructions', value: medication.instructions),
              const SizedBox(height: 8),
              const Text('Times:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...medication.times.map((time) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text('• $time'),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditMedicationDialog(medication);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () => _showDeleteConfirmation(medication),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete ${medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<MedicationProvider>().deleteMedication(medication.id);
              Navigator.pop(context); // Close confirmation
              Navigator.pop(context); // Close detail dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${medication.name} deleted'),
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

  void _markMedicationTaken(Medication medication) {
    final medicationProvider = context.read<MedicationProvider>();
    final now = DateTime.now();
    
    // Get all pending and late logs for this medication
    final actionableLogs = medicationProvider.medicationLogs
        .where((log) => 
            log.medicationId == medication.id &&
            (log.status == MedicationStatus.pending || log.status == MedicationStatus.late))
        .toList();
    
    if (actionableLogs.isNotEmpty) {
      // Sort logs by scheduled time
      actionableLogs.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      
      // Find the most appropriate log to mark as taken
      MedicationLog? selectedLog;
      
      // Strategy 1: Find the closest overdue log (scheduled time in the past)
      for (final log in actionableLogs) {
        if (log.scheduledTime.isBefore(now)) {
          selectedLog = log;
          // Keep looking for a more recent overdue log
        } else {
          break; // We've reached future logs
        }
      }
      
      // Strategy 2: If no overdue log, take the next upcoming log
      if (selectedLog == null && actionableLogs.isNotEmpty) {
        selectedLog = actionableLogs.first;
      }
      
      if (selectedLog != null) {
        medicationProvider.logMedicationTaken(
          medication.id,
          medication.name,
          selectedLog.scheduledTime,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${medication.name} marked as taken'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // No pending logs exist, create a new log with current time
      medicationProvider.logMedicationTaken(
        medication.id,
        medication.name,
        now,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${medication.name} marked as taken'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _getNextDose(Medication medication) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Safety check: if no times are set, return a default message
    if (medication.times.isEmpty) {
      return 'No schedule set';
    }
    
    // Find the next scheduled time
    for (final timeString in medication.times) {
      final timeParts = timeString.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final scheduledTime = DateTime(today.year, today.month, today.day, hour, minute);
      
      if (scheduledTime.isAfter(now)) {
        return timeString;
      }
    }
    
    // If no more doses today, show first dose of tomorrow
    return '${medication.times.first} (tomorrow)';
  }

  // Get next dose status from medication logs
  MedicationStatus? _getNextDoseStatus(Medication medication) {
    final medicationProvider = context.read<MedicationProvider>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Safety check: if no times are set, return null
    if (medication.times.isEmpty) {
      return null;
    }
    
    // Find the next scheduled time and get its status from logs
    for (final timeString in medication.times) {
      final timeParts = timeString.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final scheduledTime = DateTime(today.year, today.month, today.day, hour, minute);
      
      if (scheduledTime.isAfter(now)) {
        // Find the log for this exact time
        try {
          final log = medicationProvider.medicationLogs.firstWhere(
            (log) => log.medicationId == medication.id && 
                     log.scheduledTime.isAtSameMomentAs(scheduledTime),
          );
          return log.status;
        } catch (e) {
          return null;
        }
      }
    }
    
    // If no more doses today, check tomorrow's first dose
    final tomorrow = today.add(const Duration(days: 1));
    final firstTimeString = medication.times.first;
    final timeParts = firstTimeString.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final tomorrowFirstDose = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
    
    try {
      final log = medicationProvider.medicationLogs.firstWhere(
        (log) => log.medicationId == medication.id && 
                 log.scheduledTime.isAtSameMomentAs(tomorrowFirstDose),
      );
      return log.status;
    } catch (e) {
      return null;
    }
  }

  bool _isOverdue(Medication medication) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Safety check: if no times are set, not overdue
    if (medication.times.isEmpty) {
      return false;
    }
    
    // Check if any dose today is overdue
    for (final timeString in medication.times) {
      final timeParts = timeString.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final scheduledTime = DateTime(today.year, today.month, today.day, hour, minute);
      
      if (scheduledTime.isBefore(now) && 
          now.difference(scheduledTime).inHours < 24) {
        return true;
      }
    }
    return false;
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

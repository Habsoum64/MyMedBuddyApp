import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/health_filter_provider.dart';
import '../models/medication_log.dart';
import 'package:intl/intl.dart';

class AdvancedHealthLogsScreen extends ConsumerStatefulWidget {
  const AdvancedHealthLogsScreen({super.key});

  @override
  ConsumerState<AdvancedHealthLogsScreen> createState() => _AdvancedHealthLogsScreenState();
}

class _AdvancedHealthLogsScreenState extends ConsumerState<AdvancedHealthLogsScreen> {
  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(healthFilterProvider);
    final statistics = ref.watch(healthStatisticsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Health Logs'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(healthFilterProvider.notifier).refreshLogs(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Controls
          _buildFilterControls(context),
          
          // Statistics
          _buildStatistics(statistics),
          
          // Logs List
          Expanded(
            child: filterState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filterState.filteredLogs.isEmpty
                    ? const Center(child: Text('No logs found'))
                    : ListView.builder(
                        itemCount: filterState.filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filterState.filteredLogs[index];
                          return _buildLogCard(log);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls(BuildContext context) {
    final filterState = ref.watch(healthFilterProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]!
                : Colors.grey[300]!,
          ),
        ),
      ),
      child: Column(
        children: [
          // Status Filter
          Row(
            children: [
              const Text('Status: '),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: filterState.statusFilter,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'taken', child: Text('Taken')),
                    DropdownMenuItem(value: 'missed', child: Text('Missed')),
                    DropdownMenuItem(value: 'late', child: Text('Late')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'skipped', child: Text('Skipped')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(healthFilterProvider.notifier).setStatusFilter(value);
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Date Range
          Row(
            children: [
              const Text('Date Range: '),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => _selectDateRange(context),
                      child: Text(
                        filterState.startDate != null && filterState.endDate != null
                            ? '${DateFormat('MM/dd').format(filterState.startDate!)} - ${DateFormat('MM/dd').format(filterState.endDate!)}'
                            : 'Select Range',
                      ),
                    ),
                    if (filterState.startDate != null || filterState.endDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => ref.read(healthFilterProvider.notifier).setDateRange(null, null),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          // Clear All Filters
          if (filterState.statusFilter != 'all' || 
              filterState.startDate != null || 
              filterState.endDate != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => ref.read(healthFilterProvider.notifier).clearFilters(),
                child: const Text('Clear All Filters'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatistics(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Statistics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildStatItem('Total', stats['total'].toString(), Colors.blue),
                  _buildStatItem('Taken', stats['taken'].toString(), Colors.green),
                  _buildStatItem('Missed', stats['missed'].toString(), Colors.red),
                  _buildStatItem('Late', stats['late'].toString(), Colors.orange),
                  _buildStatItem('Pending', stats['pending'].toString(), Colors.grey),
                  _buildStatItem('Adherence', '${stats['adherenceRate'].toStringAsFixed(1)}%', 
                    stats['adherenceRate'] >= 80 ? Colors.green : Colors.orange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLogCard(MedicationLog log) {
    final statusColor = _getStatusColor(log.status);
    final statusIcon = _getStatusIcon(log.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(log.medicationName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scheduled: ${DateFormat('MMM dd, yyyy HH:mm').format(log.scheduledTime)}'),
            if (log.takenTime != null)
              Text('Taken: ${DateFormat('MMM dd, yyyy HH:mm').format(log.takenTime!)}'),
            if (log.notes != null && log.notes!.isNotEmpty)
              Text('Notes: ${log.notes}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            log.status.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.taken:
        return Colors.green;
      case MedicationStatus.missed:
        return Colors.red;
      case MedicationStatus.late:
        return Colors.orange;
      case MedicationStatus.pending:
        return Colors.blue;
      case MedicationStatus.skipped:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.taken:
        return Icons.check_circle;
      case MedicationStatus.missed:
        return Icons.error;
      case MedicationStatus.late:
        return Icons.access_time;
      case MedicationStatus.pending:
        return Icons.schedule;
      case MedicationStatus.skipped:
        return Icons.cancel;
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final filterState = ref.read(healthFilterProvider);
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: filterState.startDate != null && filterState.endDate != null
          ? DateTimeRange(start: filterState.startDate!, end: filterState.endDate!)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      ref.read(healthFilterProvider.notifier).setDateRange(picked.start, picked.end);
    }
  }
}

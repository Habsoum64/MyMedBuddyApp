import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medication_log.dart';
import '../providers/medication_provider.dart';
import 'package:intl/intl.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> with AutomaticKeepAliveClientMixin {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedFilter = 'all'; // all, taken, missed, skipped
  bool _hasLoadedOnce = false;

  @override
  bool get wantKeepAlive => true; // Keep the state alive to avoid reloading

  @override
  void initState() {
    super.initState();
    // Load logs only when this screen is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLogsIfNeeded();
    });
  }

  Future<void> _loadLogsIfNeeded() async {
    if (!_hasLoadedOnce) {
      await _loadLogs();
      _hasLoadedOnce = true;
    }
  }

  Future<void> _loadLogs() async {
    final medicationProvider = context.read<MedicationProvider>();
    await medicationProvider.loadMedicationLogs(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  List<MedicationLog> _filterLogs(List<MedicationLog> logs) {
    if (_selectedFilter == 'all') return logs;
    
    return logs.where((log) {
      switch (_selectedFilter) {
        case 'taken':
          return log.status == MedicationStatus.taken;
        case 'missed':
          return log.status == MedicationStatus.missed;
        case 'skipped':
          return log.status == MedicationStatus.skipped;
        case 'late':
          return log.status == MedicationStatus.late;
        case 'pending':
          return log.status == MedicationStatus.pending;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Consumer<MedicationProvider>(
      builder: (context, medicationProvider, child) {
        final allLogs = medicationProvider.medicationLogs;
        final filteredLogs = _filterLogs(allLogs);
        final isLoading = medicationProvider.isLoading;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Medication Logs'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => medicationProvider.refreshAllMedicationData(),
              ),
              IconButton(
                icon: const Icon(Icons.file_download),
                onPressed: _exportLogs,
              ),
            ],
          ),
          body: Column(
            children: [
              // Filter chips
              Container(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip('All', 'all'),
                    _buildFilterChip('Taken', 'taken'),
                    _buildFilterChip('Late', 'late'),
                    _buildFilterChip('Missed', 'missed'),
                    _buildFilterChip('Pending', 'pending'),
                    _buildFilterChip('Skipped', 'skipped'),
                  ],
                ),
              ),
              
              // Date range display
              if (_startDate != null || _endDate != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.date_range, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        _getDateRangeText(),
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                          _loadLogs();
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              
              // Statistics
              _buildStatistics(filteredLogs),
              
              // Logs list
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredLogs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No medication logs found',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                const Text('Logs will appear here as you take medications'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => medicationProvider.refreshAllMedicationData(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredLogs.length,
                              itemBuilder: (context, index) {
                                final log = filteredLogs[index];
                                return _buildLogCard(log);
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        // No need to reload data - the Consumer will handle filtering
      },
      selectedColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.teal.shade300.withOpacity(0.3)
          : Theme.of(context).primaryColor.withOpacity(0.2),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[850]
          : Colors.grey[50],
      checkmarkColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.teal.shade300
          : Theme.of(context).primaryColor,
    );
  }

  Widget _buildStatistics(List<MedicationLog> logs) {
    // Only show statistics when viewing all logs
    if (logs.isEmpty || _selectedFilter != 'all') return const SizedBox.shrink();

    final total = logs.length;
    final taken = logs.where((log) => log.status == MedicationStatus.taken).length;
    final missed = logs.where((log) => log.status == MedicationStatus.missed).length;
    final late = logs.where((log) => log.status == MedicationStatus.late).length;
    final pending = logs.where((log) => log.status == MedicationStatus.pending).length;
    final adherenceRate = total > 0 ? (taken / total) * 100 : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatItem('Total', total.toString(), Colors.blue),
              _buildStatItem('Taken', taken.toString(), Colors.green),
              _buildStatItem('Late', late.toString(), Colors.amber),
              _buildStatItem('Missed', missed.toString(), Colors.red),
              _buildStatItem('Pending', pending.toString(), Colors.grey),
              _buildStatItem('Adherence', '${adherenceRate.toStringAsFixed(1)}%', 
                adherenceRate >= 80 ? Colors.green : Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLogCard(MedicationLog log) {
    final statusColor = _getStatusColor(log.status);
    final statusIcon = _getStatusIcon(log.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(log.medicationName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scheduled: ${DateFormat('MMM d, y • h:mm a').format(log.scheduledTime)}'),
            if (log.takenTime != null)
              Text('Taken: ${DateFormat('MMM d, y • h:mm a').format(log.takenTime!)}'),
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
        onTap: () => _showLogDetail(log),
      ),
    );
  }

  Color _getStatusColor(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.taken:
        return Colors.green;
      case MedicationStatus.missed:
        return Colors.red;
      case MedicationStatus.skipped:
        return Colors.orange;
      case MedicationStatus.late:
        return Colors.amber;
      case MedicationStatus.pending:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.taken:
        return Icons.check_circle;
      case MedicationStatus.missed:
        return Icons.cancel;
      case MedicationStatus.skipped:
        return Icons.skip_next;
      case MedicationStatus.late:
        return Icons.access_time;
      case MedicationStatus.pending:
        return Icons.schedule;
    }
  }

  String _getDateRangeText() {
    if (_startDate != null && _endDate != null) {
      return '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}';
    } else if (_startDate != null) {
      return 'From ${DateFormat('MMM d, y').format(_startDate!)}';
    } else if (_endDate != null) {
      return 'Until ${DateFormat('MMM d, y').format(_endDate!)}';
    }
    return '';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Logs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(_startDate != null 
                ? DateFormat('MMM d, y').format(_startDate!)
                : 'Not set'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                  });
                }
              },
            ),
            ListTile(
              title: const Text('End Date'),
              subtitle: Text(_endDate != null 
                ? DateFormat('MMM d, y').format(_endDate!)
                : 'Not set'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadLogs();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showLogDetail(MedicationLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(log.medicationName),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailRow(label: 'Status', value: log.status.toString().split('.').last),
            _DetailRow(label: 'Scheduled', value: DateFormat('MMM d, y • h:mm a').format(log.scheduledTime)),
            if (log.takenTime != null)
              _DetailRow(label: 'Taken', value: DateFormat('MMM d, y • h:mm a').format(log.takenTime!)),
            if (log.notes != null && log.notes!.isNotEmpty)
              _DetailRow(label: 'Notes', value: log.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportLogs() {
    // TODO: Implement export functionality using ExportService
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon!')),
    );
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

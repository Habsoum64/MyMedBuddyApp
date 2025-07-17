import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/medication_log.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  final DatabaseService _databaseService = DatabaseService();

  ExportService._internal();

  factory ExportService() {
    return _instance;
  }

  // Get the appropriate export directory based on platform
  Future<Directory> _getExportDirectory() async {
    if (Platform.isAndroid) {
      // For Android, try to use the external storage directory first
      try {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          // Use the main directory which is more accessible
          return directory;
        }
      } catch (e) {
        print('Could not access external storage: $e');
      }
    }
    
    // Fallback to documents directory for other platforms or if Android paths fail
    return await getApplicationDocumentsDirectory();
  }

  Future<Map<String, dynamic>> generateHealthReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final logs = await _databaseService.getMedicationLogs(
        startDate: startDate,
        endDate: endDate,
      );

      // Calculate statistics
      final totalScheduled = logs.length;
      final taken = logs.where((log) => log.status == MedicationStatus.taken).length;
      final missed = logs.where((log) => log.status == MedicationStatus.missed).length;
      final skipped = logs.where((log) => log.status == MedicationStatus.skipped).length;
      final pending = logs.where((log) => log.status == MedicationStatus.pending).length;

      final adherenceRate = totalScheduled > 0 ? (taken / totalScheduled) * 100 : 0.0;

      // Group by medication
      final medicationStats = <String, Map<String, int>>{};
      for (final log in logs) {
        medicationStats[log.medicationName] ??= {
          'taken': 0,
          'missed': 0,
          'skipped': 0,
          'pending': 0,
        };
        medicationStats[log.medicationName]![log.status.toString().split('.').last] = 
            (medicationStats[log.medicationName]![log.status.toString().split('.').last] ?? 0) + 1;
      }

      return {
        'reportPeriod': {
          'startDate': startDate?.toIso8601String() ?? 'All time',
          'endDate': endDate?.toIso8601String() ?? 'All time',
        },
        'summary': {
          'totalScheduled': totalScheduled,
          'taken': taken,
          'missed': missed,
          'skipped': skipped,
          'pending': pending,
          'adherenceRate': adherenceRate.toStringAsFixed(1),
        },
        'medicationBreakdown': medicationStats,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to generate health report: $e');
    }
  }

  // Export health report to PDF
  Future<String> exportHealthReportToPDF({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final report = await generateHealthReport(
        startDate: startDate,
        endDate: endDate,
      );

      final pdf = pw.Document();
      final dateFormat = DateFormat('yyyy-MM-dd');
      final timeFormat = DateFormat('HH:mm');
      final now = DateTime.now();

      // Add main report page
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Text(
                  'MyMedBuddy Health Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Report period
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Report Period',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('Start Date: ${report['reportPeriod']['startDate']}'),
                      pw.Text('End Date: ${report['reportPeriod']['endDate']}'),
                      pw.Text('Generated: ${dateFormat.format(now)} at ${timeFormat.format(now)}'),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Summary statistics
                pw.Text(
                  'Summary Statistics',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                
                pw.SizedBox(height: 10),
                
                pw.Table(
                  border: pw.TableBorder.all(width: 1),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Metric', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Value', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...report['summary'].entries.map<pw.TableRow>((entry) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(_formatMetricName(entry.key)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(entry.value.toString()),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                
                pw.SizedBox(height: 20),
                
                // Medication breakdown
                pw.Text(
                  'Medication Breakdown',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                
                pw.SizedBox(height: 10),
                
                pw.Column(
                  children: report['medicationBreakdown'].entries.take(5).map<pw.Widget>((entry) {
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 16),
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            entry.key,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text('Taken: ${entry.value['taken'] ?? 0}'),
                          pw.Text('Missed: ${entry.value['missed'] ?? 0}'),
                          pw.Text('Skipped: ${entry.value['skipped'] ?? 0}'),
                          pw.Text('Pending: ${entry.value['pending'] ?? 0}'),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      );

      // Get the export directory (Downloads on Android, Documents otherwise)
      final directory = await _getExportDirectory();
      final fileName = 'MyMedBuddy_Health_Report_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');

      // Write PDF to file
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      throw Exception('Failed to export health report to PDF: $e');
    }
  }

  // Export medication logs to PDF
  Future<String> exportMedicationLogsToPDF({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final logs = await _databaseService.getMedicationLogs(
        startDate: startDate,
        endDate: endDate,
      );

      final pdf = pw.Document();
      final dateFormat = DateFormat('yyyy-MM-dd');
      final timeFormat = DateFormat('HH:mm');
      final now = DateTime.now();

      // Group logs by date for better organization
      final logsByDate = <String, List<MedicationLog>>{};
      for (final log in logs) {
        final dateKey = dateFormat.format(log.scheduledTime);
        logsByDate[dateKey] ??= [];
        logsByDate[dateKey]!.add(log);
      }

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Text(
                  'MyMedBuddy Medication Logs',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Report info
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Report Information',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('Period: ${startDate != null ? dateFormat.format(startDate) : 'All time'} - ${endDate != null ? dateFormat.format(endDate) : 'All time'}'),
                      pw.Text('Generated: ${dateFormat.format(now)} at ${timeFormat.format(now)}'),
                      pw.Text('Total Logs: ${logs.length}'),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Summary table for first few days
                pw.Table(
                  border: pw.TableBorder.all(width: 1),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Time', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Medication', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    ...logs.take(20).map<pw.TableRow>((log) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(dateFormat.format(log.scheduledTime), style: pw.TextStyle(fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(timeFormat.format(log.scheduledTime), style: pw.TextStyle(fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(log.medicationName, style: pw.TextStyle(fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(_formatStatus(log.status), style: pw.TextStyle(fontSize: 10)),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Get the export directory (Downloads on Android, Documents otherwise)
      final directory = await _getExportDirectory();
      final fileName = 'MyMedBuddy_Medication_Logs_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');

      // Write PDF to file
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      throw Exception('Failed to export medication logs to PDF: $e');
    }
  }

  // Helper method to format metric names
  String _formatMetricName(String key) {
    switch (key) {
      case 'totalScheduled':
        return 'Total Scheduled';
      case 'taken':
        return 'Taken';
      case 'missed':
        return 'Missed';
      case 'skipped':
        return 'Skipped';
      case 'pending':
        return 'Pending';
      case 'adherenceRate':
        return 'Adherence Rate (%)';
      default:
        return key;
    }
  }

  // Helper method to format status
  String _formatStatus(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.taken:
        return 'Taken';
      case MedicationStatus.missed:
        return 'Missed';
      case MedicationStatus.skipped:
        return 'Skipped';
      case MedicationStatus.pending:
        return 'Pending';
      case MedicationStatus.late:
        return 'Late';
    }
  }

  // Export appointment summary to PDF
  Future<String> exportAppointmentSummaryToPDF({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('yyyy-MM-dd');
      final timeFormat = DateFormat('HH:mm');
      final now = DateTime.now();

      // For now, use mock data - in a real app, you'd fetch from database
      final mockAppointments = [
        {'date': '2024-01-15', 'time': '10:00', 'doctor': 'Dr. Smith', 'type': 'Checkup'},
        {'date': '2024-01-20', 'time': '14:30', 'doctor': 'Dr. Johnson', 'type': 'Follow-up'},
        {'date': '2024-01-25', 'time': '09:15', 'doctor': 'Dr. Brown', 'type': 'Consultation'},
      ];

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Text(
                  'MyMedBuddy Appointment Summary',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Report period
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Report Period',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('Start Date: ${dateFormat.format(startDate ?? DateTime.now().subtract(Duration(days: 30)))}'),
                      pw.Text('End Date: ${dateFormat.format(endDate ?? DateTime.now())}'),
                      pw.Text('Generated: ${dateFormat.format(now)} at ${timeFormat.format(now)}'),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Summary
                pw.Text(
                  'Summary',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                
                pw.SizedBox(height: 10),
                
                pw.Text('Total Appointments: ${mockAppointments.length}'),
                pw.SizedBox(height: 10),
                
                // Appointments table
                pw.Text(
                  'Appointments',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                
                pw.SizedBox(height: 10),
                
                pw.Table(
                  border: pw.TableBorder.all(width: 1),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Time', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Doctor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...mockAppointments.map<pw.TableRow>((appointment) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(appointment['date']!),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(appointment['time']!),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(appointment['doctor']!),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(appointment['type']!),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Get the export directory
      final directory = await _getExportDirectory();
      final fileName = 'MyMedBuddy_Appointments_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');

      // Write PDF to file
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      throw Exception('Failed to export appointment summary to PDF: $e');
    }
  }

  // Export health overview to PDF
  Future<String> exportHealthOverviewToPDF({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final medicationLogs = await _databaseService.getMedicationLogs(
        startDate: startDate,
        endDate: endDate,
      );

      final pdf = pw.Document();
      final dateFormat = DateFormat('yyyy-MM-dd');
      final timeFormat = DateFormat('HH:mm');
      final now = DateTime.now();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Text(
                  'MyMedBuddy Health Overview',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Report period
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Report Period',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('Start Date: ${dateFormat.format(startDate ?? DateTime.now().subtract(Duration(days: 30)))}'),
                      pw.Text('End Date: ${dateFormat.format(endDate ?? DateTime.now())}'),
                      pw.Text('Generated: ${dateFormat.format(now)} at ${timeFormat.format(now)}'),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Summary statistics
                pw.Text(
                  'Health Overview',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                
                pw.SizedBox(height: 10),
                
                pw.Table(
                  border: pw.TableBorder.all(width: 1),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Metric', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Value', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Total Medications Taken'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${medicationLogs.where((log) => log.status == MedicationStatus.taken).length}'),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Total Appointments'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('3'), // Mock data
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Adherence Rate'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${medicationLogs.isNotEmpty ? ((medicationLogs.where((log) => log.status == MedicationStatus.taken).length / medicationLogs.length) * 100).toStringAsFixed(1) : 0}%'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Get the export directory
      final directory = await _getExportDirectory();
      final fileName = 'MyMedBuddy_Overview_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');

      // Write PDF to file
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      throw Exception('Failed to export health overview to PDF: $e');
    }
  }
}

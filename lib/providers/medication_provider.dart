import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/medication.dart';
import '../models/medication_log.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class MedicationProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  List<Medication> _medications = [];
  List<MedicationLog> _medicationLogs = [];
  List<Map<String, dynamic>> _medicationCatalog = [];
  bool _isLoading = false;
  String? _error;
  bool _hasLoadedMedications = false;
  bool _hasLoadedLogs = false;

  // Filters
  String _searchQuery = '';
  String _categoryFilter = '';
  String _statusFilter = '';
  String _sortBy = 'name'; // name, date, category

  List<Medication> get medications {
    // Auto-load medications if not already loaded
    if (!_hasLoadedMedications && !_isLoading) {
      // Use Future.microtask to avoid calling notifyListeners during build
      Future.microtask(() => loadMedications());
    }
    return _filteredMedications;
  }
  
  List<MedicationLog> get medicationLogs {
    // Auto-load logs if not already loaded
    if (!_hasLoadedLogs && !_isLoading) {
      // Use Future.microtask to avoid calling notifyListeners during build
      Future.microtask(() => loadMedicationLogs());
    }
    // Update statuses dynamically based on current time
    return _medicationLogs.map((log) => _updateLogStatus(log)).toList();
  }

  // Update log status based on current time and scheduling logic
  MedicationLog _updateLogStatus(MedicationLog log) {
    // If already taken, missed, or skipped, don't change status
    if (log.status == MedicationStatus.taken || 
        log.status == MedicationStatus.missed || 
        log.status == MedicationStatus.skipped) {
      return log;
    }

    final now = DateTime.now();
    final scheduledTime = log.scheduledTime;
    
    // If scheduled time hasn't passed yet, keep as pending
    if (now.isBefore(scheduledTime)) {
      return log.copyWith(status: MedicationStatus.pending);
    }

    // Find the medication to get its schedule
    Medication? medication;
    try {
      medication = _medications.firstWhere((med) => med.id == log.medicationId);
    } catch (e) {
      // If medication not found, mark as missed
      return log.copyWith(status: MedicationStatus.missed);
    }

    // Calculate next scheduled dose time
    final nextScheduledTime = _getNextScheduledTime(medication, scheduledTime);
    
    // If current time is past the next scheduled dose, mark as missed
    if (nextScheduledTime != null && now.isAfter(nextScheduledTime)) {
      return log.copyWith(status: MedicationStatus.missed);
    }

    // If we're past the scheduled time but before the next dose, mark as late
    return log.copyWith(status: MedicationStatus.late);
  }

  // Calculate the next scheduled dose time after a given time
  DateTime? _getNextScheduledTime(Medication medication, DateTime currentScheduledTime) {
    try {
      // Get current scheduled time components
      final currentDate = DateTime(
        currentScheduledTime.year, 
        currentScheduledTime.month, 
        currentScheduledTime.day
      );
      
      // Parse all scheduled times for the current day
      final todayTimes = medication.times.map((timeString) {
        final parts = timeString.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(currentDate.year, currentDate.month, currentDate.day, hour, minute);
      }).toList();
      
      // Sort times
      todayTimes.sort();
      
      // Find the next time after current scheduled time
      for (final time in todayTimes) {
        if (time.isAfter(currentScheduledTime)) {
          return time;
        }
      }
      
      // If no more times today, get the first time of tomorrow
      final tomorrow = currentDate.add(const Duration(days: 1));
      final firstTimeString = medication.times.first;
      final parts = firstTimeString.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
    } catch (e) {
      // Error calculating next scheduled time
      return null;
    }
  }
  List<Map<String, dynamic>> get medicationCatalog => _medicationCatalog;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get categoryFilter => _categoryFilter;
  String get statusFilter => _statusFilter;
  String get sortBy => _sortBy;

  List<Medication> get _filteredMedications {
    var filtered = List<Medication>.from(_medications);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((med) => 
        med.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        med.dosage.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        med.instructions.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Apply category filter
    if (_categoryFilter.isNotEmpty) {
      filtered = filtered.where((med) => med.category == _categoryFilter).toList();
    }
    
    // Apply status filter
    if (_statusFilter.isNotEmpty) {
      switch (_statusFilter) {
        case 'active':
          filtered = filtered.where((med) => med.isActive).toList();
          break;
        case 'inactive':
          filtered = filtered.where((med) => !med.isActive).toList();
          break;
        case 'expired':
          final now = DateTime.now();
          filtered = filtered.where((med) => 
            med.endDate != null && med.endDate!.isBefore(now)
          ).toList();
          break;
      }
    }
    
    // Apply sorting
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'date':
        filtered.sort((a, b) => b.startDate.compareTo(a.startDate));
        break;
      case 'category':
        filtered.sort((a, b) => a.category.compareTo(b.category));
        break;
    }
    
    return filtered;
  }

  List<String> get categories {
    return _medications.map((med) => med.category).toSet().toList()..sort();
  }

  Future<void> loadMedications() async {
    if (_hasLoadedMedications) return;
    
    _setLoading(true);
    try {
      // Check if user is authenticated
      if (!_authService.isLoggedIn) {
        _medications = [];
        _error = 'User not authenticated';
        _hasLoadedMedications = true;
        return;
      }

      final userId = _authService.currentUserId!;
      
      // Load user-specific medications from database
      final dbResults = await _databaseService.getUserMedications(userId);
      
      // Convert database results to Medication objects
      _medications = dbResults.map((data) {
        // Parse times from JSON string, default to empty list if null or invalid
        List<String> times = [];
        try {
          if (data['times'] != null) {
            final timesData = data['times'] as String;
            final List<dynamic> timesList = json.decode(timesData);
            times = timesList.cast<String>();
          }
        } catch (e) {
          // If parsing fails, use empty list
          times = [];
        }
        
        return Medication(
          id: data['id'] as String,
          name: data['customName'] as String? ?? data['catalogName'] as String? ?? 'Unknown',
          dosage: data['dosage'] as String,
          frequency: data['frequency'] as String,
          category: data['category'] as String? ?? 'General',
          instructions: data['instructions'] as String? ?? '',
          startDate: DateTime.tryParse(data['startDate'] as String) ?? DateTime.now(),
          endDate: data['endDate'] != null ? DateTime.tryParse(data['endDate'] as String) : null,
          times: times,
          isActive: (data['isActive'] as int) == 1,
        );
      }).toList();
      
      // Regenerate logs for all medications to ensure they're up to date
      await _regenerateAllMedicationLogs();
      
      _error = null;
      _hasLoadedMedications = true;
    } catch (e) {
      _error = e.toString();
      _medications = [];
      _hasLoadedMedications = true; // Mark as loaded even if error to prevent infinite retries
    } finally {
      _setLoading(false);
    }
  }

  // Regenerate logs for all active medications
  Future<void> _regenerateAllMedicationLogs() async {
    try {
      for (final medication in _medications.where((med) => med.isActive)) {
        // Clean up old pending logs first
        await _deleteExistingPendingLogs(medication.id);
        
        // Generate fresh logs
        await _generateMedicationLogs(medication);
        
        // Add a small delay to prevent overwhelming the database
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      // Successfully regenerated logs for medications
    } catch (e) {
      // Error regenerating medication logs
    }
  }

  // Comprehensive method to refresh all medication data and logs
  Future<void> _refreshMedicationData() async {
    try {
      // Reload medications from database
      await loadMedications();
      
      // Regenerate all logs to ensure they're up-to-date
      await _regenerateAllMedicationLogs();
      
      // Reload logs from database (this will filter out logs from deleted medications)
      await loadMedicationLogs();
      
      // Clean up any orphaned logs in memory
      _cleanupOrphanedLogs();
      
      // Successfully refreshed all medication data and logs
    } catch (e) {
      // Error refreshing medication data
    }
  }

  // Clean up logs from deleted medications
  void _cleanupOrphanedLogs() {
    final activeMedicationIds = _medications
        .where((medication) => medication.isActive)
        .map((medication) => medication.id)
        .toSet();
    
    _medicationLogs.removeWhere((log) => !activeMedicationIds.contains(log.medicationId));
    
    // Orphaned logs cleaned up
  }

  // Public method to refresh all medication data and logs
  Future<void> refreshAllMedicationData() async {
    _setLoading(true);
    try {
      // Reset loaded flags to force refresh
      _hasLoadedMedications = false;
      _hasLoadedLogs = false;
      await _refreshMedicationData();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMedicationLogs({DateTime? startDate, DateTime? endDate}) async {
    // For dashboard auto-loading, check if basic logs are loaded
    if (startDate == null && endDate == null && _hasLoadedLogs) return;
    
    try {
      // Get all logs first
      final allLogs = await _databaseService.getMedicationLogs(
        startDate: startDate,
        endDate: endDate,
      );
      
      // Filter logs to only include those from active medications
      final activeMedicationIds = _medications
          .where((medication) => medication.isActive)
          .map((medication) => medication.id)
          .toSet();
      
      _medicationLogs = allLogs.where((log) => 
        activeMedicationIds.contains(log.medicationId)
      ).toList();
      
      // Mark as loaded only if this is the basic load (no date filters)
      if (startDate == null && endDate == null) {
        _hasLoadedLogs = true;
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      // Mark as loaded even if error to prevent infinite retries
      if (startDate == null && endDate == null) {
        _hasLoadedLogs = true;
      }
      notifyListeners();
    }
  }

  // Load medication catalog (global)
  Future<void> loadMedicationCatalog() async {
    try {
      _medicationCatalog = await _databaseService.getMedicationsCatalog();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Search medications catalog
  Future<List<Map<String, dynamic>>> searchMedicationsCatalog(String query) async {
    try {
      final allMedications = await _databaseService.getMedicationsCatalog();
      
      if (query.isEmpty) {
        return allMedications;
      }
      
      return allMedications.where((med) {
        final name = med['name']?.toString().toLowerCase() ?? '';
        final category = med['category']?.toString().toLowerCase() ?? '';
        final description = med['description']?.toString().toLowerCase() ?? '';
        final searchTerm = query.toLowerCase();
        
        return name.contains(searchTerm) || 
               category.contains(searchTerm) || 
               description.contains(searchTerm);
      }).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<void> addMedicationFromCatalog({
    required String catalogMedicationId,
    required String dosage,
    required String frequency,
    required List<String> times,
    String? customInstructions,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    try {
      if (!_authService.isLoggedIn) {
        throw Exception('User not authenticated');
      }

      final userId = _authService.currentUserId!;
      
      // Get medication name from catalog
      final catalogMedications = await _databaseService.getMedicationsCatalog();
      final catalogMed = catalogMedications.firstWhere(
        (med) => med['id'] == catalogMedicationId,
        orElse: () => {'name': 'Unknown Medication'},
      );
      
      final medicationId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Add medication to database
      await _databaseService.addUserMedication({
        'id': medicationId,
        'userId': userId,
        'medicationId': catalogMedicationId, // Reference to catalog
        'customName': null, // Use catalog name
        'dosage': dosage,
        'frequency': frequency,
        'times': json.encode(times),
        'instructions': customInstructions ?? '',
        'startDate': (startDate ?? DateTime.now()).toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isActive': 1,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      // Create a temporary medication object for log generation
      final tempMedication = Medication(
        id: medicationId,
        name: catalogMed['name'] as String,
        dosage: dosage,
        frequency: frequency,
        times: times,
        instructions: customInstructions ?? '',
        startDate: startDate ?? DateTime.now(),
        endDate: endDate,
        category: 'General',
        isActive: true,
      );
      
      // Generate medication logs for scheduled times
      await _generateMedicationLogs(tempMedication);
      
      // Refresh all medication data and logs
      await _refreshMedicationData();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addMedication(Medication medication, [String? catalogId]) async {
    _setLoading(true);
    try {
      if (!_authService.isLoggedIn) {
        throw Exception('User not authenticated');
      }

      final userId = _authService.currentUserId!;
      
      // Add medication to database
      await _databaseService.addUserMedication({
        'id': medication.id,
        'userId': userId,
        'medicationId': catalogId, // Use catalogId if from catalog, null if custom
        'customName': catalogId == null ? medication.name : null, // Only set custom name if not from catalog
        'dosage': medication.dosage,
        'frequency': medication.frequency,
        'times': json.encode(medication.times),
        'instructions': medication.instructions,
        'startDate': medication.startDate.toIso8601String(),
        'endDate': medication.endDate?.toIso8601String(),
        'isActive': medication.isActive ? 1 : 0,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      // Generate medication logs for scheduled times
      await _generateMedicationLogs(medication);
      
      // Schedule notifications
      await _notificationService.scheduleMedicationReminders(medication);
      
      // Refresh all medication data and logs
      await _refreshMedicationData();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Generate medication logs for scheduled times
  Future<void> _generateMedicationLogs(Medication medication) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Use medication's end date if provided, otherwise generate for 30 days
      final endDate = medication.endDate ?? now.add(const Duration(days: 30));
      
      // Normalize end date to end of day to ensure we include the full end date
      final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      
      // Start from medication start date, but include today even if it's in the past
      DateTime currentDate = medication.startDate.isBefore(today) 
          ? today 
          : medication.startDate;
      
      // Generate logs day by day - use <= comparison to ensure we include the end date
      while (currentDate.millisecondsSinceEpoch <= normalizedEndDate.millisecondsSinceEpoch) {
        for (final timeString in medication.times) {
          final timeParts = timeString.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          
          final scheduledTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            hour,
            minute,
          );
          
          // Skip if this scheduled time is after the actual end date
          if (scheduledTime.isAfter(normalizedEndDate)) {
            continue;
          }
          
          // Create a unique, deterministic log ID
          final logId = '${medication.id}_${scheduledTime.millisecondsSinceEpoch}';
          
          // Check if log already exists using the exact log ID
          final existingLogs = await _databaseService.getMedicationLogs(
            medicationId: medication.id,
            startDate: scheduledTime.subtract(const Duration(minutes: 1)),
            endDate: scheduledTime.add(const Duration(minutes: 1)),
          );
          
          // Only create if no log exists for this exact time
          final hasExistingLog = existingLogs.any((log) => 
            log.scheduledTime.isAtSameMomentAs(scheduledTime)
          );
          
          if (!hasExistingLog) {
            // Create all logs as pending initially
            final log = MedicationLog(
              id: logId,
              medicationId: medication.id,
              medicationName: medication.name,
              scheduledTime: scheduledTime,
              status: MedicationStatus.pending,
            );
            
            await _databaseService.insertMedicationLog(log);
          }
        }
        
        currentDate = currentDate.add(const Duration(days: 1));
      }
    } catch (e) {
      print('Error generating medication logs: $e');
      // Don't throw, just log the error
    }
  }

  // Enhanced method to delete existing pending logs for a medication
  Future<void> _deleteExistingPendingLogs(String medicationId) async {
    try {
      final now = DateTime.now();
      
      // Get all future logs for this medication
      final existingLogs = await _databaseService.getMedicationLogs(
        medicationId: medicationId,
        startDate: now.subtract(const Duration(hours: 1)), // Include recent past
      );
      
      // Delete all pending logs (preserve taken/missed/skipped as historical records)
      for (final log in existingLogs) {
        if (log.status == MedicationStatus.pending) {
          await _databaseService.deleteMedicationLog(log.id);
        }
      }
    } catch (e) {
      print('Error deleting pending logs: $e');
      // Don't throw, just log the error
    }
  }

  Future<void> updateMedication(Medication medication) async {
    _setLoading(true);
    try {
      if (!_authService.isLoggedIn) {
        throw Exception('User not authenticated');
      }

      // Update medication in database
      await _databaseService.updateUserMedication(medication.id, {
        'customName': medication.name,
        'dosage': medication.dosage,
        'frequency': medication.frequency,
        'times': json.encode(medication.times),
        'instructions': medication.instructions,
        'startDate': medication.startDate.toIso8601String(),
        'endDate': medication.endDate?.toIso8601String(),
        'isActive': medication.isActive ? 1 : 0,
      });
      
      // Delete existing pending logs for this medication to avoid conflicts
      await _deleteExistingPendingLogs(medication.id);
      
      // Regenerate logs with updated schedule
      await _generateMedicationLogs(medication);
      
      // Schedule notifications
      await _notificationService.scheduleMedicationReminders(medication);
      
      // Refresh all medication data and logs
      await _refreshMedicationData();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    _setLoading(true);
    try {
      if (!_authService.isLoggedIn) {
        throw Exception('User not authenticated');
      }

      // Delete all pending logs for this medication first
      await _deleteExistingPendingLogs(medicationId);
      
      // Delete medication from database
      await _databaseService.deleteUserMedication(medicationId);
      
      // Cancel notifications
      await _notificationService.cancelMedicationNotifications(medicationId);
      
      // Refresh all medication data and logs
      await _refreshMedicationData();
      
      // Clean up logs from deleted medications in memory
      _medicationLogs.removeWhere((log) => log.medicationId == medicationId);
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logMedicationTaken(String medicationId, String medicationName, DateTime scheduledTime) async {
    try {
      final now = DateTime.now();
      
      // Try to find the exact pending log for this medication and scheduled time
      MedicationLog? targetLog;
      try {
        targetLog = medicationLogs.firstWhere(
          (log) => 
            log.medicationId == medicationId &&
            log.scheduledTime.isAtSameMomentAs(scheduledTime) &&
            log.status == MedicationStatus.pending,
        );
      } catch (e) {
        targetLog = null;
      }
      
      if (targetLog != null) {
        // Update existing log
        final updatedLog = targetLog.copyWith(
          takenTime: now,
          status: MedicationStatus.taken,
        );
        
        await _databaseService.updateMedicationLog(updatedLog);
      } else {
        // Create new log if none exists (fallback case)
        final newLog = MedicationLog(
          id: '${medicationId}_${scheduledTime.millisecondsSinceEpoch}_taken',
          medicationId: medicationId,
          medicationName: medicationName,
          scheduledTime: scheduledTime,
          takenTime: now,
          status: MedicationStatus.taken,
        );
        
        await _databaseService.insertMedicationLog(newLog);
      }
      
      // Refresh logs to reflect changes
      await loadMedicationLogs();
      
      // Notify listeners to update UI
      notifyListeners();
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error logging medication taken: $e');
      notifyListeners();
    }
  }

  Future<void> logMedicationMissed(String medicationId, String medicationName, DateTime scheduledTime) async {
    try {
      // Try to find the exact pending log for this medication and scheduled time
      MedicationLog? targetLog;
      try {
        targetLog = medicationLogs.firstWhere(
          (log) => 
            log.medicationId == medicationId &&
            log.scheduledTime.isAtSameMomentAs(scheduledTime) &&
            log.status == MedicationStatus.pending,
        );
      } catch (e) {
        targetLog = null;
      }
      
      if (targetLog != null) {
        // Update existing log
        final updatedLog = targetLog.copyWith(
          status: MedicationStatus.missed,
        );
        
        await _databaseService.updateMedicationLog(updatedLog);
      } else {
        // Create new log if none exists (fallback case)
        final newLog = MedicationLog(
          id: '${medicationId}_${scheduledTime.millisecondsSinceEpoch}_missed',
          medicationId: medicationId,
          medicationName: medicationName,
          scheduledTime: scheduledTime,
          status: MedicationStatus.missed,
        );
        
        await _databaseService.insertMedicationLog(newLog);
      }
      
      // Refresh logs to reflect changes
      await loadMedicationLogs();
      
      // Notify listeners to update UI
      notifyListeners();
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error logging medication missed: $e');
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _categoryFilter = '';
    _statusFilter = '';
    _sortBy = 'name';
    notifyListeners();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  List<MedicationLog> getTodaysMedications() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return medicationLogs.where((log) =>
      log.scheduledTime.isAfter(startOfDay) &&
      log.scheduledTime.isBefore(endOfDay)
    ).toList();
  }

  List<MedicationLog> getUpcomingMedications() {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return medicationLogs.where((log) =>
      log.status == MedicationStatus.pending &&
      log.scheduledTime.isAfter(now) &&
      log.scheduledTime.isBefore(endOfToday)
    ).toList()..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  double get todayAdherenceRate {
    final todaysMeds = getTodaysMedications();
    if (todaysMeds.isEmpty) return 0.0;
    
    final taken = todaysMeds.where((log) => log.status == MedicationStatus.taken).length;
    return (taken / todaysMeds.length) * 100;
  }
}
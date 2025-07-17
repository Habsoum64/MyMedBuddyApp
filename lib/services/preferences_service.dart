import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  static SharedPreferences? _prefs;

  PreferencesService._internal();

  factory PreferencesService() {
    return _instance;
  }

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Get SharedPreferences instance
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('PreferencesService not initialized. Call PreferencesService.init() first.');
    }
    return _prefs!;
  }

  // Notification Settings
  static const String _medicationNotifications = 'medication_notifications';
  static const String _appointmentNotifications = 'appointment_notifications';
  static const String _healthTipNotifications = 'health_tip_notifications';
  static const String _soundEnabled = 'sound_enabled';
  static const String _vibrationEnabled = 'vibration_enabled';

  // App Settings
  static const String _darkMode = 'dark_mode';
  static const String _language = 'language';
  static const String _fontSize = 'font_size';
  static const String _dateFormat = 'date_format';
  static const String _timeFormat = 'time_format';

  // User Preferences
  static const String _reminderTime = 'reminder_time';
  static const String _medicationSortOrder = 'medication_sort_order';
  static const String _appointmentSortOrder = 'appointment_sort_order';
  static const String _defaultMedicationTime = 'default_medication_time';

  // Security Settings
  static const String _biometricEnabled = 'biometric_enabled';
  static const String _autoLockEnabled = 'auto_lock_enabled';
  static const String _autoLockTimeout = 'auto_lock_timeout';

  // Backup Settings
  static const String _autoBackupEnabled = 'auto_backup_enabled';
  static const String _backupFrequency = 'backup_frequency';
  static const String _lastBackupDate = 'last_backup_date';

  // == Notification Settings ==
  bool get medicationNotifications => prefs.getBool(_medicationNotifications) ?? true;
  Future<bool> setMedicationNotifications(bool value) => prefs.setBool(_medicationNotifications, value);

  bool get appointmentNotifications => prefs.getBool(_appointmentNotifications) ?? true;
  Future<bool> setAppointmentNotifications(bool value) => prefs.setBool(_appointmentNotifications, value);

  bool get healthTipNotifications => prefs.getBool(_healthTipNotifications) ?? true;
  Future<bool> setHealthTipNotifications(bool value) => prefs.setBool(_healthTipNotifications, value);

  bool get soundEnabled => prefs.getBool(_soundEnabled) ?? true;
  Future<bool> setSoundEnabled(bool value) => prefs.setBool(_soundEnabled, value);

  bool get vibrationEnabled => prefs.getBool(_vibrationEnabled) ?? true;
  Future<bool> setVibrationEnabled(bool value) => prefs.setBool(_vibrationEnabled, value);

  // == App Settings ==
  bool get darkMode => prefs.getBool(_darkMode) ?? false;
  Future<bool> setDarkMode(bool value) => prefs.setBool(_darkMode, value);

  String get language => prefs.getString(_language) ?? 'en';
  Future<bool> setLanguage(String value) => prefs.setString(_language, value);

  double get fontSize => prefs.getDouble(_fontSize) ?? 14.0;
  Future<bool> setFontSize(double value) => prefs.setDouble(_fontSize, value);

  String get dateFormat => prefs.getString(_dateFormat) ?? 'yyyy-MM-dd';
  Future<bool> setDateFormat(String value) => prefs.setString(_dateFormat, value);

  String get timeFormat => prefs.getString(_timeFormat) ?? '24h';
  Future<bool> setTimeFormat(String value) => prefs.setString(_timeFormat, value);

  // == User Preferences ==
  String get reminderTime => prefs.getString(_reminderTime) ?? '09:00';
  Future<bool> setReminderTime(String value) => prefs.setString(_reminderTime, value);

  String get medicationSortOrder => prefs.getString(_medicationSortOrder) ?? 'name';
  Future<bool> setMedicationSortOrder(String value) => prefs.setString(_medicationSortOrder, value);

  String get appointmentSortOrder => prefs.getString(_appointmentSortOrder) ?? 'date';
  Future<bool> setAppointmentSortOrder(String value) => prefs.setString(_appointmentSortOrder, value);

  String get defaultMedicationTime => prefs.getString(_defaultMedicationTime) ?? '08:00';
  Future<bool> setDefaultMedicationTime(String value) => prefs.setString(_defaultMedicationTime, value);

  // == Security Settings ==
  bool get biometricEnabled => prefs.getBool(_biometricEnabled) ?? false;
  Future<bool> setBiometricEnabled(bool value) => prefs.setBool(_biometricEnabled, value);

  bool get autoLockEnabled => prefs.getBool(_autoLockEnabled) ?? false;
  Future<bool> setAutoLockEnabled(bool value) => prefs.setBool(_autoLockEnabled, value);

  int get autoLockTimeout => prefs.getInt(_autoLockTimeout) ?? 300; // 5 minutes
  Future<bool> setAutoLockTimeout(int value) => prefs.setInt(_autoLockTimeout, value);

  // == Backup Settings ==
  bool get autoBackupEnabled => prefs.getBool(_autoBackupEnabled) ?? true;
  Future<bool> setAutoBackupEnabled(bool value) => prefs.setBool(_autoBackupEnabled, value);

  String get backupFrequency => prefs.getString(_backupFrequency) ?? 'weekly';
  Future<bool> setBackupFrequency(String value) => prefs.setString(_backupFrequency, value);

  String? get lastBackupDate => prefs.getString(_lastBackupDate);
  Future<bool> setLastBackupDate(String value) => prefs.setString(_lastBackupDate, value);

  // == Utility Methods ==
  
  // Get all notification settings as a map
  Map<String, bool> get allNotificationSettings => {
    'medication': medicationNotifications,
    'appointment': appointmentNotifications,
    'healthTip': healthTipNotifications,
    'sound': soundEnabled,
    'vibration': vibrationEnabled,
  };

  // Save all notification settings at once
  Future<void> saveAllNotificationSettings(Map<String, bool> settings) async {
    await Future.wait([
      setMedicationNotifications(settings['medication'] ?? true),
      setAppointmentNotifications(settings['appointment'] ?? true),
      setHealthTipNotifications(settings['healthTip'] ?? true),
      setSoundEnabled(settings['sound'] ?? true),
      setVibrationEnabled(settings['vibration'] ?? true),
    ]);
  }

  // Reset all settings to default
  Future<void> resetToDefaults() async {
    await prefs.clear();
  }

  // Export settings as a map (for backup purposes)
  Map<String, dynamic> exportSettings() {
    return {
      'notifications': {
        'medication': medicationNotifications,
        'appointment': appointmentNotifications,
        'healthTip': healthTipNotifications,
        'sound': soundEnabled,
        'vibration': vibrationEnabled,
      },
      'app': {
        'darkMode': darkMode,
        'language': language,
        'fontSize': fontSize,
        'dateFormat': dateFormat,
        'timeFormat': timeFormat,
      },
      'userPreferences': {
        'reminderTime': reminderTime,
        'medicationSortOrder': medicationSortOrder,
        'appointmentSortOrder': appointmentSortOrder,
        'defaultMedicationTime': defaultMedicationTime,
      },
      'security': {
        'biometricEnabled': biometricEnabled,
        'autoLockEnabled': autoLockEnabled,
        'autoLockTimeout': autoLockTimeout,
      },
      'backup': {
        'autoBackupEnabled': autoBackupEnabled,
        'backupFrequency': backupFrequency,
        'lastBackupDate': lastBackupDate,
      },
    };
  }

  // Import settings from a map (for restore purposes)
  Future<void> importSettings(Map<String, dynamic> settings) async {
    // Notifications
    final notifications = settings['notifications'] as Map<String, dynamic>? ?? {};
    await saveAllNotificationSettings({
      'medication': notifications['medication'] ?? true,
      'appointment': notifications['appointment'] ?? true,
      'healthTip': notifications['healthTip'] ?? true,
      'sound': notifications['sound'] ?? true,
      'vibration': notifications['vibration'] ?? true,
    });

    // App settings
    final app = settings['app'] as Map<String, dynamic>? ?? {};
    await Future.wait([
      setDarkMode(app['darkMode'] ?? false),
      setLanguage(app['language'] ?? 'en'),
      setFontSize(app['fontSize'] ?? 14.0),
      setDateFormat(app['dateFormat'] ?? 'yyyy-MM-dd'),
      setTimeFormat(app['timeFormat'] ?? '24h'),
    ]);

    // User preferences
    final userPrefs = settings['userPreferences'] as Map<String, dynamic>? ?? {};
    await Future.wait([
      setReminderTime(userPrefs['reminderTime'] ?? '09:00'),
      setMedicationSortOrder(userPrefs['medicationSortOrder'] ?? 'name'),
      setAppointmentSortOrder(userPrefs['appointmentSortOrder'] ?? 'date'),
      setDefaultMedicationTime(userPrefs['defaultMedicationTime'] ?? '08:00'),
    ]);

    // Security settings
    final security = settings['security'] as Map<String, dynamic>? ?? {};
    await Future.wait([
      setBiometricEnabled(security['biometricEnabled'] ?? false),
      setAutoLockEnabled(security['autoLockEnabled'] ?? false),
      setAutoLockTimeout(security['autoLockTimeout'] ?? 300),
    ]);

    // Backup settings
    final backup = settings['backup'] as Map<String, dynamic>? ?? {};
    await Future.wait([
      setAutoBackupEnabled(backup['autoBackupEnabled'] ?? true),
      setBackupFrequency(backup['backupFrequency'] ?? 'weekly'),
      if (backup['lastBackupDate'] != null) 
        setLastBackupDate(backup['lastBackupDate']),
    ]);
  }
}

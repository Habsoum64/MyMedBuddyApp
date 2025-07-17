import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap
  }

  Future<void> scheduleMedicationNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders for taking medications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Medication Reminder',
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      categoryIdentifier: 'medication_reminder',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _convertToTZDateTime(scheduledTime),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> scheduleRepeatingMedicationNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders for taking medications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Medication Reminder',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      categoryIdentifier: 'medication_reminder',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(time),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> scheduleMedicationReminders(Medication medication) async {
    // Cancel existing notifications for this medication
    await cancelMedicationNotifications(medication.id);

    for (int i = 0; i < medication.times.length; i++) {
      final timeString = medication.times[i];
      final timeParts = timeString.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final time = TimeOfDay(hour: hour, minute: minute);

      final notificationId = '${medication.id}_$i'.hashCode;

      await scheduleRepeatingMedicationNotification(
        id: notificationId,
        title: 'Medication Reminder',
        body: 'Time to take ${medication.name} (${medication.dosage})',
        time: time,
        payload: medication.id,
      );
    }
  }

  Future<void> cancelMedicationNotifications(String medicationId) async {
    final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    
    for (final notification in pendingNotifications) {
      if (notification.payload == medicationId) {
        await _flutterLocalNotificationsPlugin.cancel(notification.id);
      }
    }
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> scheduleAppointmentReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // Schedule 24 hours before
    final reminderTime = scheduledTime.subtract(const Duration(days: 1));
    
    if (reminderTime.isAfter(DateTime.now())) {
      await scheduleMedicationNotification(
        id: id,
        title: 'Appointment Reminder',
        body: body,
        scheduledTime: reminderTime,
        payload: payload,
      );
    }

    // Schedule 1 hour before
    final hourBeforeTime = scheduledTime.subtract(const Duration(hours: 1));
    
    if (hourBeforeTime.isAfter(DateTime.now())) {
      await scheduleMedicationNotification(
        id: id + 1000000, // Offset to avoid ID conflicts
        title: 'Appointment Soon',
        body: body,
        scheduledTime: hourBeforeTime,
        payload: payload,
      );
    }
  }

  // Helper methods
  dynamic _convertToTZDateTime(DateTime dateTime) {
    // For simplicity, we'll use the local timezone
    // In a production app, you might want to use the timezone package
    return dateTime;
  }

  dynamic _nextInstanceOfTime(TimeOfDay time) {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    
    return scheduledTime;
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Flutter Local Notifications plugin instance
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Initialize Notifications
  Future<void> initNotifications() async {
    // Android Initialization
    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('@drawable/ic_stat_ionhive'); // Correct icon

    // iOS Initialization (optional, for cross-platform compatibility)
    const DarwinInitializationSettings iosInitializationSettings = DarwinInitializationSettings();

    // Combine initialization settings for both platforms
    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    // Initialize plugin with optional notification response handling
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationResponse,
    );
  }

  // Notification response callback
  void onNotificationResponse(NotificationResponse response) {
    // Add actions based on payload or response here
    print("Notification Response: ${response.payload}");
  }

  // Notification Details for Android and iOS
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        "channelId", // Unique channel ID
        "channelName", // Channel name visible to users
        channelDescription: "Channel for basic notifications",
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  // Show Notification Function
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id, // Notification ID
      title ?? 'Default Title', // Fallback to default title
      body ?? 'Default Body', // Fallback to default body
      notificationDetails(),
      payload: payload,
    );
  }

  Future<void> sendTwoNotifications() async {
    final notificationService = NotificationService();

    // First Notification
    await notificationService.showNotification(
      id: 1, // Unique ID for this notification
      title: "Notification 1",
      body: "This is the first notification",
      payload: "payload_1",
    );

    // Second Notification
    await notificationService.showNotification(
      id: 2, // Unique ID for this notification
      title: "Notification 2",
      body: "This is the second notification",
      payload: "payload_2",
    );
  }


  Future<void> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlatform =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlatform?.requestNotificationsPermission();
  }
}

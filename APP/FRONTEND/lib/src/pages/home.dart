import 'dart:isolate';
import 'dart:async';
// import 'package:ev_app/src/utilities/Connectivity_page/connectivity_page.dart';
import 'package:flutter/material.dart';
import 'Home_contents/home_content.dart'; // Import the HomeContent file
import '../components/footer.dart';
import 'wallet/wallet.dart';
import 'history/history.dart';
import 'profile/profile.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'; // Import the foreground task package
// import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  final String username;
  final int? userId;
  final String email;
    final Map<String, dynamic>? selectedLocation; // Accept the selected location


  const HomePage({super.key, required this.username, this.userId, required this.email, this.selectedLocation});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pageIndex = 0;
  final GlobalKey<FooterState> _footerKey = GlobalKey();


  @override
  void initState() {
    super.initState();
    startForegroundService(); // Start the foreground service
  }

  
  @override
  void dispose() {
    FlutterForegroundTask.stopService(); // Stop the foreground service when the app is closed
    //  _connectivitySubscription.cancel();
    super.dispose();
  }


  void startForegroundService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service_channel',
        channelName: 'Foreground Service Channel',
        channelDescription: 'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
        iconData: const NotificationIconData(
          resType: ResourceType.drawable,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000, // The interval at which the foreground task will be executed (in milliseconds)
        isOnceEvent: false, // Whether to execute the task only once
        autoRunOnBoot: true, // Whether to automatically run the task on boot
      ),
    );

    FlutterForegroundTask.startService(
      notificationTitle: 'App is running',
      notificationText: 'Your app is running in the background',
      callback: startCallback,
    );
  }

  void startCallback() {
    FlutterForegroundTask.setTaskHandler(YourTaskHandler());
  }

  void _onTabChanged(int index) {
    setState(() {
      _pageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _pageOptions = [
      HomeContent(username: widget.username, userId: widget.userId, email: widget.email, selectedLocation: widget.selectedLocation),
      WalletPage(username: widget.username, userId: widget.userId, email: widget.email ),
      HistoryPage(username: widget.username, userId: widget.userId),
      ProfilePage(username: widget.username, userId: widget.userId, email: widget.email),
    ];

    return WillPopScope(
      onWillPop: () async {
        final footerState = _footerKey.currentState;
        if (footerState != null) {
          return footerState.handleBackPress();
        }
        return true;
      },
      child: Scaffold(
        body: _pageOptions[_pageIndex],
        bottomNavigationBar: Footer(
          username:widget.username,
          userId:widget.userId,
          email: widget.email,
          key: _footerKey,
          onTabChanged: _onTabChanged,
        ),
      ),
    );
  }
}

class YourTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // Perform any initialization you need here.
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Your background task logic here
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // Cleanup tasks when the foreground service is destroyed
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp(); // Bring your app to the foreground
  }
}


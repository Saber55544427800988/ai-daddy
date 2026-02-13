import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'notification_service.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Foreground Service — keeps the app alive like WhatsApp/Telegram.
// Shows a small persistent notification: "AI Daddy is running"
// This prevents Android/OEMs from killing the app's background processes.
// ──────────────────────────────────────────────────────────────────────────────

class AIDaddyForegroundService {
  static final AIDaddyForegroundService instance =
      AIDaddyForegroundService._();
  AIDaddyForegroundService._();

  bool _isRunning = false;

  /// Initialize and configure the foreground task.
  Future<void> init() async {
    FlutterForegroundTask.initCommunicationPort();

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'ai_daddy_foreground',
        channelName: 'AI Daddy Background Service',
        channelDescription: 'Keeps AI Daddy running for reminders',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000), // every 60s
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  /// Start the foreground service.
  Future<void> start() async {
    if (_isRunning) return;

    // Check if already running
    if (await FlutterForegroundTask.isRunningService) {
      _isRunning = true;
      return;
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: 200,
      notificationTitle: 'AI Daddy 💙',
      notificationText: 'Keeping your reminders active',
      callback: _foregroundTaskCallback,
    );

    _isRunning = result is ServiceRequestSuccess;
  }

  /// Stop the foreground service.
  Future<void> stop() async {
    await FlutterForegroundTask.stopService();
    _isRunning = false;
  }

  bool get isRunning => _isRunning;
}

// ──────────────────────────────────────────────────────────────────────────────
// Top-level callback — runs in background isolate
// ──────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
void _foregroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_AIDaddyTaskHandler());
}

class _AIDaddyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Service started — nothing to initialize here.
    // The main purpose is just keeping the process alive.
    debugPrint('[ForegroundService] Started at $timestamp');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Called every 60 seconds — keeps the process alive.
    // We don't need to do anything here, the service existing
    // is enough to prevent Android from killing our timers.
    FlutterForegroundTask.updateService(
      notificationTitle: 'AI Daddy 💙',
      notificationText: 'Keeping your reminders active',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('[ForegroundService] Destroyed at $timestamp');
  }
}

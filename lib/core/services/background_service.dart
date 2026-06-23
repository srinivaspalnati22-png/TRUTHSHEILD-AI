import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backgroundServiceProvider =
    Provider<BackgroundService>((ref) => BackgroundService());

/// Manages communication with the Android NotificationListenerService
/// and handles showing local notifications from the Flutter side as well.
class BackgroundService {
  static const _permissionChannel =
      MethodChannel('com.trustshield.ai/permissions');
  static const _notificationEventChannel =
      EventChannel('com.trustshield.ai/notifications');

  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  StreamSubscription? _eventSubscription;

  /// Callback called when a threat is detected by the background service
  void Function(Map<String, dynamic>)? onThreatDetected;

  /// How many threats detected in this session
  int threatCount = 0;

  BackgroundService() {
    _initLocalNotifications();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // User tapped a notification — handled by the Android side via PendingIntent
      },
    );

    // Create notification channels
    final androidPlugin =
        _localNotif.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'trustshield_alerts',
          'Threat Alerts',
          description: 'Alerts for detected scams and threats',
          importance: Importance.high,
          enableVibration: true,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'trustshield_foreground',
          'Background Protection',
          description: 'Keeps TrustShield running in background',
          importance: Importance.low,
          showBadge: false,
        ),
      );
    }
  }

  /// Check if the Notification Listener permission is granted
  Future<bool> isNotificationListenerGranted() async {
    try {
      final bool result = await _permissionChannel
          .invokeMethod('isNotificationListenerGranted');
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Opens the system Notification Access settings page
  Future<void> requestNotificationListenerPermission() async {
    try {
      await _permissionChannel
          .invokeMethod('requestNotificationListenerPermission');
    } catch (e) {
      // Ignore
    }
  }

  /// Opens the system Overlay settings page (for floating alerts)
  Future<void> requestOverlayPermission() async {
    try {
      await _permissionChannel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      // Ignore
    }
  }

  /// Show a threat notification from Flutter side (supplementary)
  Future<void> showThreatNotification({
    required String appName,
    required String summary,
    required int trustScore,
    required String content,
  }) async {
    final emoji = trustScore < 20
        ? '🚨'
        : trustScore < 40
            ? '⚠️'
            : '⚡';

    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '$emoji TrustShield Alert — $appName',
      summary,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'trustshield_alerts',
          'Threat Alerts',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(
            '$summary\n\nMessage: ${content.take(150)}',
            contentTitle: '$emoji THREAT DETECTED — Trust Score: $trustScore/100',
          ),
          color: const Color(0xFFE53935),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Start listening to threat events from the Android service
  /// (works when app is in foreground)
  void startListening() {
    _eventSubscription?.cancel();
    _eventSubscription =
        _notificationEventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        try {
          final Map<String, dynamic> data =
              Map<String, dynamic>.from(jsonDecode(event as String));
          threatCount++;
          onThreatDetected?.call(data);
        } catch (e) {
          // Ignore malformed events
        }
      },
      onError: (dynamic error) {
        // Channel error — service may not be running
      },
    );
  }

  /// Stop listening to events
  void stopListening() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  void dispose() {
    stopListening();
  }
}

extension _StringTake on String {
  String take(int n) => length > n ? substring(0, n) : this;
}

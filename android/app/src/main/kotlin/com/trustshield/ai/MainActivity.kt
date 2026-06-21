package com.trustshield.ai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {

    private val NOTIFICATION_CHANNEL = "com.trustshield.ai/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // EventChannel for notification data from Android → Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    TrustShieldNotificationService.setEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    TrustShieldNotificationService.setEventSink(null)
                }
            })
    }
}

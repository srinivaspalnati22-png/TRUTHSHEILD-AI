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

        // MethodChannel for permission requests
        io.flutter.plugin.common.MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.trustshield.ai/permissions")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestNotificationListenerPermission" -> {
                        val intent = android.content.Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                        startActivity(intent)
                        result.success(true)
                    }
                    "isNotificationListenerGranted" -> {
                        val componentName = android.content.ComponentName(context, TrustShieldNotificationService::class.java)
                        val enabledListeners = android.provider.Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
                        val isEnabled = enabledListeners != null && enabledListeners.contains(componentName.flattenToString())
                        result.success(isEnabled)
                    }
                    "requestOverlayPermission" -> {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                            if (!android.provider.Settings.canDrawOverlays(context)) {
                                val intent = android.content.Intent(android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION, android.net.Uri.parse("package:" + context.packageName))
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.success(true)
                            }
                        } else {
                            result.success(true)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

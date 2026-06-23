package com.trustshield.ai

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val NOTIFICATION_CHANNEL = "com.trustshield.ai/notifications"
    private val PERMISSIONS_CHANNEL = "com.trustshield.ai/permissions"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // EventChannel: Android notification events → Flutter (when app is open)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    TrustShieldNotificationService.setEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    TrustShieldNotificationService.setEventSink(null)
                }
            })

        // MethodChannel: Flutter → Android for permission management
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "isNotificationListenerGranted" -> {
                        result.success(isNotificationListenerEnabled())
                    }

                    "requestNotificationListenerPermission" -> {
                        try {
                            val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SETTINGS_ERROR", e.message, null)
                        }
                    }

                    "requestOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            if (!Settings.canDrawOverlays(context)) {
                                val intent = Intent(
                                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    Uri.parse("package:${context.packageName}")
                                )
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                            }
                        }
                        result.success(true)
                    }

                    "requestPostNotificationsPermission" -> {
                        // Android 13+ POST_NOTIFICATIONS permission is handled by permission_handler
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val componentName = ComponentName(context, TrustShieldNotificationService::class.java)
        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        )
        return enabledListeners != null &&
                enabledListeners.contains(componentName.flattenToString())
    }
}

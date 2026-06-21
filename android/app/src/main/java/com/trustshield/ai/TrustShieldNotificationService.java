package com.trustshield.ai;

import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.app.Notification;
import android.os.Bundle;
import android.util.Log;
import io.flutter.plugin.common.EventChannel;
import io.flutter.embedding.engine.FlutterEngine;

import java.util.HashMap;
import java.util.Map;

public class TrustShieldNotificationService extends NotificationListenerService {

    private static final String TAG = "TrustShieldNS";
    private static EventChannel.EventSink eventSink;

    // Apps to monitor
    private static final String[] MONITORED_APPS = {
        "com.whatsapp",
        "com.whatsapp.w4b",
        "com.google.android.gm",
        "org.telegram.messenger",
        "com.instagram.android",
        "com.linkedin.android",
        "com.facebook.katana",
    };

    public static void setEventSink(EventChannel.EventSink sink) {
        eventSink = sink;
    }

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        try {
            String packageName = sbn.getPackageName();

            if (!isMonitoredApp(packageName)) return;

            Notification notification = sbn.getNotification();
            Bundle extras = notification.extras;

            if (extras == null) return;

            String title = extras.getString(Notification.EXTRA_TITLE, "");
            String text = extras.getString(Notification.EXTRA_TEXT, "");
            String bigText = extras.getString(Notification.EXTRA_BIG_TEXT, "");

            // Only process if there's meaningful content
            String content = bigText.isEmpty() ? text : bigText;
            if (content == null || content.trim().isEmpty()) return;

            // Quick pre-filter: check for common scam keywords before AI
            if (!containsScamKeywords(content + " " + title)) return;

            // Build data map
            Map<String, Object> notificationData = new HashMap<>();
            notificationData.put("packageName", packageName);
            notificationData.put("title", title != null ? title : "");
            notificationData.put("content", content);
            notificationData.put("appName", getAppName(packageName));
            notificationData.put("timestamp", System.currentTimeMillis());

            // Send to Flutter
            if (eventSink != null) {
                eventSink.success(notificationData);
            }

            Log.d(TAG, "Suspicious notification from: " + packageName);

        } catch (Exception e) {
            Log.e(TAG, "Error processing notification: " + e.getMessage());
        }
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {
        // Not needed
    }

    private boolean isMonitoredApp(String packageName) {
        for (String app : MONITORED_APPS) {
            if (app.equals(packageName)) return true;
        }
        return false;
    }

    private boolean containsScamKeywords(String text) {
        if (text == null) return false;
        String lower = text.toLowerCase();
        String[] keywords = {
            "fee", "registration", "payment", "free job", "work from home",
            "earn money", "internship", "scholarship", "congratulations",
            "selected", "offer", "click here", "link", "urgent", "immediately",
            "verify", "otp", "account", "bank", "kyc", "debit", "credit",
            "lottery", "winner", "prize", "reward", "investment", "return",
            "₹", "rs.", "rupee", "lakh", "crore"
        };
        for (String keyword : keywords) {
            if (lower.contains(keyword)) return true;
        }
        return false;
    }

    private String getAppName(String packageName) {
        switch (packageName) {
            case "com.whatsapp": return "WhatsApp";
            case "com.google.android.gm": return "Gmail";
            case "org.telegram.messenger": return "Telegram";
            case "com.instagram.android": return "Instagram";
            case "com.linkedin.android": return "LinkedIn";
            case "com.facebook.katana": return "Facebook";
            default: return "Unknown";
        }
    }
}

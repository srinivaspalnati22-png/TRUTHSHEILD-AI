package com.trustshield.ai

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

class TrustShieldNotificationService : NotificationListenerService() {

    companion object {
        private const val TAG = "TrustShieldNS"
        private const val ALERT_CHANNEL_ID = "trustshield_alerts"
        private const val FOREGROUND_CHANNEL_ID = "trustshield_foreground"
        private const val FOREGROUND_NOTIF_ID = 1001

        // API key is injected at build time via BuildConfig (see build.gradle)
        // Never hardcode keys in source — use: flutter build apk --dart-define=GEMINI_API_KEY=AIzaSy...
        private const val API_KEY = BuildConfig.GEMINI_API_KEY
        // Using gemini-1.5-flash: free-tier compatible, no billing required
        private const val GEMINI_URL =
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$API_KEY"

        // Apps to monitor (package names)
        private val MONITORED_APPS = setOf(
            "com.whatsapp",
            "com.whatsapp.w4b",
            "com.google.android.gm",       // Gmail
            "org.telegram.messenger",
            "org.telegram.plus",
            "com.android.mms",             // Default SMS
            "com.google.android.apps.messaging", // Google Messages
            "com.samsung.android.messaging",
            "com.instagram.android",
            "com.facebook.orca",           // Messenger
            "com.linkedin.android",
        )

        // Scam keywords for quick pre-filter (no API call needed for obviously safe notifications)
        private val SCAM_KEYWORDS = listOf(
            "registration fee", "reg fee", "joining fee", "training fee",
            "internship", "job offer", "work from home", "wfh",
            "earn", "₹", "rs.", "lakh", "salary", "package",
            "click here", "verify", "urgent", "limited time", "congratulations",
            "selected", "hired", "offer letter", "kyc", "otp",
            "bank account", "transfer", "payment", "advance",
            "free laptop", "government scheme", "pm scheme",
            "crypto", "investment", "returns", "profit",
        )

        private var eventSink: EventChannel.EventSink? = null
        private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

        // Debounce: avoid duplicate scans of same notification
        private val recentlyScanned = mutableMapOf<String, Long>()
        private const val DEBOUNCE_MS = 5000L

        fun setEventSink(sink: EventChannel.EventSink?) {
            eventSink = sink
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
        startForeground(FOREGROUND_NOTIF_ID, buildForegroundNotification())
        Log.d(TAG, "TrustShield notification monitoring started")
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        Log.d(TAG, "TrustShield notification monitoring stopped")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName

        // Only process monitored apps
        if (!MONITORED_APPS.contains(packageName)) return

        val extras = sbn.notification?.extras ?: return
        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: text

        val content = "$title $bigText".trim()
        if (content.length < 10) return // Too short to be meaningful

        // Debounce: skip if same notification was processed recently
        val key = "${packageName}_${content.take(50).hashCode()}"
        val now = System.currentTimeMillis()
        if ((recentlyScanned[key] ?: 0) > now - DEBOUNCE_MS) return
        recentlyScanned[key] = now

        // Clean up old entries
        if (recentlyScanned.size > 100) {
            recentlyScanned.entries.removeIf { it.value < now - 60000 }
        }

        // Quick pre-filter: only call AI if content has suspicious keywords
        val contentLower = content.lowercase()
        val hasSuspiciousKeywords = SCAM_KEYWORDS.any { contentLower.contains(it) }

        if (!hasSuspiciousKeywords) return // Not suspicious, skip AI call

        Log.d(TAG, "Suspicious notification from $packageName: $content")

        // Run AI analysis in background
        serviceScope.launch {
            try {
                val result = analyzeWithGemini(content, packageName)
                val trustScore = result.optInt("trustScore", 50)
                val threatLevel = result.optString("threatLevel", "medium")
                val summary = result.optString("summary", "Suspicious message detected")

                Log.d(TAG, "Analysis result: trustScore=$trustScore, threat=$threatLevel")

                // Only alert if genuinely suspicious (score < 50)
                if (trustScore < 50) {
                    // Show a local threat alert notification
                    showThreatAlert(
                        appName = getAppName(packageName),
                        title = title,
                        content = bigText,
                        trustScore = trustScore,
                        summary = summary,
                    )

                    // Also send data to Flutter via EventChannel (if app is open)
                    val payload = JSONObject().apply {
                        put("appName", getAppName(packageName))
                        put("packageName", packageName)
                        put("title", title)
                        put("content", bigText.take(300))
                        put("trustScore", trustScore)
                        put("threatLevel", threatLevel)
                        put("summary", summary)
                        put("timestamp", System.currentTimeMillis())
                    }

                    // Post to Flutter main thread
                    serviceScope.launch(Dispatchers.Main) {
                        try {
                            eventSink?.success(payload.toString())
                        } catch (e: Exception) {
                            Log.e(TAG, "EventSink error: ${e.message}")
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Analysis error: ${e.message}")
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // Not needed
    }

    private suspend fun analyzeWithGemini(content: String, packageName: String): JSONObject {
        return withContext(Dispatchers.IO) {
            val prompt = """You are TrustShield AI. Analyze this notification from $packageName for scam/fraud patterns.

NOTIFICATION: "$content"

Look for: registration fees, fake job offers, phishing links, advance payment requests, fake schemes.

Return ONLY valid JSON:
{"trustScore":<0-100>,"threatLevel":"<safe|low|medium|high|critical>","summary":"<one line>","isScam":<true|false>}"""

            val requestBody = JSONObject().apply {
                put("contents", JSONArray().apply {
                    put(JSONObject().apply {
                        put("parts", JSONArray().apply {
                            put(JSONObject().apply {
                                put("text", prompt)
                            })
                        })
                    })
                })
                put("generationConfig", JSONObject().apply {
                    put("temperature", 0.1)
                    put("maxOutputTokens", 256)
                    put("responseMimeType", "application/json")
                })
            }

            val url = URL(GEMINI_URL)
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/json")
            conn.doOutput = true
            conn.connectTimeout = 15000
            conn.readTimeout = 15000

            OutputStreamWriter(conn.outputStream).use { it.write(requestBody.toString()) }

            if (conn.responseCode == 200) {
                val response = BufferedReader(InputStreamReader(conn.inputStream)).readText()
                val data = JSONObject(response)
                val rawText = data.getJSONArray("candidates")
                    .getJSONObject(0)
                    .getJSONObject("content")
                    .getJSONArray("parts")
                    .getJSONObject(0)
                    .getString("text")
                    .trim()
                    .replace("```json", "")
                    .replace("```", "")
                    .trim()
                // Try to parse JSON; if it fails extract with regex
                try {
                    JSONObject(rawText)
                } catch (e: Exception) {
                    val jsonRegex = Regex("\\{[\\s\\S]*\\}")
                    val match = jsonRegex.find(rawText)
                    if (match != null) JSONObject(match.value)
                    else JSONObject().apply {
                        put("trustScore", 50)
                        put("threatLevel", "medium")
                        put("summary", "Could not parse response")
                        put("isScam", false)
                    }
                }
            } else {
                Log.w(TAG, "Gemini API error: ${conn.responseCode}. Check API key at https://aistudio.google.com/")
                JSONObject().apply {
                    put("trustScore", 50)
                    put("threatLevel", "medium")
                    put("summary", "Could not analyze (API error ${conn.responseCode})")
                    put("isScam", false)
                }
            }
        }
    }

    private fun showThreatAlert(
        appName: String,
        title: String,
        content: String,
        trustScore: Int,
        summary: String,
    ) {
        val notifManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Intent to open app when notification is tapped
        val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("from_notification", true)
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent ?: Intent(),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val emoji = when {
            trustScore < 20 -> "🚨"
            trustScore < 40 -> "⚠️"
            else -> "⚡"
        }

        val notification = NotificationCompat.Builder(this, ALERT_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("$emoji TrustShield Alert — $appName")
            .setContentText(summary)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("$summary\n\nMessage: ${content.take(150)}")
                    .setBigContentTitle("$emoji THREAT DETECTED — Trust Score: $trustScore/100")
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setColor(0xFFE53935.toInt())
            .setVibrate(longArrayOf(0, 300, 200, 300))
            .build()

        notifManager.notify(System.currentTimeMillis().toInt(), notification)
    }

    private fun buildForegroundNotification(): Notification {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent ?: Intent(),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, FOREGROUND_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentTitle("🛡️ TrustShield AI Active")
            .setContentText("Monitoring notifications for scams & fraud")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notifManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Threat alert channel (high priority)
            NotificationChannel(
                ALERT_CHANNEL_ID,
                "Threat Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alerts for detected scams and threats"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 300, 200, 300)
                notifManager.createNotificationChannel(this)
            }

            // Foreground service channel (silent)
            NotificationChannel(
                FOREGROUND_CHANNEL_ID,
                "Background Protection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps TrustShield running in background"
                setShowBadge(false)
                notifManager.createNotificationChannel(this)
            }
        }
    }

    private fun getAppName(packageName: String): String {
        return when (packageName) {
            "com.whatsapp", "com.whatsapp.w4b" -> "WhatsApp"
            "com.google.android.gm" -> "Gmail"
            "org.telegram.messenger", "org.telegram.plus" -> "Telegram"
            "com.android.mms", "com.google.android.apps.messaging",
            "com.samsung.android.messaging" -> "SMS"
            "com.instagram.android" -> "Instagram"
            "com.facebook.orca" -> "Messenger"
            "com.linkedin.android" -> "LinkedIn"
            else -> packageName.substringAfterLast(".")
                .replaceFirstChar { it.uppercase() }
        }
    }
}

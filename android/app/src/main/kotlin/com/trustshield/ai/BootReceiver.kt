package com.trustshield.ai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Starts the app after device reboot so background monitoring is always on.
 * Requires RECEIVE_BOOT_COMPLETED permission (already in AndroidManifest).
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON"
        ) {
            Log.d("BootReceiver", "Device booted — launching TrustShield")
            // Launch the main app so Flutter engine starts and notification service binds
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    putExtra("from_boot", true)
                }
            launchIntent?.let { context.startActivity(it) }
        }
    }
}

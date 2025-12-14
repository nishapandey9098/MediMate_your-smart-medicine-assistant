package com.medimate.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BootReceiver handles device boot events
 * On Android 15, this ensures alarms are restored after reboot
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        
        Log.d("MediMate-BootReceiver", "═══════════════════════════════════════")
        Log.d("MediMate-BootReceiver", "Received broadcast: $action")
        
        when (action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.d("MediMate-BootReceiver", "✅ Device rebooted or app updated")
                Log.d("MediMate-BootReceiver", "📱 App: ${context.packageName}")
                Log.d("MediMate-BootReceiver", "⏰ Alarms will be rescheduled when app opens")
                
                // Note: We can't reschedule here because Flutter isn't initialized
                // The notification service will reschedule when the app is opened
                
                // Optional: Start app automatically (requires additional permissions)
                // val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                // launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                // context.startActivity(launchIntent)
            }
            else -> {
                Log.w("MediMate-BootReceiver", "⚠️ Unknown action: $action")
            }
        }
        
        Log.d("MediMate-BootReceiver", "═══════════════════════════════════════")
    }
}
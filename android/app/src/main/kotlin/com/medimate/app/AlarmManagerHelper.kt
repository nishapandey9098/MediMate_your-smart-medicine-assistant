package com.medimate.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

object AlarmManagerHelper {
    
    private const val ACTION = "com.medimate.app.ALARM_ACTION"
    
    fun scheduleExactAlarm(
        context: Context,
        notificationId: Int,
        medicineName: String,
        dosage: String,
        instructions: String,
        triggerTimeMillis: Long
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        // Check permission (Android 12+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!alarmManager.canScheduleExactAlarms()) {
                Log.e("MediMate-Alarm", "❌ Cannot schedule exact alarms - permission denied")
                return
            }
        }
        
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION
            putExtra(AlarmReceiver.NOTIFICATION_ID_KEY, notificationId)
            putExtra(AlarmReceiver.MEDICINE_NAME_KEY, medicineName)
            putExtra(AlarmReceiver.DOSAGE_KEY, dosage)
            putExtra(AlarmReceiver.INSTRUCTIONS_KEY, instructions)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        // Cancel existing alarm with same ID
        alarmManager.cancel(pendingIntent)
        
        // Schedule new alarm using setExactAndAllowWhileIdle (works even in Doze mode)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerTimeMillis,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                triggerTimeMillis,
                pendingIntent
            )
        }
        
        Log.d("MediMate-Alarm", "✅ Alarm scheduled: ID $notificationId at ${java.util.Date(triggerTimeMillis)}")
    }
    
    fun cancelAlarm(context: Context, notificationId: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_NO_CREATE
        )
        
        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
            Log.d("MediMate-Alarm", "🗑️ Alarm cancelled: ID $notificationId")
        }
    }
}


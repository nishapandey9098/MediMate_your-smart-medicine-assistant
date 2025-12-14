package com.medimate.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import java.util.*
import android.os.PowerManager


class AlarmReceiver : BroadcastReceiver() {
    
    companion object {
        const val CHANNEL_ID = "medicine_reminders"
        const val NOTIFICATION_ID_KEY = "notification_id"
        const val MEDICINE_NAME_KEY = "medicine_name"
        const val DOSAGE_KEY = "dosage"
        const val INSTRUCTIONS_KEY = "instructions"
    }
    
    private var tts: TextToSpeech? = null
    
    override fun onReceive(context: Context, intent: Intent) {
        val notificationId = intent.getIntExtra(NOTIFICATION_ID_KEY, 0)
        val medicineName = intent.getStringExtra(MEDICINE_NAME_KEY) ?: "Medicine"
        val dosage = intent.getStringExtra(DOSAGE_KEY) ?: ""
        val instructions = intent.getStringExtra(INSTRUCTIONS_KEY) ?: ""
        
        android.util.Log.d("MediMate-Alarm", "🔔 ALARM FIRED! ID: $notificationId, Medicine: $medicineName")

         // ✅ ADD THIS LINE: Notify Flutter that alarm fired
    MainActivity.sendAlarmFired(notificationId)

        
          // Acquire a wakelock so TTS can complete even if device goes to sleep
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "MediMate::AlarmWakeLock")
        wakeLock.acquire(30_000) // 30 seconds
        try{
        // Show notification
        createNotificationChannel(context)
        showNotification(context, notificationId, medicineName, dosage, instructions)
        
        // Speak reminder using TTS
        speakReminder(context, medicineName, dosage, instructions)
    }finally {
            if (wakeLock.isHeld) {
                wakeLock.release()
            }
        }
    }
    
    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Medicine Reminders",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Time-sensitive medicine reminders"
                enableLights(true)
                enableVibration(true)
                setBypassDnd(true)
            }
            
            val manager = context.getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }
    
    private fun showNotification(
        context: Context,
        notificationId: Int,
        medicineName: String,
        dosage: String,
        instructions: String
    ) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        val body = buildString {
            append("$medicineName - $dosage")
            if (instructions.isNotEmpty()) {
                append("\n$instructions")
            }
        }
        
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("💊 Medicine Reminder")
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(false)
            .setOngoing(false)
            .setVibrate(longArrayOf(0, 1000, 500, 1000))
            .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
            .setContentIntent(pendingIntent)
            .setFullScreenIntent(pendingIntent, true)
            .build()
        
        with(NotificationManagerCompat.from(context)) {
            notify(notificationId, notification)
        }
        
        android.util.Log.d("MediMate-Alarm", "✅ Notification shown: ID $notificationId")
    }
    
    private fun speakReminder(
        context: Context,
        medicineName: String,
        dosage: String,
        instructions: String
    ) {
        android.util.Log.d("MediMate-Alarm", "🔊 Initializing TTS...")
        
        tts = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                val result = tts?.setLanguage(Locale.US)
                
                if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                    android.util.Log.e("MediMate-Alarm", "❌ TTS Language not supported")
                    return@TextToSpeech
                }
                
                tts?.setSpeechRate(0.9f)
                tts?.setPitch(1.0f)
                
                val message = buildReminderMessage(medicineName, dosage, instructions)
                
                tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) {
                        android.util.Log.d("MediMate-Alarm", "🔊 TTS started speaking")
                    }
                    
                    override fun onDone(utteranceId: String?) {
                        android.util.Log.d("MediMate-Alarm", "✅ TTS finished speaking")
                        tts?.stop()
                        tts?.shutdown()
                        tts = null
                    }
                    
                    override fun onError(utteranceId: String?) {
                        android.util.Log.e("MediMate-Alarm", "❌ TTS error")
                        tts?.shutdown()
                        tts = null
                    }
                })
                
                val params = Bundle()
                params.putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, "reminder_${System.currentTimeMillis()}")
                
                android.util.Log.d("MediMate-Alarm", "🔊 Speaking: $message")
                tts?.speak(message, TextToSpeech.QUEUE_FLUSH, params, "reminder_${System.currentTimeMillis()}")
                
            } else {
                android.util.Log.e("MediMate-Alarm", "❌ TTS initialization failed")
            }
        }
    }
    
    private fun buildReminderMessage(
        medicineName: String,
        dosage: String,
        instructions: String
    ): String {
        return buildString {
            append("Time to take your medicine. ")
            append("$medicineName, ")
            
            val spokenDosage = convertDosageToSpeech(dosage)
            append("$spokenDosage. ")
            
            if (instructions.isNotEmpty()) {
                append("$instructions. ")
            }
            
            append("Please take your medicine now.")
        }
    }
    
    private fun convertDosageToSpeech(dosage: String): String {
        return dosage
            .replace("mg", " milligrams", ignoreCase = true)
            .replace("ml", " milliliters", ignoreCase = true)
            .replace("g", " grams", ignoreCase = true)
            .replace("mcg", " micrograms", ignoreCase = true)
            .trim()
    }
}

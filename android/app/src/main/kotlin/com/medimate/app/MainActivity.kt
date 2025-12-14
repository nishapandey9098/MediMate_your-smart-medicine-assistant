package com.medimate.app

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.medimate.app/native_alarm"
    private val EVENT_CHANNEL = "com.medimate.app/alarm_events"

    companion object {
        // ✅ Static EventChannel sink to send events from anywhere
        var alarmEventSink: EventChannel.EventSink? = null
        
        // ✅ Send alarm fired event to Flutter
        fun sendAlarmFired(id: Int) {
            android.util.Log.d("MediMate-MainActivity", "📤 Sending alarm fired event: ID $id")
            alarmEventSink?.success(mapOf(
                "event" to "alarm_fired",
                "id" to id
            ))
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ✅ Setup MethodChannel (existing alarm scheduling)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleAlarm" -> {
                        val id = call.argument<Int>("id") ?: 0
                        val medicineName = call.argument<String>("medicineName") ?: ""
                        val dosage = call.argument<String>("dosage") ?: ""
                        val instructions = call.argument<String>("instructions") ?: ""
                        val triggerTimeMillis = call.argument<Long>("triggerTimeMillis") ?: 0L

                        AlarmManagerHelper.scheduleExactAlarm(
                            context,
                            id,
                            medicineName,
                            dosage,
                            instructions,
                            triggerTimeMillis
                        )
                        result.success(true)
                    }
                    "cancelAlarm" -> {
                        val id = call.argument<Int>("id") ?: 0
                        AlarmManagerHelper.cancelAlarm(context, id)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // ✅ Setup EventChannel (new - for alarm fired events)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    android.util.Log.d("MediMate-MainActivity", "📡 EventChannel listener attached")
                    alarmEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    android.util.Log.d("MediMate-MainActivity", "📡 EventChannel listener detached")
                    alarmEventSink = null
                }
            })
    }
}


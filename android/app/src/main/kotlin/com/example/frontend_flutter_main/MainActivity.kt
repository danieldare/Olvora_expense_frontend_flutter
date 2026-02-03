package com.example.frontend_flutter_main

import android.app.Notification
import android.content.Intent
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.trackspend/notifications"
    private val EVENT_CHANNEL = "com.trackspend/notifications/stream"
    private val AUDIO_RECORD_CHANNEL = "com.olvora/audio_record"
    private val AUDIO_RECORD_EVENT_CHANNEL = "com.olvora/audio_record/stream"
    private var eventSink: EventChannel.EventSink? = null
    private var audioRecordManager: AudioRecordManager? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method channel for permission checks and settings
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    val hasPermission = isNotificationListenerEnabled()
                    result.success(hasPermission)
                }
                "requestPermission" -> {
                    openNotificationSettings()
                    result.success(true)
                }
                "openSettings" -> {
                    openNotificationSettings()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Event channel for streaming notifications
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    NotificationListener.setEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    NotificationListener.setEventSink(null)
                }
            }
        )

        // Audio Record Manager - World-Class Voice Input
        val audioMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_RECORD_CHANNEL)
        val audioEventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_RECORD_EVENT_CHANNEL)
        
        audioRecordManager = AudioRecordManager(
            this,
            audioMethodChannel,
            audioEventChannel
        )

        // Method channel for audio recording
        audioMethodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> {
                    val outputPath = call.argument<String>("outputPath")
                    if (outputPath != null) {
                        audioRecordManager?.startRecording(outputPath, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "outputPath is required", null)
                    }
                }
                "stopRecording" -> {
                    audioRecordManager?.stopRecording(result)
                }
                "dispose" -> {
                    audioRecordManager?.dispose()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Event channel for audio level streaming (must be set up separately)
        audioEventChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    audioRecordManager?.setEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    audioRecordManager?.setEventSink(null)
                }
            }
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        audioRecordManager?.dispose()
        audioRecordManager = null
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        )
        return enabledListeners?.contains(packageName) == true
    }

    private fun openNotificationSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        startActivity(intent)
    }
}

// Notification Listener Service
class NotificationListener : NotificationListenerService() {
    companion object {
        private var eventSink: EventChannel.EventSink? = null

        fun setEventSink(sink: EventChannel.EventSink?) {
            eventSink = sink
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        super.onNotificationPosted(sbn)
        
        // Only process if event sink is available
        val sink = eventSink ?: return
        
        val notification = sbn.notification
        val title = notification.extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = notification.extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = notification.extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
        
        // Use big text if available (for expanded notifications)
        val body = bigText ?: text
        
        // Only process notifications that might contain debit alerts
        val packageName = sbn.packageName
        
        // Filter out system notifications and non-financial apps (optional)
        // You can customize this list based on your needs
        val systemPackages = listOf(
            "android",
            "com.android.systemui",
            "com.google.android.gms"
        )
        
        if (systemPackages.contains(packageName)) {
            return
        }
        
        Log.d("NotificationListener", "📱 Notification from $packageName: $title - $body")
        
        // Send to Flutter
        try {
            sink.success(mapOf(
                "title" to title,
                "body" to body,
                "packageName" to packageName
            ))
        } catch (e: Exception) {
            Log.e("NotificationListener", "Error sending notification to Flutter: $e")
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        super.onNotificationRemoved(sbn)
    }
}

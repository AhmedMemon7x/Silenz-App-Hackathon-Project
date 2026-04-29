package com.example.auto_silent

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.autosilence.app/ringer"
    private val TAG     = "AutoSilence"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
        scheduleRepeatingAlarm(this)
        // Start foreground service for background location monitoring
        val serviceIntent = Intent(this, SilenceService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "autosilence_bg", "AutoSilence", NotificationManager.IMPORTANCE_LOW)
            channel.description = "AutoSilence background checker"
            channel.setShowBadge(false)
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                val audio  = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val nm     = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val hasDND = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                    nm.isNotificationPolicyAccessGranted else true

                when (call.method) {

                    // ── Silent: pure volume 0, no DND ──
                    "setSilentOnly" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && hasDND) {
                                nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                            }
                            audio.ringerMode = AudioManager.RINGER_MODE_SILENT
                            audio.setStreamVolume(AudioManager.STREAM_RING, 0, 0)
                            audio.setStreamVolume(AudioManager.STREAM_NOTIFICATION, 0, 0)
                            audio.setStreamVolume(AudioManager.STREAM_SYSTEM, 0, 0)
                            Log.d(TAG, "setSilentOnly: ok")
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "setSilentOnly failed: ${e.message}")
                            result.success(false)
                        }
                    }

                    // ── DND: full interruption filter none ──
                    "setDND" -> {
                        try {
                            if (hasDND && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
                                Log.d(TAG, "setDND: ok")
                                result.success(true)
                            } else {
                                // Fallback if no DND permission
                                audio.ringerMode = AudioManager.RINGER_MODE_SILENT
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "setDND failed: ${e.message}")
                            result.success(false)
                        }
                    }

                    // ── Vibrate: vibrate only ──
                    "setVibrateOnly" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && hasDND) {
                                nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                            }
                            audio.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                            Log.d(TAG, "setVibrateOnly: ok")
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "setVibrateOnly failed: ${e.message}")
                            result.success(false)
                        }
                    }

                    // ── Normal ──
                    "setNormal" -> {
                        try {
                            if (hasDND && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                                nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                            audio.ringerMode = AudioManager.RINGER_MODE_NORMAL
                            Log.d(TAG, "setNormal: ok")
                            result.success(true)
                        } catch (e: Exception) { result.success(false) }
                    }

                    "getRingerMode" -> {
                        val mode = when (audio.ringerMode) {
                            AudioManager.RINGER_MODE_SILENT  -> "Silent"
                            AudioManager.RINGER_MODE_VIBRATE -> "Vibrate"
                            else -> "Normal"
                        }
                        result.success(mode)
                    }

                    "isDNDGranted" -> result.success(hasDND)

                    "openDNDSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            startActivity(intent)
                        } catch (e: Exception) {
                            try { startActivity(Intent(Settings.ACTION_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK }) }
                            catch (_: Exception) {}
                        }
                        result.success(true)
                    }

                    "openBatterySettings" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                                intent.data = Uri.parse("package:$packageName")
                                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                startActivity(intent)
                            }
                        } catch (e: Exception) {
                            try { startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK }) }
                            catch (_: Exception) {}
                        }
                        result.success(true)
                    }

                    "isBatteryOptimized" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        val optimized = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                            !pm.isIgnoringBatteryOptimizations(packageName)
                        else false
                        result.success(optimized)
                    }

                    "scheduleAlarm" -> {
                        scheduleRepeatingAlarm(this)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    companion object {
        private const val TAG = "AutoSilence"

        fun scheduleRepeatingAlarm(context: Context) {
            val am     = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, ScheduleReceiver::class.java)
            val pi     = PendingIntent.getBroadcast(
                context, 1001, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val triggerAt = System.currentTimeMillis() + 30_000L
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            } else {
                am.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            }
            Log.d(TAG, "Next alarm in 30s")
        }
    }
}
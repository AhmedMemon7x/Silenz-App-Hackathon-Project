package com.example.auto_silent

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import org.json.JSONArray

class SilenceService : Service() {

    private val TAG = "AutoSilence"
    private var handler: Handler? = null
    private var checkRunnable: Runnable? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "SilenceService started")
        startForegroundNotification()
        MainActivity.scheduleRepeatingAlarm(this)
        startLocationMonitoring()
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.d(TAG, "App removed from recents — keeping service alive")
        MainActivity.scheduleRepeatingAlarm(this)
        val restartIntent = Intent(applicationContext, SilenceService::class.java)
        restartIntent.setPackage(packageName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(restartIntent)
        } else {
            startService(restartIntent)
        }
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        Log.d(TAG, "SilenceService destroyed — restarting")
        handler?.removeCallbacks(checkRunnable!!)
        val restartIntent = Intent(applicationContext, SilenceService::class.java)
        restartIntent.setPackage(packageName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(restartIntent)
        } else {
            startService(restartIntent)
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startLocationMonitoring() {
        handler = Handler(Looper.getMainLooper())
        checkRunnable = object : Runnable {
            override fun run() {
                checkZonesAndSchedules()
                handler?.postDelayed(this, 30_000L)
            }
        }
        handler?.post(checkRunnable!!)
    }

    private fun checkZonesAndSchedules() {
        val prefs    = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val zonesRaw = prefs.getString("flutter.location_zones", null)

        if (!zonesRaw.isNullOrEmpty()) {
            val location = getLastLocation()
            if (location != null) {
                try {
                    val zones = JSONArray(zonesRaw)
                    for (i in 0 until zones.length()) {
                        val z         = zones.getJSONObject(i)
                        val isEnabled = z.optBoolean("isEnabled", true)
                        if (!isEnabled) continue

                        val zoneLat = z.optDouble("lat")
                        val zoneLng = z.optDouble("lng")
                        val radius  = z.optDouble("radiusMeters", 100.0)
                        val mode    = z.optString("mode", "Silent")

                        val results = FloatArray(1)
                        Location.distanceBetween(
                            location.latitude, location.longitude,
                            zoneLat, zoneLng, results)
                        val distance = results[0]

                        Log.d(TAG, "Zone '${z.optString("name")}' dist=${distance}m radius=${radius}m")

                        if (distance <= radius) {
                            Log.d(TAG, "Inside zone — applying $mode")
                            applyMode(mode)
                            return
                        }
                    }
                    Log.d(TAG, "Outside all zones")
                } catch (e: Exception) {
                    Log.e(TAG, "Zone check error: ${e.message}")
                }
            } else {
                Log.d(TAG, "No location available")
            }
        }

        checkTimeSchedules()
    }

    private fun getLastLocation(): Location? {
        return try {
            val lm = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            val fineGranted   = checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
            val coarseGranted = checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
            if (!fineGranted && !coarseGranted) return null

            val networkLoc = try { lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER) } catch (e: Exception) { null }
            val gpsLoc     = try { lm.getLastKnownLocation(LocationManager.GPS_PROVIDER) } catch (e: Exception) { null }

            when {
                gpsLoc != null && networkLoc != null -> if (gpsLoc.time > networkLoc.time) gpsLoc else networkLoc
                gpsLoc != null     -> gpsLoc
                networkLoc != null -> networkLoc
                else -> try { lm.getLastKnownLocation(LocationManager.PASSIVE_PROVIDER) } catch (e: Exception) { null }
            }
        } catch (e: Exception) {
            Log.e(TAG, "getLastLocation error: ${e.message}")
            null
        }
    }

    private fun checkTimeSchedules() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val raw   = prefs.getString("flutter.bg_schedules", null)
        if (raw.isNullOrEmpty()) { applyMode("Normal"); return }
        try {
            val schedules  = JSONArray(raw)
            val now        = java.util.Calendar.getInstance()
            val today      = dayAbbr(now.get(java.util.Calendar.DAY_OF_WEEK))
            val nowMins    = now.get(java.util.Calendar.HOUR_OF_DAY) * 60 + now.get(java.util.Calendar.MINUTE)
            var activeMode: String? = null

            for (i in 0 until schedules.length()) {
                val s         = schedules.getJSONObject(i)
                if (!s.optBoolean("isEnabled", true)) continue
                val days = s.optJSONArray("days") ?: continue
                var hasToday = false
                for (d in 0 until days.length()) { if (days.getString(d) == today) { hasToday = true; break } }
                if (!hasToday) continue
                val start    = toMins(s.optString("startTime", "00:00"))
                val end      = toMins(s.optString("endTime",   "00:00"))
                val isActive = if (end > start) nowMins >= start && nowMins < end else nowMins >= start || nowMins < end
                if (isActive) { activeMode = s.optString("mode", "Silent"); break }
            }
            applyMode(activeMode ?: "Normal")
        } catch (e: Exception) {
            Log.e(TAG, "Schedule check error: ${e.message}")
        }
    }

    private fun applyMode(mode: String) {
        val audio  = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val nm     = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val hasDND = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) nm.isNotificationPolicyAccessGranted else true
        try {
            when (mode) {
                "Silent" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && hasDND)
                        nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                    audio.ringerMode = AudioManager.RINGER_MODE_SILENT
                    audio.setStreamVolume(AudioManager.STREAM_RING, 0, 0)
                    audio.setStreamVolume(AudioManager.STREAM_NOTIFICATION, 0, 0)
                    audio.setStreamVolume(AudioManager.STREAM_SYSTEM, 0, 0)
                    Log.d(TAG, "Applied: Silent")
                }
                "DND" -> {
                    if (hasDND && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                        nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
                    else audio.ringerMode = AudioManager.RINGER_MODE_SILENT
                    Log.d(TAG, "Applied: DND")
                }
                "Vibrate" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && hasDND)
                        nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                    audio.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                    Log.d(TAG, "Applied: Vibrate")
                }
                else -> {
                    if (hasDND && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                        nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                    audio.ringerMode = AudioManager.RINGER_MODE_NORMAL
                    Log.d(TAG, "Applied: Normal")
                }
            }
        } catch (e: Exception) { Log.e(TAG, "applyMode error: ${e.message}") }
    }

    private fun toMins(time: String): Int { val p = time.split(":"); return p[0].toInt() * 60 + p[1].toInt() }

    private fun dayAbbr(dow: Int) = when (dow) {
        java.util.Calendar.MONDAY    -> "Mon"
        java.util.Calendar.TUESDAY   -> "Tue"
        java.util.Calendar.WEDNESDAY -> "Wed"
        java.util.Calendar.THURSDAY  -> "Thu"
        java.util.Calendar.FRIDAY    -> "Fri"
        java.util.Calendar.SATURDAY  -> "Sat"
        java.util.Calendar.SUNDAY    -> "Sun"
        else -> ""
    }

    private fun startForegroundNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("autosilence_bg", "AutoSilence", NotificationManager.IMPORTANCE_MIN)
            channel.setShowBadge(false)
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(channel)
        }
        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, "autosilence_bg")
                .setContentTitle("Silenz Active")
                .setContentText("Monitoring schedules & location zones")
                .setSmallIcon(android.R.drawable.ic_lock_silent_mode)
                .setOngoing(true).build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("Silenz Active")
                .setContentText("Monitoring schedules & location zones")
                .setSmallIcon(android.R.drawable.ic_lock_silent_mode)
                .setOngoing(true).build()
        }
        startForeground(1002, notification)
    }
}
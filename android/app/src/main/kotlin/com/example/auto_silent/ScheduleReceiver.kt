package com.example.auto_silent

import android.Manifest
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.media.AudioManager
import android.os.Build
import android.util.Log
import org.json.JSONArray
import java.util.Calendar

class ScheduleReceiver : BroadcastReceiver() {

    private val TAG = "AutoSilence"

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Alarm fired — checking schedules")
        checkAndApply(context)
        MainActivity.scheduleRepeatingAlarm(context)
    }

    @androidx.annotation.RequiresApi(Build.VERSION_CODES.M)
    private fun checkAndApply(context: Context) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        // ── Check location zones first (higher priority) ──
        val zonesRaw = prefs.getString("flutter.location_zones", null)
        if (!zonesRaw.isNullOrEmpty()) {
            try {
                val zones = JSONArray(zonesRaw)
                val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

                val lastLocation = try {
                    val fineGranted   = context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)   == PackageManager.PERMISSION_GRANTED
                    val coarseGranted = context.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
                    if (fineGranted || coarseGranted) {
                        locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                            ?: locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
                            ?: locationManager.getLastKnownLocation(LocationManager.PASSIVE_PROVIDER)
                    } else {
                        Log.d(TAG, "Location permission not granted")
                        null
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Location error: ${e.message}")
                    null
                }

                if (lastLocation != null) {
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
                            lastLocation.latitude, lastLocation.longitude,
                            zoneLat, zoneLng, results)
                        val distance = results[0]

                        Log.d(TAG, "Zone '${z.optString("name")}' distance=${distance}m radius=${radius}m mode=$mode")

                        if (distance <= radius) {
                            Log.d(TAG, "Inside zone — applying $mode")
                            applyMode(context, mode)
                            return
                        }
                    }
                    Log.d(TAG, "Outside all zones — checking time schedules")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Zone check error: ${e.message}")
            }
        }

        // ── Check time-based schedules ──
        val raw = prefs.getString("flutter.bg_schedules", null)
        if (raw.isNullOrEmpty()) {
            Log.d(TAG, "No schedules saved — restoring Normal")
            applyMode(context, "Normal")
            return
        }

        try {
            val schedules = JSONArray(raw)
            val now       = Calendar.getInstance()
            val today     = dayAbbr(now.get(Calendar.DAY_OF_WEEK))
            val nowMins   = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)

            Log.d(TAG, "today=$today nowMins=$nowMins schedules=${schedules.length()}")

            var activeMode: String? = null

            for (i in 0 until schedules.length()) {
                val s         = schedules.getJSONObject(i)
                val isEnabled = s.optBoolean("isEnabled", true)
                if (!isEnabled) continue

                val days = s.optJSONArray("days") ?: continue
                var hasToday = false
                for (d in 0 until days.length()) {
                    if (days.getString(d) == today) { hasToday = true; break }
                }
                if (!hasToday) continue

                val start    = toMins(s.optString("startTime", "00:00"))
                val end      = toMins(s.optString("endTime",   "00:00"))
                val isActive = if (end > start)
                    nowMins >= start && nowMins < end
                else
                    nowMins >= start || nowMins < end

                Log.d(TAG, "  '${s.optString("name")}' mode=${s.optString("mode")} start=$start end=$end active=$isActive")

                if (isActive) {
                    activeMode = s.optString("mode", "Silent")
                    Log.d(TAG, "Active schedule: ${s.optString("name")} mode=$activeMode")
                    break
                }
            }

            applyMode(context, activeMode ?: "Normal")

        } catch (e: Exception) {
            Log.e(TAG, "Error: ${e.message}")
        }
    }

    private fun applyMode(context: Context, mode: String) {
        val audio  = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val nm     = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val hasDND = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            nm.isNotificationPolicyAccessGranted else true

        try {
            when (mode) {
                // Pure silent — volume 0, no DND
                "Silent" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && hasDND) {
                        nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                    }
                    audio.ringerMode = AudioManager.RINGER_MODE_SILENT
                    audio.setStreamVolume(AudioManager.STREAM_RING, 0, 0)
                    audio.setStreamVolume(AudioManager.STREAM_NOTIFICATION, 0, 0)
                    audio.setStreamVolume(AudioManager.STREAM_SYSTEM, 0, 0)
                    Log.d(TAG, "Applied: Silent (volume 0)")
                }
                // Full DND
                "DND" -> {
                    if (hasDND && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
                    } else {
                        audio.ringerMode = AudioManager.RINGER_MODE_SILENT
                    }
                    Log.d(TAG, "Applied: DND")
                }
                // Vibrate only
                "Vibrate" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && hasDND) {
                        nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                    }
                    audio.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                    Log.d(TAG, "Applied: Vibrate")
                }
                // Normal
                else -> {
                    if (hasDND && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                        nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                    audio.ringerMode = AudioManager.RINGER_MODE_NORMAL
                    Log.d(TAG, "Applied: Normal")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "applyMode failed: ${e.message}")
        }
    }

    private fun toMins(time: String): Int {
        val parts = time.split(":")
        return parts[0].toInt() * 60 + parts[1].toInt()
    }

    private fun dayAbbr(dow: Int) = when (dow) {
        Calendar.MONDAY    -> "Mon"
        Calendar.TUESDAY   -> "Tue"
        Calendar.WEDNESDAY -> "Wed"
        Calendar.THURSDAY  -> "Thu"
        Calendar.FRIDAY    -> "Fri"
        Calendar.SATURDAY  -> "Sat"
        Calendar.SUNDAY    -> "Sun"
        else               -> ""
    }
}
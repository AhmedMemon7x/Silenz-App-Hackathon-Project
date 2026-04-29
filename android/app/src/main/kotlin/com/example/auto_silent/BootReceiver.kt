package com.example.auto_silent

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("AutoSilence", "Boot — rescheduling alarm")
        MainActivity.scheduleRepeatingAlarm(context)
    }
}
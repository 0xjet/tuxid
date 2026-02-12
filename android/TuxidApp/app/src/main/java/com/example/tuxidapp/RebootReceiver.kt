package com.example.tuxidapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class RebootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Reset the execution flag when the device is rebooted
            RebootPreferences.setFunctionExecuted(context, false)
        }
    }
}
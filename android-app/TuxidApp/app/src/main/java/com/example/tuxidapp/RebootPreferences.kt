package com.example.tuxidapp

import android.content.Context

object RebootPreferences {
    // Only one execution per boot (SharedPreferences key)
    private const val PREFS_NAME = "AppPrefs"
    private const val KEY_HAS_EXECUTED = "hasExecuted"

    // Check if the function has been executed
    fun hasFunctionExecuted(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_HAS_EXECUTED, false)
    }

    // Set the function execution flag
    fun setFunctionExecuted(context: Context, executed: Boolean) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(KEY_HAS_EXECUTED, executed).apply()
    }
}
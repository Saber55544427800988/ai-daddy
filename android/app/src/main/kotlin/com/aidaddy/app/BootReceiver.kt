package com.aidaddy.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BootReceiver â€?reschedules ALL saved reminders after device reboot.
 *
 * Android clears all AlarmManager alarms on reboot. This receiver:
 *   1. Loads all saved reminders from native SharedPreferences
 *   2. Reschedules each using AlarmManager.setExactAndAllowWhileIdle()
 *   3. Handles expired daily reminders by scheduling next occurrence
 *   4. Cleans up expired one-shot reminders
 *
 * Triggers on:
 *   - BOOT_COMPLETED (standard Android boot)
 *   - QUICKBOOT_POWERON (HTC/some OEMs fast boot)
 *   - MY_PACKAGE_REPLACED (app update)
 *   - LOCKED_BOOT_COMPLETED (direct boot on encrypted devices)
 *
 * Requires: android.permission.RECEIVE_BOOT_COMPLETED
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "AIDaddyBoot"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: "unknown"
        Log.d(TAG, "=== BOOT/UPDATE RECEIVED: $action ===")

        when (action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED -> {
                rescheduleAllReminders(context)
            }
            else -> {
                Log.w(TAG, "Unexpected action: $action")
                // Still try to reschedule â€?better safe than sorry
                rescheduleAllReminders(context)
            }
        }
    }

    private fun rescheduleAllReminders(context: Context) {
        try {
            // Ensure bubble channel exists (needed for notifications)
            BubbleNotificationHelper.createBubbleChannel(context.applicationContext)

            // Reschedule all saved reminders
            ReminderScheduler.rescheduleAll(context.applicationContext)

            val count = ReminderScheduler.getPendingCount(context.applicationContext)
            Log.d(TAG, "Boot reschedule complete. $count reminders active.")
        } catch (e: Exception) {
            Log.e(TAG, "Boot reschedule FAILED: ${e.message}")
        }
    }
}

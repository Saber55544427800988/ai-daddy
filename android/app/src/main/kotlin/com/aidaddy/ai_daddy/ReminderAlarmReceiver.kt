package com.aidaddy.ai_daddy

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * ReminderAlarmReceiver — fires when AlarmManager triggers a scheduled reminder.
 *
 * This runs 100% in native Android. No Flutter engine required.
 * Shows notification directly via BubbleNotificationHelper.
 *
 * Architecture:
 *   AlarmManager → ReminderAlarmReceiver.onReceive() → BubbleNotificationHelper.showBubble()
 *
 * For daily repeating reminders, reschedules the next occurrence automatically.
 */
class ReminderAlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "AIDaddyAlarm"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "=== ALARM RECEIVED ===")

        val requestCode = intent.getIntExtra("requestCode", -1)
        val title = intent.getStringExtra("title") ?: "AI Daddy 💙"
        val body = intent.getStringExtra("body") ?: "Hey! You have a reminder 💙"
        val priority = intent.getStringExtra("priority") ?: "high"
        val repeatPolicy = intent.getStringExtra("repeatPolicy") ?: "none"
        val triggerTimeMs = intent.getLongExtra("triggerTimeMs", 0L)

        Log.d(TAG, "Alarm fired: id=$requestCode body='$body' priority=$priority repeat=$repeatPolicy")

        // Show notification via the bubble system (with full fallback chain)
        try {
            BubbleNotificationHelper.showBubble(
                context.applicationContext,
                requestCode,
                title,
                body,
                priority
            )
            Log.d(TAG, "Notification shown for id=$requestCode")
        } catch (e: Exception) {
            Log.e(TAG, "Show notification FAILED: ${e.message}")
            // Direct fallback — create bare notification
            try {
                BubbleNotificationHelper.showBasicFallbackPublic(
                    context.applicationContext, requestCode, title, body
                )
            } catch (e2: Exception) {
                Log.e(TAG, "Even basic fallback FAILED: ${e2.message}")
            }
        }

        // Handle repeat policy
        if (repeatPolicy == "daily" && triggerTimeMs > 0) {
            val nextTrigger = triggerTimeMs + (24 * 60 * 60 * 1000L) // +24 hours
            Log.d(TAG, "Rescheduling daily alarm id=$requestCode for next day")
            ReminderScheduler.schedule(
                context.applicationContext,
                requestCode,
                title,
                body,
                nextTrigger,
                priority,
                "daily"
            )
        } else {
            // One-shot — remove from persistence
            ReminderScheduler.removeReminder(context.applicationContext, requestCode)
            Log.d(TAG, "One-shot alarm cleaned up: id=$requestCode")
        }
    }
}

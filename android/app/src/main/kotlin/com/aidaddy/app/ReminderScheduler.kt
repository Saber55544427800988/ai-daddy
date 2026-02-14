package com.aidaddy.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import org.json.JSONObject

/**
 * ReminderScheduler �?the core of the universal reminder engine.
 *
 * Architecture:
 *   - Uses AlarmManager.setExactAndAllowWhileIdle() with RTC_WAKEUP
 *   - Persists ALL reminders to SharedPreferences BEFORE scheduling
 *   - Each reminder has unique requestCode, message, triggerTime, priority
 *   - On boot: BootReceiver reads saved reminders and reschedules all
 *   - On alarm fire: ReminderAlarmReceiver shows notification natively
 *
 * This runs 100% in native Android �?no Flutter engine needed for alarm delivery.
 */
object ReminderScheduler {

    private const val TAG = "AIDaddyScheduler"
    private const val PREFS_NAME = "ai_daddy_native_reminders"
    private const val KEY_REMINDERS = "scheduled_reminders"

    // ────────────────────────────────────────────────────────────────────────
    // Schedule a reminder
    // ────────────────────────────────────────────────────────────────────────

    /**
     * Schedule a reminder with the most reliable method available.
     *
     * @param context       Application context
     * @param requestCode   Unique ID for this reminder
     * @param title         Notification title
     * @param body          Notification body text
     * @param triggerTimeMs Absolute trigger time in millis (System.currentTimeMillis based)
     * @param priority      "low", "medium", "high"
     * @param repeatPolicy  "none", "daily", "weekly" (for daily, we reschedule after fire)
     */
    fun schedule(
        context: Context,
        requestCode: Int,
        title: String,
        body: String,
        triggerTimeMs: Long,
        priority: String = "high",
        repeatPolicy: String = "none"
    ): Boolean {
        // 1. Save to persistent storage FIRST (survives reboot/kill)
        saveReminder(context, requestCode, title, body, triggerTimeMs, priority, repeatPolicy)

        // 2. Schedule with AlarmManager
        return scheduleAlarm(context, requestCode, title, body, triggerTimeMs, priority, repeatPolicy)
    }

    /**
     * Schedule the actual AlarmManager alarm.
     */
    private fun scheduleAlarm(
        context: Context,
        requestCode: Int,
        title: String,
        body: String,
        triggerTimeMs: Long,
        priority: String,
        repeatPolicy: String
    ): Boolean {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            val intent = Intent(context, ReminderAlarmReceiver::class.java).apply {
                action = "com.aidaddy.REMINDER_ALARM"
                putExtra("requestCode", requestCode)
                putExtra("title", title)
                putExtra("body", body)
                putExtra("priority", priority)
                putExtra("repeatPolicy", repeatPolicy)
                putExtra("triggerTimeMs", triggerTimeMs)
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Check if we can schedule exact alarms (Android 12+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerTimeMs,
                        pendingIntent
                    )
                    Log.d(TAG, "Exact alarm scheduled: id=$requestCode time=$triggerTimeMs")
                } else {
                    // Fallback: inexact but still wakes from Doze
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerTimeMs,
                        pendingIntent
                    )
                    Log.w(TAG, "Exact alarm NOT permitted, using inexact: id=$requestCode")
                }
            } else {
                // Pre-Android 12: always allowed
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTimeMs,
                    pendingIntent
                )
                Log.d(TAG, "Exact alarm scheduled (pre-S): id=$requestCode time=$triggerTimeMs")
            }

            return true
        } catch (e: Exception) {
            Log.e(TAG, "Schedule FAILED id=$requestCode: ${e.message}")

            // Last resort fallback
            try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val intent = Intent(context, ReminderAlarmReceiver::class.java).apply {
                    action = "com.aidaddy.REMINDER_ALARM"
                    putExtra("requestCode", requestCode)
                    putExtra("title", title)
                    putExtra("body", body)
                    putExtra("priority", priority)
                    putExtra("repeatPolicy", repeatPolicy)
                    putExtra("triggerTimeMs", triggerTimeMs)
                }
                val pi = PendingIntent.getBroadcast(
                    context, requestCode, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTimeMs, pi)
                Log.d(TAG, "Fallback alarm scheduled: id=$requestCode")
                return true
            } catch (e2: Exception) {
                Log.e(TAG, "Even fallback schedule FAILED: ${e2.message}")
                return false
            }
        }
    }

    // ────────────────────────────────────────────────────────────────────────
    // Cancel a reminder
    // ────────────────────────────────────────────────────────────────────────

    fun cancel(context: Context, requestCode: Int) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, ReminderAlarmReceiver::class.java).apply {
                action = "com.aidaddy.REMINDER_ALARM"
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
            removeReminder(context, requestCode)
            Log.d(TAG, "Alarm cancelled: id=$requestCode")
        } catch (e: Exception) {
            Log.e(TAG, "Cancel error: ${e.message}")
        }
    }

    fun cancelAll(context: Context) {
        val reminders = getAllReminders(context)
        for (id in reminders.keys) {
            try {
                cancel(context, id.toInt())
            } catch (_: Exception) {}
        }
        clearAllReminders(context)
        Log.d(TAG, "All alarms cancelled")
    }

    // ────────────────────────────────────────────────────────────────────────
    // Persistence �?SharedPreferences (survives reboot)
    // ────────────────────────────────────────────────────────────────────────

    private fun saveReminder(
        context: Context,
        requestCode: Int,
        title: String,
        body: String,
        triggerTimeMs: Long,
        priority: String,
        repeatPolicy: String
    ) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val json = prefs.getString(KEY_REMINDERS, "{}") ?: "{}"
            val map = JSONObject(json)

            val reminder = JSONObject().apply {
                put("id", requestCode)
                put("title", title)
                put("body", body)
                put("triggerTimeMs", triggerTimeMs)
                put("priority", priority)
                put("repeatPolicy", repeatPolicy)
                put("scheduledAt", System.currentTimeMillis())
            }

            map.put(requestCode.toString(), reminder)
            prefs.edit().putString(KEY_REMINDERS, map.toString()).apply()
            Log.d(TAG, "Reminder saved: id=$requestCode")
        } catch (e: Exception) {
            Log.e(TAG, "Save error: ${e.message}")
        }
    }

    fun removeReminder(context: Context, requestCode: Int) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val json = prefs.getString(KEY_REMINDERS, "{}") ?: "{}"
            val map = JSONObject(json)
            map.remove(requestCode.toString())
            prefs.edit().putString(KEY_REMINDERS, map.toString()).apply()
        } catch (_: Exception) {}
    }

    private fun clearAllReminders(context: Context) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putString(KEY_REMINDERS, "{}").apply()
        } catch (_: Exception) {}
    }

    /**
     * Get all saved reminders as Map<String, JSONObject>
     */
    fun getAllReminders(context: Context): Map<String, JSONObject> {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val json = prefs.getString(KEY_REMINDERS, "{}") ?: "{}"
            val map = JSONObject(json)
            val result = mutableMapOf<String, JSONObject>()
            val keys = map.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                result[key] = map.getJSONObject(key)
            }
            return result
        } catch (e: Exception) {
            Log.e(TAG, "getAllReminders error: ${e.message}")
            return emptyMap()
        }
    }

    // ────────────────────────────────────────────────────────────────────────
    // Reschedule all saved reminders (called by BootReceiver)
    // ────────────────────────────────────────────────────────────────────────

    fun rescheduleAll(context: Context) {
        val reminders = getAllReminders(context)
        val now = System.currentTimeMillis()
        var rescheduled = 0
        var expired = 0

        for ((_, reminder) in reminders) {
            try {
                val id = reminder.getInt("id")
                val title = reminder.getString("title")
                val body = reminder.getString("body")
                val triggerTimeMs = reminder.getLong("triggerTimeMs")
                val priority = reminder.optString("priority", "high")
                val repeatPolicy = reminder.optString("repeatPolicy", "none")

                if (triggerTimeMs > now) {
                    // Future reminder �?reschedule
                    scheduleAlarm(context, id, title, body, triggerTimeMs, priority, repeatPolicy)
                    rescheduled++
                } else if (repeatPolicy == "daily") {
                    // Expired daily reminder �?reschedule for next occurrence
                    var nextTrigger = triggerTimeMs
                    val dayMs = 24 * 60 * 60 * 1000L
                    while (nextTrigger <= now) {
                        nextTrigger += dayMs
                    }
                    saveReminder(context, id, title, body, nextTrigger, priority, repeatPolicy)
                    scheduleAlarm(context, id, title, body, nextTrigger, priority, repeatPolicy)
                    rescheduled++
                } else {
                    // Expired one-shot �?clean up
                    removeReminder(context, id)
                    expired++
                }
            } catch (e: Exception) {
                Log.e(TAG, "Reschedule error: ${e.message}")
            }
        }

        Log.d(TAG, "Reschedule complete: $rescheduled rescheduled, $expired expired")
    }

    // ────────────────────────────────────────────────────────────────────────
    // Diagnostic �?check if exact alarms are permitted
    // ────────────────────────────────────────────────────────────────────────

    fun canScheduleExactAlarms(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        return try {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.canScheduleExactAlarms()
        } catch (_: Exception) {
            false
        }
    }

    fun getPendingCount(context: Context): Int {
        return getAllReminders(context).size
    }
}

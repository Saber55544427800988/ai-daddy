package com.aidaddy.ai_daddy

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.aidaddy.ai_daddy/bubble"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize bubble channel + notification channels on startup
        BubbleNotificationHelper.createBubbleChannel(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {

                // ── Bubble Notifications ─────────────────────────────────

                "showBubble" -> {
                    val notifId = call.argument<Int>("id") ?: 0
                    val title = call.argument<String>("title") ?: "AI Daddy 💙"
                    val body = call.argument<String>("body") ?: ""
                    val priority = call.argument<String>("priority") ?: "high"

                    BubbleNotificationHelper.showBubble(
                        applicationContext, notifId, title, body, priority
                    )
                    result.success(true)
                }
                "cancelBubble" -> {
                    val notifId = call.argument<Int>("id") ?: 0
                    BubbleNotificationHelper.cancelBubble(applicationContext, notifId)
                    result.success(true)
                }
                "areBubblesSupported" -> {
                    result.success(BubbleNotificationHelper.areBubblesSupported(applicationContext))
                }
                "createBubbleChannel" -> {
                    BubbleNotificationHelper.createBubbleChannel(applicationContext)
                    result.success(true)
                }

                // ── Native Reminder Scheduling (AlarmManager) ────────────

                "scheduleNativeReminder" -> {
                    val requestCode = call.argument<Int>("requestCode") ?: 0
                    val title = call.argument<String>("title") ?: "AI Daddy 💙"
                    val body = call.argument<String>("body") ?: ""
                    val triggerTimeMs = call.argument<Number>("triggerTimeMs")?.toLong() ?: 0L
                    val priority = call.argument<String>("priority") ?: "high"
                    val repeatPolicy = call.argument<String>("repeatPolicy") ?: "none"

                    val ok = ReminderScheduler.schedule(
                        applicationContext, requestCode, title, body,
                        triggerTimeMs, priority, repeatPolicy
                    )
                    result.success(ok)
                }
                "cancelNativeReminder" -> {
                    val requestCode = call.argument<Int>("requestCode") ?: 0
                    ReminderScheduler.cancel(applicationContext, requestCode)
                    result.success(true)
                }
                "cancelAllNativeReminders" -> {
                    ReminderScheduler.cancelAll(applicationContext)
                    result.success(true)
                }
                "getPendingReminderCount" -> {
                    result.success(ReminderScheduler.getPendingCount(applicationContext))
                }
                "canScheduleExactAlarms" -> {
                    result.success(true) // No longer needed, always return true
                }
                "openExactAlarmSettings" -> {
                    result.success(true) // No-op, exact alarms removed
                }

                // ── Device / Battery ─────────────────────────────────────

                "requestBatteryOptimization" -> {
                    try {
                        val pm = getSystemService(android.content.Context.POWER_SERVICE) as android.os.PowerManager
                        if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                            val intent = android.content.Intent(
                                android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                android.net.Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "isBatteryOptimized" -> {
                    try {
                        val pm = getSystemService(android.content.Context.POWER_SERVICE) as android.os.PowerManager
                        result.success(!pm.isIgnoringBatteryOptimizations(packageName))
                    } catch (e: Exception) {
                        result.success(true) // Assume optimized if we can't check
                    }
                }
                "getDeviceManufacturer" -> {
                    result.success(Build.MANUFACTURER)
                }

                // ── Test / Diagnostic ────────────────────────────────────

                "scheduleTestReminder" -> {
                    // Schedule a reminder 60 seconds from now for testing
                    val testTime = System.currentTimeMillis() + 60_000L
                    val ok = ReminderScheduler.schedule(
                        applicationContext,
                        99999,
                        "AI Daddy Test 🧪",
                        "Test reminder fired! Notifications work on your device ✅",
                        testTime,
                        "high",
                        "none"
                    )
                    result.success(ok)
                }

                else -> result.notImplemented()
            }
        }
    }
}

package com.aidaddy.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Person
import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat

/**
 * BubbleNotificationHelper â€?creates Android 11+ bubble notifications
 * that look and behave like Messenger chat heads.
 *
 * On devices that don't support bubbles (< Android 11), falls back to
 * high-priority heads-up MessagingStyle notifications.
 */
object BubbleNotificationHelper {

    private const val TAG = "AIDaddyBubble"
    private const val CHANNEL_ID = "ai_daddy_bubbles_v1"
    private const val CHANNEL_NAME = "AI Daddy Bubbles"
    private const val CHANNEL_DESC = "Chat bubble notifications from AI Daddy"
    private const val SHORTCUT_ID = "ai_daddy_chat"

    /**
     * Initialize the bubble notification channel.
     * Must be called once (typically from Flutter init).
     */
    fun createBubbleChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Delete old bubble channels if they exist
        try {
            nm.deleteNotificationChannel("ai_daddy_bubbles")
        } catch (_: Exception) {}

        val soundUri = Uri.parse("android.resource://${context.packageName}/raw/daddy_sound")
        val audioAttrs = AudioAttributes.Builder()
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .build()

        val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_HIGH).apply {
            description = CHANNEL_DESC
            setSound(soundUri, audioAttrs)
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 200, 100, 200)
            setShowBadge(true)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                setAllowBubbles(true)
            }
        }

        nm.createNotificationChannel(channel)
        Log.d(TAG, "Bubble channel created: $CHANNEL_ID")
    }

    /**
     * Publish a dynamic shortcut for bubble support.
     * Android 11+ requires a valid shortcut to associate with bubble metadata.
     */
    private fun publishShortcut(context: Context) {
        try {
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
            }

            val shortcut = ShortcutInfoCompat.Builder(context, SHORTCUT_ID)
                .setShortLabel("AI Daddy")
                .setLongLabel("Chat with AI Daddy")
                .setIcon(IconCompat.createWithResource(context, R.mipmap.ic_launcher))
                .setIntent(intent)
                .setLongLived(true)
                .setCategories(setOf("com.android.voicemail.SHARE_TARGET"))
                .build()

            ShortcutManagerCompat.pushDynamicShortcut(context, shortcut)
            Log.d(TAG, "Shortcut published: $SHORTCUT_ID")
        } catch (e: Exception) {
            Log.e(TAG, "Shortcut error: ${e.message}")
        }
    }

    /**
     * Show a bubble notification.
     *
     * @param context Application context
     * @param notifId Unique notification ID
     * @param title Notification title (e.g. "AI Daddy ðŸ’™")
     * @param body Message body
     * @param priority "low", "medium", or "high"
     */
    fun showBubble(
        context: Context,
        notifId: Int,
        title: String,
        body: String,
        priority: String = "high"
    ) {
        try {
            createBubbleChannel(context)
            publishShortcut(context)

            // Intent for when bubble/notification is tapped
            val tapIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val tapPending = PendingIntent.getActivity(
                context, notifId, tapIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )

            // Determine notification priority
            val notifPriority = when (priority) {
                "low" -> NotificationCompat.PRIORITY_DEFAULT
                "medium" -> NotificationCompat.PRIORITY_HIGH
                else -> NotificationCompat.PRIORITY_MAX
            }

            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setContentIntent(tapPending)
                .setPriority(notifPriority)
                .setCategory(NotificationCompat.CATEGORY_MESSAGE)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setAutoCancel(true)
                .setColor(0xFF00BFFF.toInt())

            // MessagingStyle for chat-like appearance
            val person = androidx.core.app.Person.Builder()
                .setName("AI Daddy ðŸ’™")
                .setImportant(true)
                .setIcon(IconCompat.createWithResource(context, R.mipmap.ic_launcher))
                .build()

            val messagingStyle = NotificationCompat.MessagingStyle(person)
                .setConversationTitle("AI Daddy")
                .addMessage(body, System.currentTimeMillis(), person)

            builder.setStyle(messagingStyle)

            // === BUBBLE METADATA (Android 11+) ===
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                try {
                    val bubbleIntent = Intent(context, BubbleActivity::class.java).apply {
                        action = Intent.ACTION_VIEW
                    }
                    val bubblePending = PendingIntent.getActivity(
                        context, notifId + 10000, bubbleIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                    )

                    val bubbleMetadata = NotificationCompat.BubbleMetadata.Builder(
                        bubblePending,
                        IconCompat.createWithResource(context, R.mipmap.ic_launcher)
                    )
                        .setDesiredHeight(600)
                        .setAutoExpandBubble(priority == "high")
                        .setSuppressNotification(false)
                        .build()

                    builder.setBubbleMetadata(bubbleMetadata)
                    builder.setShortcutId(SHORTCUT_ID)

                    Log.d(TAG, "Bubble metadata set for id=$notifId")
                } catch (e: Exception) {
                    Log.e(TAG, "Bubble metadata error (falling back to heads-up): ${e.message}")
                }
            }

            // Show the notification
            val nm = NotificationManagerCompat.from(context)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                // Check POST_NOTIFICATIONS permission on Android 13+
                if (context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)
                    == android.content.pm.PackageManager.PERMISSION_GRANTED
                ) {
                    nm.notify(notifId, builder.build())
                    Log.d(TAG, "Bubble notification shown id=$notifId")
                } else {
                    Log.w(TAG, "POST_NOTIFICATIONS permission not granted")
                    // Still try â€?some ROMs allow it
                    try { nm.notify(notifId, builder.build()) } catch (_: Exception) {}
                }
            } else {
                nm.notify(notifId, builder.build())
                Log.d(TAG, "Bubble notification shown id=$notifId")
            }

        } catch (e: Exception) {
            Log.e(TAG, "showBubble FAILED: ${e.message}")
            // Ultimate fallback â€?basic notification via NotificationManager
            showBasicFallback(context, notifId, title, body)
        }
    }

    /**
     * Cancel a specific bubble notification.
     */
    fun cancelBubble(context: Context, notifId: Int) {
        try {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(notifId)
        } catch (e: Exception) {
            Log.e(TAG, "Cancel error: ${e.message}")
        }
    }

    /**
     * Check if the device supports bubble notifications.
     */
    fun areBubblesSupported(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return false
        try {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            return nm.areBubblesAllowed()
        } catch (_: Exception) {
            return false
        }
    }

    /**
     * Basic fallback notification when everything else fails.
     * Used internally and by ReminderAlarmReceiver.
     */
    private fun showBasicFallback(context: Context, notifId: Int, title: String, body: String) {
        showBasicFallbackPublic(context, notifId, title, body)
    }

    /**
     * Public basic fallback â€?called by ReminderAlarmReceiver when bubble fails.
     */
    fun showBasicFallbackPublic(context: Context, notifId: Int, title: String, body: String) {
        try {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val fallbackChannel = NotificationChannel(
                    "ai_daddy_fallback",
                    "AI Daddy Fallback",
                    NotificationManager.IMPORTANCE_HIGH
                )
                nm.createNotificationChannel(fallbackChannel)
            }

            val notif = NotificationCompat.Builder(context, "ai_daddy_fallback")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .build()

            nm.notify(notifId, notif)
            Log.d(TAG, "Fallback notification shown id=$notifId")
        } catch (e: Exception) {
            Log.e(TAG, "Even fallback FAILED: ${e.message}")
        }
    }
}

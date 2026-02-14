# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep annotations
-keepattributes *Annotation*

# Keep SQFlite
-keep class com.tekartik.sqflite.** { *; }

# Keep Flutter Local Notifications
-keep class com.dexterous.** { *; }

# Keep HTTP
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**

# Keep Google Fonts
-keep class com.google.** { *; }
-dontwarn com.google.**

# Keep Android Alarm Manager Plus
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }

# Keep WorkManager
-keep class androidx.work.** { *; }

# Keep AndroidX Core for bubble notifications
-keep class androidx.core.app.** { *; }
-keep class androidx.core.content.pm.** { *; }
-keep class androidx.core.graphics.drawable.** { *; }

# Keep Bubble classes
-keep class com.aidaddy.app.BubbleNotificationHelper { *; }
-keep class com.aidaddy.app.BubbleActivity { *; }

# Keep Native Reminder classes (alarm scheduling, boot recovery)
-keep class com.aidaddy.app.ReminderScheduler { *; }
-keep class com.aidaddy.app.ReminderAlarmReceiver { *; }
-keep class com.aidaddy.app.BootReceiver { *; }

# Prevent R8 from removing needed classes
-keep class **.R$* { *; }
-keepclassmembers class * { @android.webkit.JavascriptInterface <methods>; }

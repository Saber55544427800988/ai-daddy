package com.aidaddy.ai_daddy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.aidaddy.ai_daddy/bubble"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize bubble channel on startup
        BubbleNotificationHelper.createBubbleChannel(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
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
                else -> result.notImplemented()
            }
        }
    }
}

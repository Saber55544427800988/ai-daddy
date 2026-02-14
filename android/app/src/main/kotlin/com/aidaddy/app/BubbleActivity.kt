package com.aidaddy.app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * BubbleActivity â€?launched when the user taps an expanded bubble.
 * This is a lightweight FlutterActivity that opens the main AI Daddy chat.
 * 
 * Required attributes in AndroidManifest:
 *   android:allowEmbedded="true"
 *   android:resizeableActivity="true"
 *   android:documentLaunchMode="always"
 */
class BubbleActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // The bubble will open to the Flutter chat screen
        // Flutter routing can be handled via the intent extras if needed
    }
}

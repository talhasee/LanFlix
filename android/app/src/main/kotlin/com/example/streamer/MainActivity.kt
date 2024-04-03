package com.example.streamer

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.videostreamer"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "streamVideo") {
                val videoPath = call.argument<String>("videoPath")
                // Invoke the Java application here
                // You might need to use a different approach to run the Java application from Android
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}

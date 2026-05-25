package com.studycompanion.study_companion

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Prevent screenshots and screen recording on all screens (login, quiz, AI content).
        // Remove this flag only if screen sharing is explicitly needed as a feature.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}

package com.grullondev.personal_finance

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Prevent the OS from capturing financial content in the app switcher
        // screenshot and from appearing in screen recordings / screenshots.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}

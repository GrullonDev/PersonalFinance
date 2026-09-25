package com.grullondev.personal_finance

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import androidx.core.app.NotificationManagerCompat
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val paymentCaptureChannel = "personal_finance/payment_capture"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Handle the splash screen transition.
        installSplashScreen()

        super.onCreate(savedInstanceState)

        // Bloquear capturas de pantalla a nivel del sistema operativo
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Registro automático de pagos leídos de notificaciones.
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, paymentCaptureChannel)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "drainPending" -> result.success(PaymentCaptureStore.drain(applicationContext))
                "isAccessGranted" -> result.success(
                    NotificationManagerCompat.getEnabledListenerPackages(this).contains(packageName)
                )
                "openAccessSettings" -> {
                    startActivity(
                        Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        PaymentCaptureStore.onCaptured = { channel.invokeMethod("onPaymentCaptured", null) }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        PaymentCaptureStore.onCaptured = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}

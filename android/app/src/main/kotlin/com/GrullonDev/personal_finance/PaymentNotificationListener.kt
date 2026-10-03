package com.grullondev.personal_finance

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONObject

/**
 * Lee las notificaciones de pagos (Google Wallet, Google Pay, Samsung Wallet,
 * apps de bancos y SMS bancarios) y encola sólo las que parecen un movimiento
 * de dinero. La interpretación final (gasto/ingreso, comercio, categoría) se
 * hace en Dart; aquí sólo se filtra para no guardar notificaciones ajenas.
 *
 * El usuario debe conceder el acceso en Ajustes > Acceso a notificaciones.
 */
class PaymentNotificationListener : NotificationListenerService() {

    companion object {
        private val WALLET_PACKAGES = setOf(
            "com.google.android.apps.walletnfcrel",
            "com.google.android.apps.nbu.paisa.user",
            "com.samsung.android.spay",
        )

        // Apps de chat: un "te pago 50" en una conversación no es un pago.
        private val IGNORED_PACKAGES = setOf(
            "com.whatsapp",
            "com.whatsapp.w4b",
            "org.telegram.messenger",
            "com.facebook.orca",
            "com.instagram.android",
            "com.google.android.gm",
            "com.discord",
            "com.snapchat.android",
        )

        private val MONEY_KEYWORDS = listOf(
            "pagaste", "has pagado", "pago", "compra", "consumo", "cargo",
            "débito", "debito", "retiro", "transferencia", "enviaste",
            "recibiste", "has recibido", "te envi", "depósito", "deposito",
            "acreditado", "acreditamos", "abonamos", "reembolso", "devolución",
            "devolucion", "paid", "purchase", "payment", "spent", "received",
            "refund", "deposit",
        )

        private val AMOUNT = Regex(
            """(?<![A-Za-z])(GTQ|USD|MXN|EUR|COP|PEN|CLP|ARS|HNL|CRC|DOP|US\$|Q|\$|€|£|₡|S/)\s?\d|\d[\d.,]*\s?(GTQ|USD|MXN|EUR|quetzales|dólares|dolares)""",
            RegexOption.IGNORE_CASE,
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        val notification = sbn ?: return
        val pkg = notification.packageName ?: return
        if (pkg == packageName || pkg in IGNORED_PACKAGES) return
        if ((notification.notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0) return

        val extras = notification.notification.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString().orEmpty()
        if (title.isBlank() && text.isBlank()) return

        val full = "$title $text"
        if (!AMOUNT.containsMatchIn(full)) return
        val lower = full.lowercase()
        val isWallet = pkg in WALLET_PACKAGES
        if (!isWallet && MONEY_KEYWORDS.none { lower.contains(it) }) return

        val capture = JSONObject()
            .put("source", "notification")
            .put("packageName", pkg)
            .put("title", title)
            .put("text", text)
            .put("postedAt", notification.postTime)

        try {
            PaymentCaptureStore.enqueue(applicationContext, capture)
        } catch (e: Exception) {
            // Nunca romper el listener por una notificación mal formada.
        }
    }
}

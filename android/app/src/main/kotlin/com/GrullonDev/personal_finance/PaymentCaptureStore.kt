package com.grullondev.personal_finance

import android.content.Context
import android.os.Handler
import android.os.Looper
import org.json.JSONArray
import org.json.JSONObject

/**
 * Cola persistente de pagos detectados. El listener de notificaciones puede
 * ejecutarse sin que Flutter esté activo, así que las capturas se guardan
 * aquí hasta que la app las lee con `drainPending`.
 */
object PaymentCaptureStore {
    private const val PREFS = "payment_capture"
    private const val KEY_QUEUE = "queue"
    private const val KEY_RECENT = "recent"
    private const val MAX_QUEUE = 100
    private const val DUPLICATE_WINDOW_MS = 10 * 60 * 1000L

    /** Lo asigna MainActivity mientras Flutter está vivo. */
    @Volatile
    var onCaptured: (() -> Unit)? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    @Synchronized
    fun enqueue(context: Context, capture: JSONObject) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()

        // Las apps suelen actualizar la misma notificación: evita duplicados.
        val signature = "${capture.optString("packageName")}|${capture.optString("title")}|${capture.optString("text")}"
        val recent = JSONObject(prefs.getString(KEY_RECENT, "{}") ?: "{}")
        val lastSeen = recent.optLong(signature, 0L)
        if (now - lastSeen < DUPLICATE_WINDOW_MS) return
        recent.put(signature, now)
        val keys = recent.keys().asSequence().toList()
        for (key in keys) {
            if (now - recent.optLong(key, 0L) > DUPLICATE_WINDOW_MS) recent.remove(key)
        }

        val queue = JSONArray(prefs.getString(KEY_QUEUE, "[]") ?: "[]")
        queue.put(capture)
        while (queue.length() > MAX_QUEUE) queue.remove(0)

        prefs.edit()
            .putString(KEY_QUEUE, queue.toString())
            .putString(KEY_RECENT, recent.toString())
            .apply()

        onCaptured?.let { callback -> mainHandler.post { callback() } }
    }

    @Synchronized
    fun drain(context: Context): List<Map<String, Any?>> {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val queue = JSONArray(prefs.getString(KEY_QUEUE, "[]") ?: "[]")
        prefs.edit().putString(KEY_QUEUE, "[]").apply()

        val result = mutableListOf<Map<String, Any?>>()
        for (i in 0 until queue.length()) {
            val item = queue.optJSONObject(i) ?: continue
            result.add(
                mapOf(
                    "source" to item.optString("source", "notification"),
                    "packageName" to item.optString("packageName"),
                    "title" to item.optString("title"),
                    "text" to item.optString("text"),
                    "postedAt" to item.optLong("postedAt", System.currentTimeMillis()),
                )
            )
        }
        return result
    }
}

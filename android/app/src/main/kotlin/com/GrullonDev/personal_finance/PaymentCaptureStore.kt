package com.grullondev.personal_finance

import android.content.Context
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import com.google.firebase.auth.FirebaseAuth
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest

/**
 * Cola persistente de pagos detectados. El listener de notificaciones puede
 * ejecutarse sin que Flutter esté activo, así que las capturas se guardan
 * aquí hasta que la app confirma cada elemento.
 */
object PaymentCaptureStore {
    private const val PREFS = "payment_capture"
    private const val KEY_QUEUE = "queue"
    private const val KEY_RECENT = "recent"
    private const val RECENT_SIGNATURES = "recent_signatures"
    private const val REPOST_WINDOW_MS = 10 * 60 * 1000L
    private const val OWNER = "owner"

    @Volatile
    var onCaptured: (() -> Unit)? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun records(raw: String?): List<JSONObject> {
        val queue = JSONArray(raw ?: "[]")
        return (0 until queue.length()).mapNotNull { queue.optJSONObject(it) }
            .filter { it.optString("owner").isNotBlank() && it.optString("id").isNotBlank() }
    }

    private fun SharedPreferences.Editor.persist() {
        check(commit()) { "Could not persist payment capture data" }
    }

    private fun digest(vararg fields: Any): String {
        val data = JSONArray(fields.toList()).toString().toByteArray()
        return MessageDigest.getInstance("SHA-256").digest(data).joinToString("") { "%02x".format(it) }
    }

    @Synchronized
    fun setOwner(context: Context, owner: String?) {
        val prefs = prefs(context)
        prefs.edit().putString(OWNER, owner)
            .putString(KEY_QUEUE, JSONArray(records(prefs.getString(KEY_QUEUE, null))).toString())
            .remove(KEY_RECENT).persist()
    }

    @Synchronized
    fun setSources(context: Context, sources: List<String>) {
        val prefs = prefs(context)
        val owner = prefs.getString(OWNER, null) ?: return
        prefs.edit().putStringSet("sources:$owner", sources.toSet()).persist()
    }

    @Synchronized
    fun allowedOwner(context: Context, pkg: String): String? {
        val prefs = prefs(context)
        val owner = prefs.getString(OWNER, null) ?: return null
        return owner.takeIf { pkg in prefs.getStringSet("sources:$owner", emptySet()).orEmpty() &&
            FirebaseAuth.getInstance().currentUser?.uid == owner }
    }

    @Synchronized
    fun enqueue(context: Context, owner: String, notificationKey: String, capture: JSONObject) {
        val pkg = capture.getString("packageName")
        if (allowedOwner(context, pkg) != owner) return
        val prefs = prefs(context)
        val id = digest(owner, notificationKey, capture.getLong("postedAt"))
        val queue = records(prefs.getString(KEY_QUEUE, null))
        if (queue.any { it.optString("id") == id }) return
        val now = System.currentTimeMillis()
        val signatures = JSONObject(prefs.getString(RECENT_SIGNATURES, "{}") ?: "{}")
        signatures.keys().asSequence().toList().filter {
            now - signatures.optLong(it) >= REPOST_WINDOW_MS
        }.forEach { signatures.remove(it) }
        if (signatures.has(id)) return
        signatures.put(id, now)
        capture.put("id", id).put("owner", owner)
        prefs.edit().putString(KEY_QUEUE, JSONArray(queue + capture).toString())
            .putString(RECENT_SIGNATURES, signatures.toString()).persist()
        mainHandler.post { onCaptured?.invoke() }
    }

    @Synchronized
    fun peek(context: Context): List<Map<String, Any?>> {
        val prefs = prefs(context)
        val owner = prefs.getString(OWNER, null) ?: return emptyList()
        return records(prefs.getString(KEY_QUEUE, null))
            .filter { it.optString("owner") == owner }
            .map { item -> item.keys().asSequence().associateWith { item.get(it) } }
    }

    @Synchronized
    fun acknowledge(context: Context, id: String?) {
        val prefs = prefs(context)
        val owner = prefs.getString(OWNER, null) ?: return
        val retained = records(prefs.getString(KEY_QUEUE, null)).filterNot {
            it.optString("id") == id && it.optString("owner") == owner
        }
        prefs.edit().putString(KEY_QUEUE, JSONArray(retained).toString()).persist()
    }
}

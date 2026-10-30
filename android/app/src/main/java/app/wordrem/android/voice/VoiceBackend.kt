package app.wordrem.android.voice

import app.wordrem.android.BuildConfig
import app.wordrem.android.billing.Billing
import app.wordrem.android.data.Store
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.HttpUrl
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

/**
 * Sesli öğretmen sunucusu (server/voice-worker) istemcisi — iOS VoiceBackend ile aynı uç noktalar.
 * Adres ve uygulama anahtarı derleme sırasında iOS Info.plist'ten (ya da secrets.properties'ten) gelir.
 */
object VoiceBackend {
    data class Grant(val sessionId: String, val model: String, val allowedSeconds: Int, val tier: String)
    data class Status(val tier: String, val remainingSeconds: Int)

    /** code: "paywall" (ücretsiz süre bitti) · "limit_reached" · "too_many_new_users" · "not_configured" · "network" */
    class Failure(val code: String, val remainingSeconds: Int? = null) : Exception(code)

    private val base: HttpUrl = BuildConfig.VOICE_API_BASE_URL.toHttpUrl()
    private val appKey = BuildConfig.VOICE_APP_KEY
    private val json = "application/json".toMediaType()

    val http: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .pingInterval(20, TimeUnit.SECONDS)
        .build()

    val isConfigured get() = appKey.isNotEmpty()

    /** RevenueCat kullanıcı kimliği: sunucu Pro hakkını bununla RevenueCat'e sorar */
    val appUserId: String get() = Billing.appUserId ?: Store.localUserId

    private fun url(path: String, vararg query: Pair<String, String>): HttpUrl =
        base.newBuilder().addPathSegments(path).apply { query.forEach { addQueryParameter(it.first, it.second) } }.build()

    private fun request(url: HttpUrl) = Request.Builder().url(url).header("X-App-Key", appKey)

    /** engine: "gemini" (iOS'taki varsayılan) ya da "realtime" (Gemini açılmazsa) */
    suspend fun createSession(instructions: String, tools: JSONArray, quality: String, engine: String): Grant =
        withContext(Dispatchers.IO) {
            if (!isConfigured) throw Failure("not_configured")
            val body = JSONObject()
                .put("appUserId", appUserId).put("instructions", instructions).put("tools", tools)
                .put("speed", 1.0).put("quality", quality).put("metered", true)
                .put("deviceId", Store.deviceId).put("engine", engine)
            val req = request(url("v1/voice/session")).post(body.toString().toRequestBody(json)).build()
            val res = runCatching { http.newCall(req).execute() }.getOrElse { throw Failure("network") }
            res.use {
                val obj = runCatching { JSONObject(it.body?.string() ?: "{}") }.getOrDefault(JSONObject())
                if (it.code == 200) {
                    Grant(obj.getString("sessionId"), obj.optString("model"), obj.optInt("allowedSeconds"), obj.optString("tier"))
                } else {
                    throw Failure(obj.optString("error", "network"), if (obj.has("remainingSeconds")) obj.optInt("remainingSeconds") else null)
                }
            }
        }

    suspend fun status(): Status? = withContext(Dispatchers.IO) {
        if (!isConfigured) return@withContext null
        val req = request(url("v1/voice/status", "appUserId" to appUserId, "deviceId" to Store.deviceId)).get().build()
        runCatching {
            http.newCall(req).execute().use {
                val o = JSONObject(it.body!!.string())
                Status(o.optString("tier", "free"), o.optInt("remainingSeconds"))
            }
        }.getOrNull()
    }

    /** Öğrencinin sesini sunucu üzerinden yazıya çevirir (PCM 16 bit 24 kHz mono) */
    suspend fun transcribe(sessionId: String, pcm: ByteArray, language: String? = null): String = withContext(Dispatchers.IO) {
        if (pcm.size < 4800) return@withContext ""
        val q = mutableListOf("session" to sessionId, "appUserId" to appUserId)
        if (language != null) q += "lang" to language
        val req = request(url("v1/voice/cascade/stt", *q.toTypedArray()))
            .post(pcm.toRequestBody("application/octet-stream".toMediaType())).build()
        runCatching {
            http.newCall(req).execute().use { JSONObject(it.body!!.string()).optString("transcript") }
        }.getOrDefault("")
    }

    suspend fun reportUsage(sessionId: String, seconds: Int) = withContext(Dispatchers.IO) {
        val body = JSONObject().put("appUserId", appUserId).put("sessionId", sessionId).put("seconds", seconds)
        runCatching { http.newCall(request(url("v1/voice/usage")).post(body.toString().toRequestBody(json)).build()).execute().close() }
    }

    /** Sayaçlı WebSocket: anahtar sunucuda kalır, süreyi sunucu sayar (path: "v1/voice/gemini" | "v1/voice/realtime") */
    fun openSocket(path: String, sessionId: String, listener: WebSocketListener): WebSocket {
        val u = url(path, "session" to sessionId, "appUserId" to appUserId)
        return http.newWebSocket(request(u).build(), listener)
    }
}

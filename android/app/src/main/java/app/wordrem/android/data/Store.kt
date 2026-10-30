package app.wordrem.android.data

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.util.UUID

/** Tutor kartından ya da ders listesinden öğrenilen kelime/ifade (iOS LearnedWord ile aynı alanlar) */
data class LearnedWord(
    val id: String,
    val term: String,
    val meaning: String,
    val languageCode: String,   // büyük harf: "EN"
    val learnedAt: Long,
)

/**
 * Hesap yok (iOS gibi): her şey cihazda, SharedPreferences'ta tutulur ve Android yedeğiyle taşınır.
 * Compose ekranları `version` değiştiğinde yeniden çizilir.
 */
object Store {
    private lateinit var prefs: SharedPreferences

    /** Her yazmada artar; ekranlar bunu okuyarak güncel kalır */
    var version by mutableIntStateOf(0)
        private set

    var onboardingDone by mutableStateOf(false)
        private set
    var isPremium by mutableStateOf(false)

    fun init(context: Context) {
        if (::prefs.isInitialized) return
        prefs = context.getSharedPreferences("wordrem", Context.MODE_PRIVATE)
        onboardingDone = prefs.getBoolean("hasCompletedOnboarding", false)
        isPremium = prefs.getBoolean("isPremium", false)
        // İlk açılışta arayüz dili cihaz dilinden tahmin edilir (onboarding'de değiştirilebilir)
        if (prefs.getString("userNativeLangCode", null) == null) {
            val device = java.util.Locale.getDefault().language
            if (LANGS.any { it.code == device }) prefs.edit().putString("userNativeLangCode", device).apply()
        }
        if (prefs.getString("deviceId", null) == null) {
            prefs.edit().putString("deviceId", UUID.randomUUID().toString().uppercase()).apply()
        }
    }

    private fun bump() { version++ }

    // MARK: Kimlik
    /** Sunucunun ücretsiz süre sayacı için kalıcı cihaz kimliği (UUID biçimi şart) */
    val deviceId: String get() = prefs.getString("deviceId", "")!!
    /** RevenueCat yapılandırılmadıysa ses sunucusuna giden kullanıcı kimliği */
    val localUserId: String
        get() = prefs.getString("localUserId", null) ?: ("android-" + UUID.randomUUID()).also {
            prefs.edit().putString("localUserId", it).apply()
        }

    // MARK: Profil
    var nativeLang: String
        get() = prefs.getString("userNativeLangCode", "en")!!
        set(v) { prefs.edit().putString("userNativeLangCode", v.lowercase()).apply(); bump() }
    var targetLang: String
        get() = prefs.getString("selectedTargetLanguageCode", "en")!!.lowercase()
        set(v) { prefs.edit().putString("selectedTargetLanguageCode", v.lowercase()).apply(); bump() }
    var username: String
        get() = prefs.getString("username", "")!!
        set(v) { prefs.edit().putString("username", v.trim()).apply(); bump() }
    /** 0 başlangıç … 4 ileri; onboarding hep 1 yazar (iOS ile aynı) */
    var proficiency: Int
        get() = prefs.getInt("selectedProficiencyLevel", 1)
        set(v) { prefs.edit().putInt("selectedProficiencyLevel", v).apply(); bump() }

    fun completeOnboarding() {
        prefs.edit().putBoolean("hasCompletedOnboarding", true).apply()
        onboardingDone = true
        bump()
    }

    fun savePremium(active: Boolean) {
        isPremium = active
        prefs.edit().putBoolean("isPremium", active).apply()
    }

    var demoScenario: Int
        get() = prefs.getInt("demo.scenario", -1)
        set(v) { prefs.edit().putInt("demo.scenario", v).apply() }

    // MARK: Lupa'nın hafızası
    val tutorFacts: List<String> get() = stringList("tutorFacts")
    val tutorSummaries: List<String> get() = stringList("tutorSummaries")
    fun rememberFact(fact: String) {
        val f = tutorFacts.toMutableList()
        if (fact !in f) f += fact
        putStringList("tutorFacts", f.takeLast(30))
    }
    fun addSummary(summary: String) = putStringList("tutorSummaries", (tutorSummaries + summary).takeLast(10))

    // MARK: Ders planı (dil başına: "en:meet.greet")
    private val goalsDone: JSONObject get() = JSONObject(prefs.getString("voiceGoalsDone", "{}")!!)
    fun goalKey(goalId: String, lang: String = targetLang) = "$lang:$goalId"
    fun isGoalDone(goalId: String) = goalsDone.has(goalKey(goalId))
    val goalsDoneCount: Int get() = goalsDone.keys().asSequence().count { it.startsWith("$targetLang:") }
    fun markGoalDone(goalId: String) {
        val o = goalsDone
        if (!o.has(goalKey(goalId))) o.put(goalKey(goalId), System.currentTimeMillis())
        prefs.edit().putString("voiceGoalsDone", o.toString()).apply(); bump()
    }

    // MARK: Öğrenilen kelimeler
    val learnedWords: List<LearnedWord>
        get() {
            val arr = JSONArray(prefs.getString("learnedWords", "[]")!!)
            return (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                LearnedWord(o.getString("id"), o.getString("term"), o.getString("meaning"),
                    o.getString("languageCode"), o.optLong("learnedAt"))
            }
        }

    /** Yeni olanları ekler (aynı id varsa atlar); ilk tekrar yarın */
    fun addWords(words: List<LearnedWord>): Int {
        val existing = learnedWords
        val ids = existing.map { it.id }.toSet()
        val fresh = words.filter { it.id !in ids }
        if (fresh.isEmpty()) return 0
        val arr = JSONArray()
        (fresh + existing).take(2000).forEach {
            arr.put(JSONObject().put("id", it.id).put("term", it.term).put("meaning", it.meaning)
                .put("languageCode", it.languageCode).put("learnedAt", it.learnedAt))
        }
        prefs.edit().putString("learnedWords", arr.toString()).apply()
        fresh.forEach { Review.ensure(it.id) }
        bump()
        return fresh.size
    }

    // MARK: Tekrar durumları (ReviewCore)
    fun reviewStates(): JSONObject = JSONObject(prefs.getString("reviewStates", "{}")!!)
    fun saveReviewStates(o: JSONObject) { prefs.edit().putString("reviewStates", o.toString()).apply(); bump() }

    // MARK: Seri (çalışılan günler)
    val studyDays: Set<String> get() = prefs.getStringSet("studyDays", emptySet())!!
    fun markStudiedToday() {
        val today = LocalDate.now().toString()
        if (today in studyDays) return
        prefs.edit().putStringSet("studyDays", (studyDays + today).sorted().takeLast(400).toSet()).apply(); bump()
    }
    /** Bugün ya da dün biten ardışık gün sayısı */
    val streak: Int
        get() {
            val days = studyDays
            var d = LocalDate.now()
            if (d.toString() !in days) d = d.minusDays(1)
            var n = 0
            while (d.toString() in days) { n++; d = d.minusDays(1) }
            return n
        }

    val studiedToday: Boolean get() = LocalDate.now().toString() in studyDays

    // MARK: Hatırlatma saati (son 20 açılışın medyanı, iOS ile aynı)
    fun addOpenMinute(m: Int) {
        val arr = JSONArray(prefs.getString("rem.habitMinutes", "[]")!!)
        val list = (0 until arr.length()).map { arr.getInt(it) } + m
        prefs.edit().putString("rem.habitMinutes", JSONArray(list.takeLast(20)).toString()).apply()
    }
    val habitMinutes: Int
        get() {
            val arr = JSONArray(prefs.getString("rem.habitMinutes", "[]")!!)
            val list = (0 until arr.length()).map { arr.getInt(it) }.sorted()
            return if (list.size < 3) 19 * 60 + 30 else list[list.size / 2]
        }

    // MARK: Sıfırlama
    fun resetAll() {
        val keepDevice = deviceId
        val keepUser = prefs.getString("localUserId", null)
        val edit = prefs.edit().clear().putString("deviceId", keepDevice)
        if (keepUser != null) edit.putString("localUserId", keepUser)
        edit.apply()
        onboardingDone = false
        isPremium = false
        bump()
    }

    private fun stringList(key: String): List<String> {
        val arr = JSONArray(prefs.getString(key, "[]")!!)
        return (0 until arr.length()).map { arr.getString(it) }
    }
    private fun putStringList(key: String, list: List<String>) {
        prefs.edit().putString(key, JSONArray(list).toString()).apply(); bump()
    }
}

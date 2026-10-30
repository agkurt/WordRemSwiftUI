package app.wordrem.android.data

import android.content.Context
import org.json.JSONObject

/** Dil seçenekleri: uygulama dili = ana dil (iOS LanguageManager ile aynı 8 dil) */
data class Lang(val code: String, val nativeName: String, val englishName: String, val flag: String)

val LANGS = listOf(
    Lang("tr", "Türkçe", "Turkish", "🇹🇷"),
    Lang("en", "English", "English", "🇬🇧"),
    Lang("de", "Deutsch", "German", "🇩🇪"),
    Lang("fr", "Français", "French", "🇫🇷"),
    Lang("es", "Español", "Spanish", "🇪🇸"),
    Lang("it", "Italiano", "Italian", "🇮🇹"),
    Lang("ru", "Русский", "Russian", "🇷🇺"),
    Lang("zh", "中文", "Chinese", "🇨🇳"),
)
fun lang(code: String) = LANGS.firstOrNull { it.code == code.lowercase() } ?: LANGS[1]

data class Goal(val id: String, val title: Map<String, String>, val brief: String, val targets: List<String>)
data class Chapter(val id: String, val level: Int, val title: Map<String, String>, val subtitle: Map<String, String>, val goals: List<Goal>)
data class Level(val id: String, val order: Int, val titles: Map<String, String>, val descriptions: Map<String, String>)
data class Word(val id: String, val term: String, val translations: Map<String, String>, val phonetic: String?, val example: String?)

/** "TR"/"EN" anahtarlı metinden ana dildeki karşılık (yoksa İngilizce) */
fun Map<String, String>.loc(code: String = Store.nativeLang): String =
    this[code.uppercase()] ?: this["EN"] ?: values.firstOrNull() ?: ""

/** Paketlenmiş içerik: assets/content.json (kelime kursları) + assets/scenarios.json (Lupa'nın ders planı) */
object Content {
    lateinit var chapters: List<Chapter>; private set
    private lateinit var raw: JSONObject
    private val langIds = mutableMapOf<String, Int>()
    private val courseByTarget = mutableMapOf<Int, String>()

    fun load(context: Context) {
        if (::raw.isInitialized) return
        val sc = JSONObject(context.assets.open("scenarios.json").bufferedReader().readText())
        chapters = sc.getJSONArray("chapters").objects().map { c ->
            Chapter(c.getString("id"), c.optInt("level", 1), c.getJSONObject("title").strings(),
                c.optJSONObject("subtitle")?.strings() ?: emptyMap(),
                c.getJSONArray("goals").objects().map { g ->
                    Goal(g.getString("id"), g.getJSONObject("title").strings(), g.optString("brief"),
                        g.optJSONArray("targets")?.let { a -> (0 until a.length()).map { a.getString(it) } } ?: emptyList())
                })
        }
        raw = JSONObject(context.assets.open("content.json").bufferedReader().readText())
        raw.getJSONArray("languages").objects().forEach { langIds[it.getString("code").uppercase()] = it.getInt("id") }
        raw.getJSONArray("courses").objects().forEach { courseByTarget[it.getInt("target_lang_id")] = it.getString("id") }
    }

    /** Sıradaki ders hedefi: ilk tamamlanmamış (hepsi bittiyse en baştan) */
    fun nextGoal(): Pair<Chapter, Goal>? {
        for (c in chapters) c.goals.firstOrNull { !Store.isGoalDone(it.id) }?.let { return c to it }
        return chapters.firstOrNull()?.let { c -> c.goals.firstOrNull()?.let { c to it } }
    }

    fun goal(chapterId: String, goalId: String): Pair<Chapter, Goal>? =
        chapters.firstOrNull { it.id == chapterId }?.let { c -> c.goals.firstOrNull { it.id == goalId }?.let { c to it } }

    /** Öğrenilen dilin kelime kursu seviyeleri (Türkçe gibi kursu olmayan dilde boş) */
    fun levels(target: String = Store.targetLang): List<Level> {
        val course = langIds[target.uppercase()]?.let { courseByTarget[it] } ?: return emptyList()
        return raw.getJSONArray("levels").objects().filter { it.getString("course_id") == course }
            .map { Level(it.getString("id"), it.getInt("order_index"), it.optJSONObject("titles")?.strings() ?: mapOf("EN" to it.getString("title")),
                it.optJSONObject("descriptions")?.strings() ?: emptyMap()) }
            .sortedBy { it.order }
    }

    fun words(levelId: String): List<Word> {
        val ids = raw.getJSONArray("word_level_assignments").objects().filter { it.getString("level_id") == levelId }
            .sortedBy { it.optInt("display_order") }.map { it.getString("word_id") }
        val byId = raw.getJSONArray("words").objects().filter { it.getString("id") in ids }.associateBy { it.getString("id") }
        return ids.mapNotNull { byId[it] }.map {
            val tr = it.optJSONObject("translations")?.strings()?.toMutableMap() ?: mutableMapOf()
            Word(it.getString("id"), it.getString("term"), tr, it.optString("phonetic").takeIf { p -> p.isNotBlank() && p != "null" },
                it.optString("example_sentence").takeIf { e -> e.isNotBlank() && e != "null" })
        }
    }
}

private fun org.json.JSONArray.objects(): List<JSONObject> = (0 until length()).map { getJSONObject(it) }
private fun JSONObject.strings(): Map<String, String> = keys().asSequence().associateWith { optString(it) }

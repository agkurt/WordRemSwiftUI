package app.wordrem.android.data

import org.json.JSONObject
import java.time.LocalDate
import java.time.ZoneId
import kotlin.math.max
import kotlin.math.roundToInt

/** iOS ReviewCore ile aynı SM-2 benzeri tekrar algoritması */
enum class Grade { AGAIN, HARD, GOOD, EASY }

object Review {
    private fun startOfDay(daysFromToday: Long): Long =
        LocalDate.now().plusDays(daysFromToday).atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli()

    /** Yeni kelime: ilk tekrarı yarın */
    fun ensure(id: String) {
        val all = Store.reviewStates()
        if (all.has(id)) return
        all.put(id, JSONObject().put("interval", 0.0).put("ease", 2.5).put("reps", 0).put("lapses", 0)
            .put("due", startOfDay(1)))
        Store.saveReviewStates(all)
    }

    fun grade(id: String, g: Grade) {
        val all = Store.reviewStates()
        val s = all.optJSONObject(id) ?: JSONObject().put("interval", 0.0).put("ease", 2.5).put("reps", 0).put("lapses", 0)
        var interval = s.optDouble("interval", 0.0)
        var ease = s.optDouble("ease", 2.5)
        var reps = s.optInt("reps")
        var lapses = s.optInt("lapses")
        val due: Long
        when (g) {
            Grade.AGAIN -> {
                lapses++; reps = 0; interval = 0.0; ease = max(1.3, ease - 0.2)
                due = System.currentTimeMillis() + 10 * 60_000
            }
            else -> {
                when (g) {
                    Grade.HARD -> { interval = max(1.0, interval * 1.2); ease = max(1.3, ease - 0.15) }
                    Grade.GOOD -> { interval = when (reps) { 0 -> 1.0; 1 -> 3.0; else -> interval * ease }; reps++ }
                    else -> { interval = if (reps == 0) 3.0 else max(4.0, interval * ease * 1.3); reps++; ease += 0.15 }
                }
                due = startOfDay(max(1, interval.roundToInt()).toLong())
            }
        }
        all.put(id, s.put("interval", interval).put("ease", ease).put("reps", reps).put("lapses", lapses)
            .put("due", due).put("lastReviewed", System.currentTimeMillis()))
        Store.saveReviewStates(all)
        Store.markStudiedToday()
    }

    /** Bugün tekrar zamanı gelenler (yalnızca öğrenilen dil) */
    fun dueToday(lang: String = Store.targetLang): List<LearnedWord> {
        val states = Store.reviewStates()
        val end = startOfDay(1)
        return Store.learnedWords.filter { w ->
            w.languageCode.equals(lang, true) && (states.optJSONObject(w.id)?.optLong("due") ?: 0L) < end
        }
    }

    fun intervalDays(id: String): Double = Store.reviewStates().optJSONObject(id)?.optDouble("interval", 0.0) ?: 0.0
    fun isMature(id: String) = intervalDays(id) >= 21
}

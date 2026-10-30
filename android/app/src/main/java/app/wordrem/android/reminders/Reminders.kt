package app.wordrem.android.reminders

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import app.wordrem.android.MainActivity
import app.wordrem.android.R
import app.wordrem.android.data.Content
import app.wordrem.android.data.Store
import app.wordrem.android.data.loc
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId

/**
 * Günde en fazla bir Lupa hatırlatması (iOS SmartReminders'ın sade hâli): kullanıcının uygulamayı genelde açtığı
 * saatte (son açılışların medyanı, yoksa 19:30), o gün çalışmadıysa. Seri varsa seriyi kurtarma, yoksa sıradaki ders.
 */
object Reminders {
    private const val CHANNEL = "lupa"

    /** Uygulama her açıldığında: alışkanlık saatini öğren ve sıradaki hatırlatmayı kur */
    fun onAppOpen(context: Context) {
        val now = LocalDateTime.now()
        val minutes = now.hour * 60 + now.minute
        if (minutes in 6 * 60..23 * 60) Store.addOpenMinute(minutes)
        schedule(context)
    }

    fun schedule(context: Context) {
        if (!Store.onboardingDone) return
        val habit = Store.habitMinutes
        var fire = LocalDate.now().atStartOfDay().plusMinutes(habit.toLong())
        if (!fire.isAfter(LocalDateTime.now().plusMinutes(5)) || Store.studiedToday) fire = fire.plusDays(1)
        val at = fire.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
        val alarms = context.getSystemService(AlarmManager::class.java)
        // Kesin alarm izni gerekmez: birkaç dakika kayabilir, hatırlatma için yeterli
        alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending(context))
    }

    private fun pending(context: Context) = PendingIntent.getBroadcast(
        context, 1, Intent(context, ReminderReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    fun show(context: Context) {
        if (Store.studiedToday || !Store.onboardingDone) return
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
            && android.os.Build.VERSION.SDK_INT >= 33) return
        val nm = context.getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(NotificationChannel(CHANNEL, "Lupa", NotificationManager.IMPORTANCE_DEFAULT))
        val streak = Store.streak
        val body = if (streak >= 2) streakRescue(streak)
            else nextLesson(Content.nextGoal()?.second?.title?.loc() ?: "")
        val open = PendingIntent.getActivity(context, 0, Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP), PendingIntent.FLAG_IMMUTABLE)
        val n = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Lupa")
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(open)
            .setAutoCancel(true)
            .build()
        runCatching { NotificationManagerCompat.from(context).notify(1, n) }
    }

    private fun pick(v: Map<String, String>) = v[Store.nativeLang] ?: v["en"]!!

    private fun streakRescue(n: Int) = pick(mapOf(
        "tr" to "🔥 $n günlük serin bu gece bitiyor! Benimle 2 dakika konuş, kurtaralım.",
        "en" to "🔥 Your $n-day streak ends tonight! Talk with me for 2 minutes and let's save it.",
        "de" to "🔥 Deine $n-Tage-Serie endet heute Nacht! Sprich 2 Minuten mit mir und wir retten sie.",
        "fr" to "🔥 Ta série de $n jours se termine ce soir ! Parle 2 minutes avec moi pour la sauver.",
        "es" to "🔥 ¡Tu racha de $n días termina esta noche! Habla conmigo 2 minutos y la salvamos.",
        "it" to "🔥 La tua serie di $n giorni finisce stanotte! Parla con me 2 minuti e la salviamo.",
        "ru" to "🔥 Твоя серия из $n дн. закончится сегодня ночью! Поговори со мной 2 минуты, и мы её сохраним.",
        "zh" to "🔥 你连续 $n 天的记录今晚就要断了！和我聊 2 分钟，一起保住它。",
    ))

    private fun nextLesson(lesson: String) = pick(mapOf(
        "tr" to "Bugün “$lesson” konuşalım mı? Senin için hazırladım.",
        "en" to "Shall we do “$lesson” today? I've got it ready for you.",
        "de" to "Wollen wir heute „$lesson“ machen? Ich habe alles vorbereitet.",
        "fr" to "On fait « $lesson » aujourd'hui ? Je l'ai préparé pour toi.",
        "es" to "¿Hacemos “$lesson” hoy? Ya lo tengo listo para ti.",
        "it" to "Facciamo “$lesson” oggi? L'ho preparato per te.",
        "ru" to "Займёмся сегодня уроком «$lesson»? Я всё подготовила.",
        "zh" to "今天来练“$lesson”好吗？我已经为你准备好了。",
    ))
}

/** Hatırlatma saati geldi (ya da telefon yeniden başladı): göster ve yarını kur */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Store.init(context.applicationContext)
        Content.load(context.applicationContext)
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) Reminders.show(context)
        Reminders.schedule(context)
    }
}

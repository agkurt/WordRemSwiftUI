package app.wordrem.android.ui

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.wordrem.android.BuildConfig
import app.wordrem.android.Nav
import app.wordrem.android.Route
import app.wordrem.android.billing.Billing
import app.wordrem.android.data.LANGS
import app.wordrem.android.data.Review
import app.wordrem.android.data.Store
import app.wordrem.android.data.lang
import app.wordrem.android.i18n.K
import kotlinx.coroutines.launch
import java.time.LocalDate

/** iOS ProfileView: ad + Pro durumu, seri takvimi, istatistikler, ayarlar */
@Composable
fun ProfileScreen(nav: Nav) {
    Store.version
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var picker by remember { mutableStateOf<String?>(null) }   // "native" | "target"
    var confirmReset by remember { mutableStateOf(false) }
    fun open(url: String) = context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text(K.TAB_PROFILE(), style = DS.title)
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(56.dp).clip(CircleShape).background(DS.accentSoft), contentAlignment = Alignment.Center) {
                Text(Store.username.take(1).uppercase().ifEmpty { "?" }, fontSize = 24.sp, color = DS.accent, fontWeight = FontWeight.Bold)
            }
            Spacer(Modifier.size(14.dp))
            Column {
                Text(Store.username, style = DS.heading)
                Text(if (Store.isPremium) K.PRO_ACTIVE() else "WordRem AI", color = if (Store.isPremium) DS.success else DS.muted, fontSize = 14.sp)
            }
        }

        if (!Store.isPremium) Card(onClick = { nav.push(Route.Paywall) }, color = DS.ink) {
            Text(K.GO_PRO(), color = DS.raised, style = DS.heading.copy(color = DS.raised))
            Spacer(Modifier.height(4.dp))
            Text(K.GO_PRO_SUB(), color = DS.raised.copy(alpha = 0.8f), fontSize = 14.sp)
        }

        Card {
            Text(K.STREAK_DAYS.f(Store.streak), style = DS.heading)
            Spacer(Modifier.height(12.dp))
            val today = LocalDate.now()
            val monday = today.minusDays((today.dayOfWeek.value - 1).toLong())
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                (0..6).forEach { i ->
                    val d = monday.plusDays(i.toLong())
                    val studied = d.toString() in Store.studyDays
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(d.dayOfWeek.getDisplayName(java.time.format.TextStyle.NARROW, java.util.Locale.forLanguageTag(Store.nativeLang)),
                            fontSize = 12.sp, color = DS.muted)
                        Spacer(Modifier.height(4.dp))
                        Box(Modifier.size(30.dp).clip(CircleShape).background(if (studied) DS.accent else if (d == today) DS.accentSoft else DS.sunken),
                            contentAlignment = Alignment.Center) {
                            Text("${d.dayOfMonth}", fontSize = 12.sp, color = if (studied) DS.raised else DS.inkSoft)
                        }
                    }
                }
            }
        }

        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Stat(Store.learnedWords.size.toString(), K.WORDS_LEARNED(), Modifier.weight(1f))
            Stat(Store.goalsDoneCount.toString(), K.LESSONS_DONE(), Modifier.weight(1f))
            Stat(Store.studyDays.size.toString(), K.STUDY_DAYS(), Modifier.weight(1f))
        }

        Card {
            Setting(K.NATIVE_LANGUAGE(), lang(Store.nativeLang).let { "${it.flag} ${it.nativeName}" }) { picker = "native" }
            Divider()
            Setting(K.LEARNING_LANGUAGE(), lang(Store.targetLang).let { "${it.flag} ${it.nativeName}" }) { picker = "target" }
            Divider()
            Setting(K.RESTORE(), "") { scope.launch { Billing.restore() } }
            Divider()
            Setting(K.MANAGE_SUB(), "") { open("https://play.google.com/store/account/subscriptions?package=${BuildConfig.APPLICATION_ID}") }
            Divider()
            Setting(K.PRIVACY(), "") { open("https://api.wordremai.app/privacy") }
            Divider()
            Setting(K.TERMS(), "") { open("https://api.wordremai.app/terms") }
            Divider()
            Setting(K.RESET(), "", danger = true) { confirmReset = true }
        }
        Text("WordRem AI ${BuildConfig.VERSION_NAME} · ${Review.dueToday().size}", fontSize = 11.sp, color = DS.muted)
    }

    picker?.let { which ->
        val options = if (which == "native") LANGS else LANGS.filter { it.code != Store.nativeLang }
        AlertDialog(
            onDismissRequest = { picker = null },
            confirmButton = {}, dismissButton = { TextButton(onClick = { picker = null }) { Text(K.CANCEL()) } },
            text = {
                Column {
                    options.forEach { l ->
                        Text("${l.flag}  ${l.nativeName}", fontSize = 18.sp, color = DS.ink, modifier = Modifier.fillMaxWidth().clickable {
                            if (which == "native") {
                                Store.nativeLang = l.code
                                if (Store.targetLang == l.code) Store.targetLang = if (l.code == "en") "es" else "en"
                            } else Store.targetLang = l.code
                            picker = null
                        }.padding(vertical = 10.dp))
                    }
                }
            },
        )
    }
    if (confirmReset) AlertDialog(
        onDismissRequest = { confirmReset = false },
        title = { Text(K.RESET()) }, text = { Text(K.RESET_CONFIRM()) },
        confirmButton = { TextButton(onClick = { confirmReset = false; Store.resetAll() }) { Text(K.RESET(), color = DS.danger) } },
        dismissButton = { TextButton(onClick = { confirmReset = false }) { Text(K.CANCEL()) } },
    )
}

@Composable
private fun Stat(value: String, label: String, modifier: Modifier) {
    Column(modifier.clip(RoundedCornerShape(16.dp)).background(DS.raised).padding(14.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, style = DS.heading)
        Text(label, fontSize = 12.sp, color = DS.muted)
    }
}

@Composable
private fun Setting(label: String, value: String, danger: Boolean = false, onClick: () -> Unit) {
    Row(Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, color = if (danger) DS.danger else DS.ink, modifier = Modifier.weight(1f))
        Text(value, color = DS.muted)
    }
}

@Composable
private fun Divider() = HorizontalDivider(color = DS.line)

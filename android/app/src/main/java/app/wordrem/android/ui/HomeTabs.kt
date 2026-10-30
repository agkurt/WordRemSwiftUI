package app.wordrem.android.ui

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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.wordrem.android.Nav
import app.wordrem.android.Route
import app.wordrem.android.data.Content
import app.wordrem.android.data.Review
import app.wordrem.android.data.Store
import app.wordrem.android.data.lang
import app.wordrem.android.data.loc
import app.wordrem.android.i18n.K
import app.wordrem.android.voice.TutorMode

/** iOS MainTabView: Konuş · Kelimeler · Profil */
@Composable
fun HomeTabs(nav: Nav) {
    var tab by rememberSaveable { mutableIntStateOf(0) }
    Column(Modifier.fillMaxSize()) {
        Box(Modifier.weight(1f)) {
            when (tab) {
                0 -> TalkHome(nav)
                1 -> WordsScreen(nav)
                else -> ProfileScreen(nav)
            }
        }
        HorizontalDivider(color = DS.line)
        Row(Modifier.fillMaxWidth().background(DS.raised).padding(vertical = 6.dp)) {
            TabItem(Icons.Default.GraphicEq, K.TAB_TALK(), tab == 0) { tab = 0 }
            TabItem(Icons.AutoMirrored.Filled.MenuBook, K.TAB_WORDS(), tab == 1) { tab = 1 }
            TabItem(Icons.Default.Person, K.TAB_PROFILE(), tab == 2) { tab = 2 }
        }
    }
}

@Composable
private fun androidx.compose.foundation.layout.RowScope.TabItem(icon: ImageVector, label: String, selected: Boolean, onClick: () -> Unit) {
    Column(Modifier.weight(1f).clickable(onClick = onClick).padding(vertical = 6.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(icon, contentDescription = label, tint = if (selected) DS.accent else DS.muted)
        Text(label, fontSize = 11.sp, color = if (selected) DS.accent else DS.muted, fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal)
    }
}

/** iOS TalkHomeView: üst çubuk (bayrak, seri), tekrar şeridi, sıradaki ders, asistanla serbest sohbet */
@Composable
fun TalkHome(nav: Nav) {
    Store.version   // veriler değişince yenile
    val target = lang(Store.targetLang)
    val due = Review.dueToday()
    val next = Content.nextGoal()
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(target.flag, fontSize = 26.sp)
            Spacer(Modifier.width(8.dp))
            Column(Modifier.weight(1f)) {
                Text(target.nativeName, fontWeight = FontWeight.SemiBold, color = DS.ink)
                Text(K.LEVEL.f(1 + Store.goalsDoneCount / 5), fontSize = 12.sp, color = DS.muted)
            }
            Icon(Icons.Default.LocalFireDepartment, contentDescription = null, tint = if (Store.streak > 0) DS.accent else DS.muted)
            Text("${Store.streak}", fontWeight = FontWeight.Bold, color = DS.ink, fontSize = 17.sp)
        }
        Text(if (Store.username.isNotEmpty()) K.HELLO.f(Store.username) else K.TAB_TALK(), style = DS.title)

        if (due.isNotEmpty()) {
            Card(onClick = { nav.push(Route.Review) }, color = DS.accentSoft) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(K.REVIEW_DUE.f(due.size), color = DS.ink, fontWeight = FontWeight.Medium, modifier = Modifier.weight(1f))
                    Text(K.REVIEW_START(), color = DS.accent, fontWeight = FontWeight.Bold)
                }
            }
        }

        next?.let { (chapter, goal) ->
            Card {
                Text(K.NEXT_LESSON().uppercase(), style = DS.eyebrow)
                Spacer(Modifier.height(6.dp))
                Text(goal.title.loc(), style = DS.heading)
                Spacer(Modifier.height(4.dp))
                Text(chapter.title.loc() + " · " + chapter.subtitle.loc(), style = DS.body.copy(fontSize = 14.sp))
                Spacer(Modifier.height(16.dp))
                PrimaryButton(K.START_LESSON(), color = DS.accent) { nav.push(Route.Voice(TutorMode.Goal(chapter.id, goal.id))) }
            }
        }

        Card(onClick = { nav.push(Route.Voice(TutorMode.FreeChat)) }, color = DS.slate) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(44.dp).clip(CircleShape).background(DS.raised), contentAlignment = Alignment.Center) { LupaBars(24.dp) }
                Spacer(Modifier.width(14.dp))
                Column {
                    Text(K.TALK_ASSISTANT(), color = DS.raised, fontWeight = FontWeight.SemiBold, fontSize = 18.sp)
                    Spacer(Modifier.height(2.dp))
                    Text(K.TALK_ASSISTANT_SUB(), color = DS.raised.copy(alpha = 0.8f), fontSize = 14.sp)
                }
            }
        }

        // Plan: bölümdeki hedefler
        next?.first?.let { chapter ->
            Text(chapter.title.loc().uppercase(), style = DS.eyebrow, modifier = Modifier.padding(top = 8.dp))
            chapter.goals.forEach { g ->
                val done = Store.isGoalDone(g.id)
                Row(Modifier.fillMaxWidth().clip(androidx.compose.foundation.shape.RoundedCornerShape(12.dp))
                    .clickable { nav.push(Route.Voice(TutorMode.Goal(chapter.id, g.id))) }.padding(vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(22.dp).clip(CircleShape).background(if (done) DS.success else DS.sunken), contentAlignment = Alignment.Center) {
                        if (done) Text("✓", color = DS.raised, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                    Spacer(Modifier.width(12.dp))
                    Text(g.title.loc(), color = if (done) DS.muted else DS.ink, fontSize = 16.sp)
                }
            }
        }
    }
}

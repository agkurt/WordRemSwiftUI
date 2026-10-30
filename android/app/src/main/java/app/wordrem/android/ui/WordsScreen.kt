package app.wordrem.android.ui

import androidx.compose.animation.core.animateFloatAsState
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.wordrem.android.Nav
import app.wordrem.android.Route
import app.wordrem.android.data.Content
import app.wordrem.android.data.Grade
import app.wordrem.android.data.LearnedWord
import app.wordrem.android.data.Level
import app.wordrem.android.data.Review
import app.wordrem.android.data.Store
import app.wordrem.android.data.loc
import app.wordrem.android.i18n.K
import app.wordrem.android.voice.TutorMode

/** iOS WordsView: Öğrendiklerim (Lupa'nın kartları + eklenen kelimeler) · Kurs (paketlenmiş kelime seviyeleri) */
@Composable
fun WordsScreen(nav: Nav) {
    var segment by rememberSaveable { mutableIntStateOf(0) }
    var level by remember { mutableStateOf<Level?>(null) }
    Store.version
    Column(Modifier.fillMaxSize().padding(horizontal = 20.dp)) {
        Spacer(Modifier.height(20.dp))
        Text(K.TAB_WORDS(), style = DS.title)
        Spacer(Modifier.height(12.dp))
        Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(DS.sunken).padding(4.dp)) {
            listOf(K.LEARNED(), K.COURSE()).forEachIndexed { i, label ->
                Box(Modifier.weight(1f).clip(RoundedCornerShape(10.dp)).background(if (segment == i) DS.raised else Color.Transparent)
                    .clickable { segment = i; level = null }.padding(vertical = 9.dp), contentAlignment = Alignment.Center) {
                    Text(label, fontWeight = if (segment == i) FontWeight.SemiBold else FontWeight.Normal, color = DS.ink)
                }
            }
        }
        Spacer(Modifier.height(12.dp))
        when {
            segment == 0 -> LearnedList(nav)
            level == null -> LevelList { level = it }
            else -> LevelWords(level!!) { level = null }
        }
    }
}

@Composable
private fun LearnedList(nav: Nav) {
    val words = Store.learnedWords.filter { it.languageCode.equals(Store.targetLang, true) }
    val due = Review.dueToday()
    LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        if (due.isNotEmpty()) item {
            PrimaryButton(K.REVIEW_DUE.f(due.size), color = DS.accent) { nav.push(Route.Review) }
        }
        if (words.isNotEmpty()) item {
            Card(onClick = { nav.push(Route.Voice(TutorMode.WordPractice)) }, color = DS.slate) {
                Text(K.PRACTICE_WORDS(), color = DS.raised, fontWeight = FontWeight.SemiBold)
            }
        }
        if (words.isEmpty()) item { Text(K.NO_WORDS(), style = DS.body, modifier = Modifier.padding(top = 24.dp), textAlign = TextAlign.Center) }
        items(words, key = { it.id }) { WordRow(it) }
        item { Spacer(Modifier.height(16.dp)) }
    }
}

@Composable
private fun WordRow(w: LearnedWord) {
    Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(DS.raised).padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f)) {
            Text(w.term, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = DS.ink)
            Text(w.meaning, fontSize = 14.sp, color = DS.inkSoft)
        }
        val days = Review.intervalDays(w.id)
        Box(Modifier.clip(RoundedCornerShape(8.dp)).background(if (days >= 21) DS.success else if (days >= 3) DS.gold else DS.sunken)
            .padding(horizontal = 8.dp, vertical = 4.dp)) {
            Text(if (days < 1) "•" else "${days.toInt()}d", fontSize = 12.sp, color = if (days >= 3) DS.raised else DS.muted)
        }
    }
}

@Composable
private fun LevelList(onOpen: (Level) -> Unit) {
    val levels = remember(Store.targetLang) { Content.levels() }
    if (levels.isEmpty()) { Text(K.NO_COURSE(), style = DS.body, modifier = Modifier.padding(top = 24.dp)); return }
    LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        items(levels, key = { it.id }) { l ->
            Card(onClick = { onOpen(l) }) {
                Text(K.LEVEL.f(l.order).uppercase(), style = DS.eyebrow)
                Text(l.titles.loc(), style = DS.heading.copy(fontSize = 18.sp))
                Text(l.descriptions.loc(), style = DS.body.copy(fontSize = 14.sp))
            }
        }
        item { Spacer(Modifier.height(16.dp)) }
    }
}

@Composable
private fun LevelWords(level: Level, onBack: () -> Unit) {
    val words = remember(level.id) { Content.words(level.id) }
    var message by remember { mutableStateOf<String?>(null) }
    Column {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null, tint = DS.ink) }
            Text(level.titles.loc(), style = DS.heading)
        }
        PrimaryButton(message ?: K.ADD_TO_REVIEW(), color = DS.accent) {
            val n = Store.addWords(words.map {
                LearnedWord("course:${it.id}", it.term, it.translations.loc().ifEmpty { it.translations["EN"] ?: "" },
                    Store.targetLang.uppercase(), System.currentTimeMillis())
            })
            message = K.ADDED.f(n)
        }
        Spacer(Modifier.height(10.dp))
        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(words, key = { it.id }) { w ->
                Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(DS.raised).padding(14.dp)) {
                    Row(verticalAlignment = Alignment.Bottom) {
                        Text(w.term, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = DS.ink)
                        w.phonetic?.let { Text("  $it", fontSize = 13.sp, color = DS.muted) }
                    }
                    Text(w.translations.loc(), fontSize = 14.sp, color = DS.inkSoft)
                    w.example?.let { Text(it, fontSize = 13.sp, color = DS.muted) }
                }
            }
            item { Spacer(Modifier.height(16.dp)) }
        }
    }
}

/** iOS ReviewSessionView: terim → dokununca anlam → Tekrar / Zor / İyi / Kolay */
@Composable
fun ReviewScreen(onClose: () -> Unit) {
    val queue = remember { mutableStateListOf<LearnedWord>().apply { addAll(Review.dueToday().shuffled()) } }
    var revealed by remember { mutableStateOf(false) }
    Column(Modifier.fillMaxSize().padding(20.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onClose) { Icon(Icons.Default.Close, contentDescription = null, tint = DS.inkSoft) }
            Spacer(Modifier.weight(1f))
            Text("${queue.size}", color = DS.muted)
        }
        val w = queue.firstOrNull()
        if (w == null) {
            Column(Modifier.weight(1f).fillMaxWidth(), verticalArrangement = Arrangement.Center, horizontalAlignment = Alignment.CenterHorizontally) {
                LupaBars(64.dp)
                Spacer(Modifier.height(20.dp))
                Text(K.REVIEW_DONE(), style = DS.title, textAlign = TextAlign.Center)
            }
            PrimaryButton(K.DONE(), onClick = onClose)
            return@Column
        }
        Box(Modifier.weight(1f).fillMaxWidth().clickable { revealed = true }, contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(w.term, style = DS.title.copy(fontSize = 34.sp), textAlign = TextAlign.Center)
                Spacer(Modifier.height(18.dp))
                val a by animateFloatAsState(if (revealed) 1f else 0.35f, label = "reveal")
                Text(w.meaning, style = DS.body.copy(fontSize = 20.sp), textAlign = TextAlign.Center,
                    modifier = Modifier.alpha(a).then(if (revealed) Modifier else Modifier.blur(10.dp)))
                if (!revealed) { Spacer(Modifier.height(18.dp)); Text(K.SHOW_ANSWER(), color = DS.accent, fontWeight = FontWeight.SemiBold) }
            }
        }
        if (revealed) Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf(Grade.AGAIN to (K.AGAIN() to DS.danger), Grade.HARD to (K.HARD() to DS.gold),
                Grade.GOOD to (K.GOOD() to DS.success), Grade.EASY to (K.EASY() to DS.slate)).forEach { (g, v) ->
                Box(Modifier.weight(1f).height(54.dp).clip(RoundedCornerShape(14.dp)).background(v.second).clickable {
                    Review.grade(w.id, g)
                    queue.removeAt(0)
                    if (g == Grade.AGAIN) queue.add(w)   // tekrar kuyruğun sonuna
                    revealed = false
                }, contentAlignment = Alignment.Center) { Text(v.first, color = Color.White, fontWeight = FontWeight.SemiBold) }
            }
        }
    }
}

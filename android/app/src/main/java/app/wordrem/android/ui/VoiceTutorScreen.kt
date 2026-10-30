package app.wordrem.android.ui

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import app.wordrem.android.Nav
import app.wordrem.android.Route
import app.wordrem.android.data.Content
import app.wordrem.android.data.Store
import app.wordrem.android.data.loc
import app.wordrem.android.i18n.K
import app.wordrem.android.voice.Phase
import app.wordrem.android.voice.TutorMode
import app.wordrem.android.voice.TutorSession
import app.wordrem.android.voice.Turn

/** Canlı ders ekranı: altyazılar, ifade kartları, bas-konuş düğmesi ve yazarak konuşma */
@Composable
fun VoiceTutorScreen(mode: TutorMode, nav: Nav, onboarding: Boolean = false, onDone: () -> Unit = { nav.pop() }) {
    val context = LocalContext.current
    var micGranted by remember {
        mutableStateOf(ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED)
    }
    val askMic = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { micGranted = it }
    LaunchedEffect(Unit) { if (!micGranted) askMic.launch(Manifest.permission.RECORD_AUDIO) }

    val session = remember(mode) { TutorSession(mode) }
    DisposableEffect(session) { onDispose { session.release() } }
    LaunchedEffect(micGranted) { if (micGranted && session.phase == Phase.CONNECTING) session.start() }

    val title = when (mode) {
        is TutorMode.Goal -> Content.goal(mode.chapterId, mode.goalId)?.second?.title?.loc() ?: "Lupa"
        TutorMode.Demo -> K.DEMO_TITLE()
        TutorMode.WordPractice -> K.PRACTICE_WORDS()
        TutorMode.FreeChat -> K.TALK_ASSISTANT()
    }

    Column(Modifier.fillMaxSize().imePadding()) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = { session.end(); onDone() }) { Icon(Icons.Default.Close, contentDescription = K.END(), tint = DS.inkSoft) }
            Text(title, style = DS.heading.copy(fontSize = 18.sp), modifier = Modifier.weight(1f), maxLines = 1)
            if (onboarding) Text(K.SKIP(), color = DS.muted, modifier = Modifier.padding(12.dp).pointerInput(Unit) {
                detectTapGestures { session.end(); onDone() }
            })
        }

        when {
            !micGranted -> Centered {
                Text(K.MIC_NEEDED(), style = DS.body, textAlign = TextAlign.Center)
                Spacer(Modifier.height(16.dp))
                PrimaryButton(K.ALLOW()) { askMic.launch(Manifest.permission.RECORD_AUDIO) }
            }
            session.lessonComplete -> LessonComplete(session) { onDone() }
            session.errorCode != null -> ErrorState(session.errorCode!!,
                onPro = { if (onboarding) onDone() else nav.replaceTop(Route.Paywall) },
                onRetry = { nav.replaceTop(Route.Voice(mode)) },
                onClose = onDone)
            else -> LiveSession(session, onboarding)
        }
    }
}

@Composable
private fun Centered(content: @Composable () -> Unit) {
    Column(Modifier.fillMaxSize().padding(32.dp), verticalArrangement = Arrangement.Center, horizontalAlignment = Alignment.CenterHorizontally) { content() }
}

@Composable
private fun ErrorState(code: String, onPro: () -> Unit, onRetry: () -> Unit, onClose: () -> Unit) = Centered {
    LupaBars(56.dp, active = false)
    Spacer(Modifier.height(24.dp))
    val freeOver = (code == "paywall" || code == "time_up") && !Store.isPremium
    Text(when {
        freeOver -> K.FREE_TIME_UP()
        code == "limit_reached" || code == "time_up" -> K.LIMIT_REACHED()
        else -> K.ERROR_NETWORK()
    }, style = DS.body, textAlign = TextAlign.Center)
    Spacer(Modifier.height(24.dp))
    when {
        freeOver -> PrimaryButton(K.GO_PRO(), color = DS.accent, onClick = onPro)
        code == "network" || code == "too_many_new_users" -> PrimaryButton(K.TRY_AGAIN(), onClick = onRetry)
        else -> PrimaryButton(K.DONE(), onClick = onClose)
    }
}

@Composable
private fun LessonComplete(session: TutorSession, onDone: () -> Unit) {
    val cards = session.turns.filter { it.role == Turn.Role.CARD }.distinctBy { it.text }
    Column(Modifier.fillMaxSize().padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.height(24.dp))
        LupaBars(72.dp)
        Spacer(Modifier.height(20.dp))
        Text(K.LESSON_COMPLETE(), style = DS.title)
        Spacer(Modifier.height(20.dp))
        if (cards.isNotEmpty()) {
            Text(K.PHRASES_LEARNED().uppercase(), style = DS.eyebrow, modifier = Modifier.fillMaxWidth())
            Spacer(Modifier.height(8.dp))
            LazyColumn(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                itemsIndexed(cards) { _, c -> PhraseCard(c) }
            }
        } else Spacer(Modifier.weight(1f))
        PrimaryButton(K.DONE(), onClick = onDone)
    }
}

@Composable
private fun PhraseCard(c: Turn) {
    Card(color = DS.accentSoft) {
        Text(c.text, fontSize = 19.sp, fontWeight = FontWeight.SemiBold, color = DS.ink)
        if (c.translation.isNotBlank()) {
            Spacer(Modifier.height(4.dp))
            Text(c.translation, style = DS.body)
        }
    }
}

@Composable
private fun LiveSession(session: TutorSession, onboarding: Boolean) {
    val list = rememberLazyListState()
    LaunchedEffect(session.turns.size, session.turns.lastOrNull()?.text?.length) {
        if (session.turns.isNotEmpty()) list.animateScrollToItem(session.turns.lastIndex)
    }
    Column(Modifier.fillMaxSize()) {
        Box(Modifier.fillMaxWidth().padding(vertical = 8.dp), contentAlignment = Alignment.Center) {
            LupaBars(48.dp, active = session.phase == Phase.SPEAKING || session.phase == Phase.CONNECTING)
        }
        LazyColumn(Modifier.weight(1f).padding(horizontal = 16.dp), state = list, verticalArrangement = Arrangement.spacedBy(10.dp)) {
            itemsIndexed(session.turns) { _, t ->
                when (t.role) {
                    Turn.Role.CARD -> PhraseCard(t)
                    Turn.Role.AI -> Text(t.text, style = DS.body.copy(color = DS.ink, fontSize = 17.sp), modifier = Modifier.fillMaxWidth(0.92f))
                    Turn.Role.USER -> Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.CenterEnd) {
                        Text(t.text, color = Color.White, fontSize = 16.sp, modifier = Modifier.widthIn(max = 300.dp)
                            .clip(RoundedCornerShape(16.dp)).background(DS.slate).padding(horizontal = 14.dp, vertical = 10.dp))
                    }
                }
            }
        }
        Text(
            when (session.phase) {
                Phase.CONNECTING -> K.CONNECTING()
                Phase.LISTENING -> K.LISTENING()
                Phase.THINKING -> K.THINKING()
                Phase.SPEAKING -> K.SPEAKING()
                else -> if (session.turns.isEmpty()) K.HOLD_TO_TALK() else K.YOUR_TURN()
            },
            style = DS.eyebrow.copy(fontSize = 13.sp), textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
        )
        HoldToTalk(session)
        if (!onboarding) TextInput(session)
        Spacer(Modifier.height(8.dp))
    }
}

@Composable
private fun HoldToTalk(session: TutorSession) {
    val listening = session.phase == Phase.LISTENING
    val enabled = session.phase != Phase.CONNECTING
    Box(Modifier.fillMaxWidth().padding(vertical = 12.dp), contentAlignment = Alignment.Center) {
        Box(
            Modifier.size(88.dp).scale(if (listening) 1.12f else 1f).clip(CircleShape)
                .background(if (!enabled) DS.line else if (listening) DS.accentDeep else DS.accent)
                .pointerInput(enabled) {
                    if (!enabled) return@pointerInput
                    detectTapGestures(onPress = {
                        session.holdStart()
                        tryAwaitRelease()
                        session.holdEnd()
                    })
                },
            contentAlignment = Alignment.Center,
        ) { Icon(Icons.Default.Mic, contentDescription = K.HOLD_TO_TALK(), tint = Color.White, modifier = Modifier.size(38.dp)) }
    }
}

@Composable
private fun TextInput(session: TutorSession) {
    var text by remember { mutableStateOf("") }
    val send = { session.sendText(text); text = "" }
    Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        OutlinedTextField(
            value = text, onValueChange = { text = it }, singleLine = true, placeholder = { Text(K.TYPE_MESSAGE()) },
            shape = RoundedCornerShape(22.dp), modifier = Modifier.weight(1f),
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send), keyboardActions = KeyboardActions(onSend = { send() }),
            colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = DS.accent, unfocusedBorderColor = DS.line,
                focusedContainerColor = DS.raised, unfocusedContainerColor = DS.raised),
        )
        IconButton(onClick = send, enabled = text.isNotBlank() && session.phase != Phase.CONNECTING) {
            Icon(Icons.AutoMirrored.Filled.Send, contentDescription = null, tint = if (text.isNotBlank()) DS.accent else DS.muted)
        }
    }
}

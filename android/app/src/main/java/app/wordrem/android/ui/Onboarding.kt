package app.wordrem.android.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.wordrem.android.Nav
import app.wordrem.android.data.LANGS
import app.wordrem.android.data.Lang
import app.wordrem.android.data.Store
import app.wordrem.android.i18n.K
import app.wordrem.android.voice.TutorMode

/** iOS OnboardingFlow: hoş geldin → ana dil → öğrenilecek dil → ad → Lupa demosu → ödeme ekranı */
@Composable
fun OnboardingFlow() {
    var step by rememberSaveable { mutableStateOf(0) }
    val version = Store.version   // dil değişince metinler yenilensin
    BackHandler(enabled = step in 1..3) { step-- }
    when (step) {
        0 -> Welcome { step = 1 }
        1 -> LangPicker(K.NATIVE_Q(), LANGS, Store.nativeLang.takeIf { version >= 0 }) { Store.nativeLang = it; step = 2 }
        2 -> LangPicker(K.TARGET_Q(), LANGS.filter { it.code != Store.nativeLang }, null) {
            Store.targetLang = it; Store.proficiency = 1; step = 3
        }
        3 -> NameStep { Store.username = it; step = 4 }
        4 -> {
            val nav = androidx.compose.runtime.remember { Nav() }
            Column(Modifier.fillMaxSize()) {
                VoiceTutorScreen(TutorMode.Demo, nav, onboarding = true, onDone = { step = 5 })
            }
        }
        else -> PaywallScreen(onClose = { Store.completeOnboarding() })
    }
}

@Composable
private fun Welcome(onNext: () -> Unit) {
    Column(Modifier.fillMaxSize().padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.weight(1f))
        LupaBars(96.dp)
        Spacer(Modifier.height(32.dp))
        Text(K.WELCOME_TITLE(), style = DS.title, textAlign = TextAlign.Center)
        Spacer(Modifier.height(12.dp))
        Text(K.WELCOME_SUB(), style = DS.body, textAlign = TextAlign.Center)
        Spacer(Modifier.weight(1f))
        PrimaryButton(K.START(), onClick = onNext)
    }
}

@Composable
private fun LangPicker(title: String, langs: List<Lang>, selected: String?, onPick: (String) -> Unit) {
    Column(Modifier.fillMaxSize().padding(horizontal = 24.dp)) {
        Spacer(Modifier.height(32.dp))
        Text(title, style = DS.title)
        Spacer(Modifier.height(20.dp))
        LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            items(langs, key = { it.code }) { l ->
                Row(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp))
                        .background(if (l.code == selected) DS.accentSoft else DS.raised)
                        .border(1.dp, if (l.code == selected) DS.accent else DS.line, RoundedCornerShape(14.dp))
                        .clickable { onPick(l.code) }.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(l.flag, fontSize = 26.sp)
                    Spacer(Modifier.padding(6.dp))
                    Text(l.nativeName, fontSize = 18.sp, fontWeight = FontWeight.Medium, color = DS.ink)
                }
            }
            item { Spacer(Modifier.height(24.dp)) }
        }
    }
}

@Composable
private fun NameStep(onNext: (String) -> Unit) {
    var name by rememberSaveable { mutableStateOf(Store.username) }
    Column(Modifier.fillMaxSize().padding(24.dp).imePadding()) {
        Spacer(Modifier.height(32.dp))
        Text(K.NAME_Q(), style = DS.title)
        Spacer(Modifier.height(20.dp))
        OutlinedTextField(
            value = name, onValueChange = { name = it.take(30) }, singleLine = true,
            placeholder = { Text(K.NAME_HINT()) },
            keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Words),
            shape = RoundedCornerShape(14.dp),
            colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = DS.accent, unfocusedBorderColor = DS.line,
                focusedContainerColor = DS.raised, unfocusedContainerColor = DS.raised),
            modifier = Modifier.fillMaxWidth(),
        )
        Spacer(Modifier.weight(1f))
        PrimaryButton(K.CONTINUE(), enabled = name.isNotBlank()) { onNext(name.trim()) }
    }
}

package app.wordrem.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import app.wordrem.android.billing.Billing
import app.wordrem.android.data.Store
import app.wordrem.android.reminders.Reminders
import app.wordrem.android.ui.DS
import app.wordrem.android.ui.HomeTabs
import app.wordrem.android.ui.OnboardingFlow
import app.wordrem.android.ui.PaywallScreen
import app.wordrem.android.ui.ReviewScreen
import app.wordrem.android.ui.VoiceTutorScreen
import app.wordrem.android.ui.WordRemTheme
import app.wordrem.android.voice.TutorMode

/** Uygulama içi gezinme: sekmeler + üstüne açılan tam ekranlar */
sealed interface Route {
    data class Voice(val mode: TutorMode) : Route
    data object Review : Route
    data object Paywall : Route
}

class Nav {
    val stack = mutableStateListOf<Route>()
    fun push(r: Route) { stack += r }
    fun pop() { if (stack.isNotEmpty()) stack.removeAt(stack.lastIndex) }
    fun replaceTop(r: Route) { pop(); push(r) }
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent { WordRemTheme { App() } }
    }
}

@Composable
private fun App() {
    val nav = remember { Nav() }
    val context = androidx.compose.ui.platform.LocalContext.current
    LaunchedEffect(Unit) { Billing.refresh() }
    // Bildirim izni (Android 13+) onboarding bittikten sonra istenir; hatırlatma uygulama her açıldığında yeniden kurulur
    val askNotify = androidx.activity.compose.rememberLauncherForActivityResult(
        androidx.activity.result.contract.ActivityResultContracts.RequestPermission()) { Reminders.schedule(context) }
    LaunchedEffect(Store.onboardingDone) {
        if (!Store.onboardingDone) return@LaunchedEffect
        Reminders.onAppOpen(context)
        if (android.os.Build.VERSION.SDK_INT >= 33 && androidx.core.content.ContextCompat.checkSelfPermission(context,
                android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
            askNotify.launch(android.Manifest.permission.POST_NOTIFICATIONS)
        }
    }
    Box(Modifier.fillMaxSize().background(DS.paper).safeDrawingPadding()) {
        if (!Store.onboardingDone) {
            OnboardingFlow()
            return@Box
        }
        HomeTabs(nav)
        nav.stack.lastOrNull()?.let { route ->
            BackHandler { nav.pop() }
            Box(Modifier.fillMaxSize().background(DS.paper)) {
                when (route) {
                    is Route.Voice -> VoiceTutorScreen(route.mode, nav)
                    Route.Review -> ReviewScreen(onClose = nav::pop)
                    Route.Paywall -> PaywallScreen(onClose = nav::pop)
                }
            }
        }
    }
}

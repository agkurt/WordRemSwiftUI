package app.wordrem.android.ui

import android.app.Activity
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.wordrem.android.billing.Billing
import app.wordrem.android.data.Store
import app.wordrem.android.i18n.K
import com.revenuecat.purchases.Package
import com.revenuecat.purchases.PackageType
import kotlinx.coroutines.launch

/** iOS OnboardingPaywallView'in sade hâli: dört fayda, plan seçimi, deneme notu, geri yükleme */
@Composable
fun PaywallScreen(onClose: () -> Unit) {
    val activity = LocalContext.current as Activity
    val scope = rememberCoroutineScope()
    var packages by remember { mutableStateOf<List<Package>?>(null) }
    var selected by remember { mutableStateOf<Package?>(null) }
    var busy by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) {
        if (Store.isPremium) { onClose(); return@LaunchedEffect }
        packages = Billing.packages().also { selected = it.firstOrNull() }
    }

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(24.dp)) {
        Row { Spacer(Modifier.weight(1f)); Text(K.NOT_NOW(), color = DS.muted, modifier = Modifier.clickable(onClick = onClose).padding(8.dp)) }
        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) { LupaBars(64.dp) }
        Spacer(Modifier.height(16.dp))
        Text(K.PAYWALL_TITLE(), style = DS.title, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
        Spacer(Modifier.height(20.dp))
        listOf(K.PF_TALK, K.PF_PLAN, K.PF_FIX, K.PF_REMEMBER).forEach {
            Row(Modifier.padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                Text("✓", color = DS.accent, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                Spacer(Modifier.width(12.dp))
                Text(it(), color = DS.ink, fontSize = 16.sp)
            }
        }
        Spacer(Modifier.height(20.dp))
        when {
            packages == null -> Box(Modifier.fillMaxWidth().padding(24.dp), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = DS.accent) }
            packages!!.isEmpty() -> Text(K.STORE_UNAVAILABLE(), style = DS.body, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
            else -> Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                packages!!.forEach { p -> PlanRow(p, p == selected) { selected = p } }
            }
        }
        Spacer(Modifier.height(14.dp))
        if (selected?.packageType == PackageType.ANNUAL) Text(K.TRIAL_NOTE(), fontSize = 13.sp, color = DS.muted, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
        error?.let { Text(it, color = DS.danger, fontSize = 13.sp, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) }
        Spacer(Modifier.height(14.dp))
        PrimaryButton(K.SUBSCRIBE(), enabled = selected != null && !busy, color = DS.accent) {
            val pkg = selected ?: return@PrimaryButton
            busy = true; error = null
            scope.launch {
                runCatching { Billing.purchase(activity, pkg) }
                    .onSuccess { if (it) onClose() }
                    .onFailure { error = it.message }
                busy = false
            }
        }
        SecondaryButton(K.RESTORE()) {
            scope.launch { if (runCatching { Billing.restore() }.getOrDefault(false)) onClose() }
        }
    }
}

@Composable
private fun PlanRow(p: Package, selected: Boolean, onClick: () -> Unit) {
    val label = when (p.packageType) {
        PackageType.ANNUAL -> K.YEARLY()
        PackageType.MONTHLY -> K.MONTHLY()
        PackageType.WEEKLY -> K.WEEKLY()
        else -> p.product.title
    }
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(if (selected) DS.accentSoft else DS.raised)
            .border(if (selected) 2.dp else 1.dp, if (selected) DS.accent else DS.line, RoundedCornerShape(14.dp))
            .clickable(onClick = onClick).padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Text(label, fontWeight = FontWeight.SemiBold, color = DS.ink, fontSize = 17.sp)
            if (p.packageType == PackageType.ANNUAL) Text(K.BEST_VALUE(), color = DS.accent, fontSize = 12.sp, fontWeight = FontWeight.Bold)
        }
        Text(p.product.price.formatted, fontWeight = FontWeight.SemiBold, color = DS.ink)
    }
}

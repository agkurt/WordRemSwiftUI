package app.wordrem.android.ui

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** iOS DesignSystem (DS) renkleri: kâğıt + mürekkep + terrakota vurgu, her zaman açık tema */
object DS {
    val paper = Color(0xFFF6F2EA)
    val raised = Color(0xFFFFFDF8)
    val sunken = Color(0xFFEFE9DE)
    val line = Color(0xFFE4DDD0)
    val ink = Color(0xFF1C1A17)
    val inkSoft = Color(0xFF4A453E)
    val muted = Color(0xFF8A8277)
    val accent = Color(0xFFC2512F)
    val accentDeep = Color(0xFF9E3F22)
    val accentSoft = Color(0xFFF3E2D8)
    val slate = Color(0xFF2F4B5C)
    val success = Color(0xFF3F7D58)
    val danger = Color(0xFFB4423A)
    val gold = Color(0xFFC8962E)

    val title = TextStyle(fontFamily = FontFamily.Serif, fontWeight = FontWeight.SemiBold, fontSize = 28.sp, color = ink, lineHeight = 34.sp)
    val heading = TextStyle(fontFamily = FontFamily.Serif, fontWeight = FontWeight.SemiBold, fontSize = 21.sp, color = ink)
    val body = TextStyle(fontSize = 16.sp, color = inkSoft, lineHeight = 22.sp)
    val eyebrow = TextStyle(fontSize = 11.sp, fontWeight = FontWeight.Bold, color = muted, letterSpacing = 1.2.sp)
}

@Composable
fun WordRemTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = lightColorScheme(
            primary = DS.accent, onPrimary = Color.White, background = DS.paper, surface = DS.raised,
            onBackground = DS.ink, onSurface = DS.ink, secondary = DS.slate,
        ),
        content = content,
    )
}

@Composable
fun Card(modifier: Modifier = Modifier, onClick: (() -> Unit)? = null, color: Color = DS.raised, content: @Composable ColumnScope.() -> Unit) {
    Column(
        modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(color)
            .border(1.dp, DS.line, RoundedCornerShape(18.dp))
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(18.dp),
        content = content,
    )
}

@Composable
fun PrimaryButton(text: String, modifier: Modifier = Modifier, enabled: Boolean = true, color: Color = DS.ink, onClick: () -> Unit) {
    Box(
        modifier
            .fillMaxWidth()
            .height(54.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(if (enabled) color else DS.line)
            .clickable(enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) { Text(text, color = if (enabled) Color.White else DS.muted, fontWeight = FontWeight.SemiBold, fontSize = 17.sp) }
}

@Composable
fun SecondaryButton(text: String, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Box(
        modifier
            .fillMaxWidth()
            .height(50.dp)
            .clip(RoundedCornerShape(14.dp))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) { Text(text, color = DS.inkSoft, fontWeight = FontWeight.Medium, fontSize = 16.sp) }
}

/** Lupa'nın simgesi (iOS VoiceLogoView): dört hareketli kapsül çubuk */
@Composable
fun LupaBars(size: Dp = 64.dp, active: Boolean = true) {
    val tr = rememberInfiniteTransition(label = "lupa")
    val colors = listOf(DS.ink, DS.accent, DS.slate, DS.accent)
    Row(horizontalArrangement = Arrangement.spacedBy(size / 10), verticalAlignment = Alignment.CenterVertically, modifier = Modifier.height(size)) {
        colors.forEachIndexed { i, c ->
            val h by tr.animateFloat(
                initialValue = 0.35f, targetValue = if (active) 1f else 0.4f,
                animationSpec = infiniteRepeatable(tween(520 + i * 130), RepeatMode.Reverse), label = "bar$i",
            )
            Box(Modifier.width(size / 7).height(size * h).clip(RoundedCornerShape(50)).background(c))
        }
    }
}

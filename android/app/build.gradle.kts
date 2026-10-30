import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

// Gizli değerler android/secrets.properties'ten okunur (git'e girmez).
// Yoksa ses sunucusu anahtarı iOS'un Info.plist'inden alınır (tek kaynak).
val secrets = Properties().apply {
    val f = rootProject.file("secrets.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
fun plistValue(key: String): String {
    val plist = rootProject.file("../WordRemSwiftUI/Info.plist")
    if (!plist.exists()) return ""
    val m = Regex("<key>$key</key>\\s*<string>([^<]*)</string>").find(plist.readText())
    return m?.groupValues?.get(1) ?: ""
}
fun secret(key: String, plistKey: String? = null): String =
    secrets.getProperty(key) ?: plistKey?.let { plistValue(it) } ?: ""

// google-services.json eklenince Firebase Analytics açılır
if (file("google-services.json").exists()) apply(plugin = "com.google.gms.google-services")

android {
    namespace = "app.wordrem.android"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.twinflare.wordrem"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"

        buildConfigField("String", "VOICE_API_BASE_URL", "\"${secret("voice.baseUrl", "VoiceAPIBaseURL").ifEmpty { "https://api.wordremai.app" }}\"")
        buildConfigField("String", "VOICE_APP_KEY", "\"${secret("voice.appKey", "VoiceAppKey")}\"")
        buildConfigField("String", "REVENUECAT_API_KEY", "\"${secret("revenuecat.googleApiKey")}\"")
        buildConfigField("String", "RC_ENTITLEMENT", "\"${secrets.getProperty("revenuecat.entitlement") ?: "pro"}\"")
    }

    signingConfigs {
        create("release") {
            val ks = secrets.getProperty("release.storeFile")
            if (ks != null) {
                storeFile = rootProject.file(ks)
                storePassword = secrets.getProperty("release.storePassword")
                keyAlias = secrets.getProperty("release.keyAlias")
                keyPassword = secrets.getProperty("release.keyPassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            if (secrets.getProperty("release.storeFile") != null) signingConfig = signingConfigs.getByName("release")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlin { jvmToolchain(17) }
    sourceSets["main"].assets.srcDir(layout.buildDirectory.dir("generated/wordrem-assets"))
    buildFeatures {
        compose = true
        buildConfig = true
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2025.06.01")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.9.1")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.9.1")
    implementation("androidx.core:core-ktx:1.16.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.revenuecat.purchases:purchases:9.1.0")
    debugImplementation("androidx.compose.ui:ui-tooling")
}

// Ders içeriği iOS ile aynı dosyalardan gelir (tek kaynak): WordRemSwiftUI/Resources
val copyContent by tasks.registering(Copy::class) {
    from(rootProject.file("../WordRemSwiftUI/Resources")) { include("content.json", "scenarios.json") }
    into(layout.buildDirectory.dir("generated/wordrem-assets"))
}
tasks.named("preBuild") { dependsOn(copyContent) }

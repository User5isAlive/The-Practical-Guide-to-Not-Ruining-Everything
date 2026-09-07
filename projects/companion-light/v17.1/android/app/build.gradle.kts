// CC0-1.0 — minimal. VERIFY versions.
plugins { id("com.android.application"); id("org.jetbrains.kotlin.android"); id("org.jetbrains.kotlin.plugin.compose") }
android {
    namespace = "org.memoryalpha.companion"; compileSdk = 35
    defaultConfig { applicationId = "org.memoryalpha.companion"; minSdk = 31; targetSdk = 35 }
    buildFeatures { compose = true }
}
dependencies {
    implementation("androidx.activity:activity-compose:1.9.3")
    implementation("androidx.compose.material3:material3:1.3.1")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.work:work-runtime-ktx:2.10.0")       // the fold, charging + idle
    implementation("androidx.security:security-crypto:1.1.0-alpha06")   // BYOK keys
    // implementation("com.google.ai.edge.litertlm:litertlm-android:<VERIFY>")   // option A
    // implementation("<llama.cpp android binding>")                            // option B
}

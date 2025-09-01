// Root build script (Kotlin DSL) to patch 3P Android library namespaces when missing (AGP 8+)
// This helps older plugins like isar_flutter_libs define a namespace under AGP 8+.

import com.android.build.gradle.LibraryExtension
import org.gradle.api.JavaVersion

subprojects {
    // Only care about Android library modules
    plugins.withId("com.android.library") {
        // Try using typed extension first (AGP 8+)
        extensions.findByType(LibraryExtension::class.java)?.apply {
            compileSdk = 34
            defaultConfig { minSdk = 21 }
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_11
                targetCompatibility = JavaVersion.VERSION_11
            }
            if (project.name.contains("isar_flutter_libs") && namespace == null) {
                namespace = "dev.isar.isar_flutter_libs"
            }
        }
        // Fallback for older AGP on plugin subprojects (e.g., isar_flutter_libs)
        afterEvaluate {
            if (project.name.contains("isar_flutter_libs")) {
                val androidExt = extensions.findByName("android")
                if (androidExt != null) {
                    try {
                        val m = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.java)
                        m.invoke(androidExt, 34)
                    } catch (_: Throwable) {}
                    try {
                        val dc = androidExt.javaClass.getMethod("getDefaultConfig").invoke(androidExt)
                        val ms = dc.javaClass.methods.firstOrNull { it.name == "setMinSdkVersion" }
                        ms?.invoke(dc, 21)
                    } catch (_: Throwable) {}
                }
            }
        }
    }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mindtamer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Required for some libraries (e.g., flutter_local_notifications)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.mindtamer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring support for Java 8+ APIs on older Android
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

// Ensure Flutter CLI can find APKs where it expects (projectRoot/build/app/outputs/flutter-apk)
val projectRootDir = rootProject.rootDir.parentFile
val flutterOutDir = file(File(projectRootDir, "build/app/outputs/flutter-apk"))

tasks.register<Copy>("copyDebugApkToProjectRoot") {
    val src = layout.buildDirectory.file("outputs/flutter-apk/app-debug.apk")
    from(src)
    into(flutterOutDir)
    doFirst { flutterOutDir.mkdirs() }
}

tasks.register<Copy>("copyReleaseApkToProjectRoot") {
    val src = layout.buildDirectory.file("outputs/flutter-apk/app-release.apk")
    from(src)
    into(flutterOutDir)
    doFirst { flutterOutDir.mkdirs() }
}

afterEvaluate {
    tasks.findByName("assembleDebug")?.finalizedBy("copyDebugApkToProjectRoot")
    tasks.findByName("assembleRelease")?.finalizedBy("copyReleaseApkToProjectRoot")
}

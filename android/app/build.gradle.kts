plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.cs2tracker.cs2_tracker"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Necesario para que flutter_local_notifications use zonedSchedule en APIs antiguas.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.cs2tracker.cs2_tracker"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Firma con debug keys para que `flutter run --release` funcione en local.
            signingConfig = signingConfigs.getByName("debug")
            // Reglas ProGuard para preservar los generic types que
            // flutter_local_notifications necesita al restaurar notificaciones
            // programadas desde SharedPreferences.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.easyconnect"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.easyconnect.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 21  // Android 5.0 (Lollipop) - Supporte la plupart des appareils
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Support de toutes les architectures CPU pour compatibilité maximale
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64"))
        }
    }

    // Configuration des splits ABI pour créer un APK universel
    splits {
        abi {
            isEnable = false  // Désactivé pour créer un APK universel (fat APK)
            reset()
            // Si vous voulez créer des APK séparés par architecture, décommentez:
            // include("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
            // isUniversalApk = true  // Crée aussi un APK universel
        }
    }

    buildTypes {
        release {
            // Configuration de signature temporairement désactivée pour les tests
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Lowest Android API the app supports. Flutter's own default is 24 (Android
// 7.0); the image_picker plugin also currently requires 24, so this can't go
// lower without changing that dependency. Held in a local so `flutter build`'s
// gradle migration doesn't rewrite the literal.
val legacyDeviceMinSdk = 24

// Release signing details, read from android/key.properties (never committed).
// When that file is absent (e.g. a fresh checkout), release builds fall back to
// the debug key so `flutter run --release` still works.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.mobile_app_for_model"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Unique, non-"com.example" application id. Some devices and Play
        // Protect reject the default example id outright ("App not installed").
        applicationId = "com.jaguza.cattleweight"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = legacyDeviceMinSdk
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        getByName("debug") {
            // Keep the legacy JAR (v1) signature alongside v2/v3 so the APK
            // verifies on the widest range of Android versions.
            enableV1Signing = true
            enableV2Signing = true
        }
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
            enableV1Signing = true
            enableV2Signing = true
        }
    }

    buildTypes {
        release {
            // Use the real release key when key.properties is present, otherwise
            // fall back to the debug key so the build still succeeds.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

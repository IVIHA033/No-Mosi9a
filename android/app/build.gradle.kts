plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nomosi9a.app"
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
        applicationId = "com.nomosi9a.app"
        // Android 10 is the first version that lets an app capture the audio
        // of other apps (AudioPlaybackCapture), so nothing below it can work.
        minSdk = 29
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    androidResources {
        // Models are memory-mapped straight from the APK; keep them uncompressed.
        noCompress += listOf("onnx")
    }

    packaging {
        // Compress native libraries inside the APK: ONNX Runtime alone is ~30 MB
        // uncompressed, so this roughly halves the download size.
        jniLibs.useLegacyPackaging = true
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            // Replace with your own keystore before sharing the APK widely.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
    }
}

dependencies {
    // On-device neural network runtime (MIT). Runs the speech model, no internet needed.
    implementation("com.microsoft.onnxruntime:onnxruntime-android:1.30.0")
    // Lets us reach ServiceManager to read the audio session list (Apache-2.0).
    implementation("org.lsposed.hiddenapibypass:hiddenapibypass:6.1")
    // Optional one-tap setup without a computer (Apache-2.0).
    implementation("dev.rikka.shizuku:api:13.1.5")
    implementation("dev.rikka.shizuku:provider:13.1.5")

    testImplementation("junit:junit:4.13.2")
}

flutter {
    source = "../.."
}

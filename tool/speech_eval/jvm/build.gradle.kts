// Runs the app's engine classes (the real Kotlin sources) on a desktop JVM with the desktop
// ONNX Runtime, for parity.py. Build: ../../../android/gradlew -p . installDist
plugins {
    kotlin("jvm") version "2.2.20"
    application
}

repositories { mavenCentral() }

dependencies { implementation("com.microsoft.onnxruntime:onnxruntime:1.30.0") }

kotlin { jvmToolchain(17) }

val engine = "../../../android/app/src/main/kotlin/com/nomosi9a/app/engine"
sourceSets["main"].kotlin.setSrcDirs(listOf("src", engine))
sourceSets["main"].kotlin.include(
    "Harness.kt", "dsp/Fft.kt", "dsp/Stft.kt", "dsp/Decimator.kt",
    "Denoiser.kt", "DpdfnetDenoiser.kt", "SileroVad.kt", "SpeechGuard.kt",
)

application { mainClass.set("HarnessKt") }

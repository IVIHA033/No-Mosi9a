package com.nomosi9a.app.engine

/**
 * A streaming "keep the voice, drop everything else" processor.
 *
 * Audio is pushed one hop at a time (10 ms). Implementations keep whatever
 * state they need between calls and must not allocate inside [process]:
 * it runs on the real-time audio thread 100 times per second.
 */
interface Denoiser : AutoCloseable {
    val sampleRate: Int
    val hopSize: Int

    /** How far the output lags behind the input, in samples. */
    val latencySamples: Int

    /** [input] and [output] are both [hopSize] mono samples in -1..1. */
    fun process(input: FloatArray, output: FloatArray)

    /** Forget all history (used after long silences or a stream restart). */
    fun reset()

    /** Word-cut protection, when this denoiser has one. */
    val guard: SpeechGuard?
        get() = null
}

/** The bundled speech models, from best sound to lightest on the battery. */
enum class ModelSpec(val id: String, val asset: String) {
    /** 48 kHz full-band DPDFNet-2: best music removal and natural voice. */
    FULL("full", "models/dpdfnet2_48k.onnx"),

    /** 16 kHz DPDFNet-2: the same removal power at phone-call bandwidth, ~1.5x cheaper. */
    BALANCED("balanced", "models/dpdfnet2_16k.onnx"),

    /** 16 kHz DPDFNet baseline: ~4x cheaper than full, removes a bit less music. */
    LIGHT("light", "models/dpdfnet_16k.onnx");

    companion object {
        fun fromId(id: String?): ModelSpec? = entries.firstOrNull { it.id == id }
    }
}

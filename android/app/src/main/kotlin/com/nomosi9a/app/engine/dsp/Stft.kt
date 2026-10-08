package com.nomosi9a.app.engine.dsp

import kotlin.math.PI
import kotlin.math.sin

/** Works on one spectrum frame: `re/im` hold [StreamingStft.bins] values, edited in place. */
fun interface SpectrumFilter {
    fun filter(re: FloatArray, im: FloatArray)
}

/**
 * Causal streaming STFT -> filter -> inverse STFT with overlap-add.
 *
 * Window length = 2 x hop with a Vorbis window, which satisfies
 * w[n]^2 + w[n + hop]^2 = 1, so analysis+synthesis windowing reconstructs the
 * input exactly (delayed by `window - hop` samples) when the filter is identity.
 * This matches the DeepFilterNet/DPDFNet front-end.
 */
class StreamingStft(val windowSize: Int, private val filter: SpectrumFilter) {
    val hopSize = windowSize / 2
    val bins = windowSize / 2 + 1

    /** Delay added by framing alone (the model may add more on top). */
    val framingDelay = windowSize - hopSize

    private val window = vorbisWindow(windowSize)
    private val fft = RealFft(windowSize)
    private val history = FloatArray(windowSize - hopSize)
    private val frame = FloatArray(windowSize)
    private val re = FloatArray(bins)
    private val im = FloatArray(bins)
    private val synth = FloatArray(windowSize)
    private val overlap = FloatArray(windowSize)

    init {
        require(windowSize % 2 == 0) { "window must be even" }
    }

    fun process(input: FloatArray, output: FloatArray) {
        val keep = windowSize - hopSize
        System.arraycopy(history, 0, frame, 0, keep)
        System.arraycopy(input, 0, frame, keep, hopSize)
        System.arraycopy(frame, hopSize, history, 0, keep)
        for (n in 0 until windowSize) frame[n] *= window[n]

        fft.forward(frame, re, im)
        filter.filter(re, im)
        fft.inverse(re, im, synth)

        for (n in 0 until windowSize) overlap[n] += synth[n] * window[n]
        System.arraycopy(overlap, 0, output, 0, hopSize)
        System.arraycopy(overlap, hopSize, overlap, 0, windowSize - hopSize)
        overlap.fill(0f, windowSize - hopSize, windowSize)
    }

    fun reset() {
        history.fill(0f)
        overlap.fill(0f)
    }

    companion object {
        fun vorbisWindow(size: Int): FloatArray {
            val half = size / 2.0
            return FloatArray(size) { i ->
                val s = sin(0.5 * PI * (i + 0.5) / half)
                sin(0.5 * PI * s * s).toFloat()
            }
        }
    }
}

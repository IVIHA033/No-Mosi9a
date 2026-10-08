package com.nomosi9a.app.engine.dsp

import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

/**
 * Integer-factor downsampler (48 kHz -> 16 kHz for the speech detector):
 * a causal 63-tap Blackman-windowed sinc low-pass, evaluated only at the kept
 * samples. Accepts blocks of up to [maxBlock] samples and never allocates.
 */
class Decimator(val factor: Int, private val maxBlock: Int) {

    private val taps: FloatArray = lowpass(TAPS, CUTOFF_HZ / 48_000.0)
    private val buffer = FloatArray(TAPS - 1 + maxBlock)
    private var phase = 0

    init {
        require(factor >= 1)
    }

    /** Filters [count] samples of [input] into [output]; returns how many were written. */
    fun process(input: FloatArray, count: Int, output: FloatArray): Int {
        require(count <= maxBlock)
        if (factor == 1) {
            System.arraycopy(input, 0, output, 0, count)
            return count
        }
        val history = TAPS - 1
        System.arraycopy(input, 0, buffer, history, count)
        var written = 0
        var i = phase
        while (i < count) {
            // y = sum_k h[k] * x[n - k], with x[n] at buffer[i + history]
            var acc = 0f
            val newest = i + history
            for (k in 0 until TAPS) acc += taps[k] * buffer[newest - k]
            output[written++] = acc
            i += factor
        }
        phase = i - count
        System.arraycopy(buffer, count, buffer, 0, history)
        return written
    }

    fun reset() {
        buffer.fill(0f)
        phase = 0
    }

    companion object {
        const val TAPS = 63
        private const val CUTOFF_HZ = 7_200.0

        /** Same coefficients as tool/speech_eval/guard.py (numpy sinc and blackman). */
        fun lowpass(n: Int, cutoff: Double): FloatArray {
            val h = DoubleArray(n) { i ->
                val m = i - (n - 1) / 2.0
                val x = 2 * cutoff * m
                val sinc = if (x == 0.0) 1.0 else sin(PI * x) / (PI * x)
                val blackman = 0.42 - 0.5 * cos(2 * PI * i / (n - 1)) + 0.08 * cos(4 * PI * i / (n - 1))
                2 * cutoff * sinc * blackman
            }
            val sum = h.sum()
            return FloatArray(n) { (h[it] / sum).toFloat() }
        }
    }
}

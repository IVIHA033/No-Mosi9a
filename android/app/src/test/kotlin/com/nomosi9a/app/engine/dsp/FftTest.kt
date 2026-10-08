package com.nomosi9a.app.engine.dsp

import org.junit.Assert.assertEquals
import org.junit.Test
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin
import kotlin.random.Random

class FftTest {

    private fun naiveDft(re: FloatArray, im: FloatArray, inverse: Boolean): Pair<DoubleArray, DoubleArray> {
        val n = re.size
        val outRe = DoubleArray(n)
        val outIm = DoubleArray(n)
        val sign = if (inverse) 1.0 else -1.0
        for (k in 0 until n) {
            var sr = 0.0
            var si = 0.0
            for (t in 0 until n) {
                val a = sign * 2.0 * PI * k * t / n
                sr += re[t] * cos(a) - im[t] * sin(a)
                si += re[t] * sin(a) + im[t] * cos(a)
            }
            outRe[k] = sr
            outIm[k] = si
        }
        return outRe to outIm
    }

    private fun check(n: Int, inverse: Boolean) {
        val rnd = Random(n * 31 + if (inverse) 1 else 0)
        val re = FloatArray(n) { rnd.nextFloat() * 2 - 1 }
        val im = FloatArray(n) { rnd.nextFloat() * 2 - 1 }
        val outRe = FloatArray(n)
        val outIm = FloatArray(n)
        Fft(n, inverse).transform(re, im, outRe, outIm)
        val (expRe, expIm) = naiveDft(re, im, inverse)
        var err = 0.0
        for (k in 0 until n) {
            err = max(err, abs(outRe[k] - expRe[k]))
            err = max(err, abs(outIm[k] - expIm[k]))
        }
        assertEquals("n=$n inverse=$inverse", 0.0, err, 2e-3 * kotlin.math.sqrt(n.toDouble()))
    }

    @Test
    fun matchesNaiveDftForModelSizes() {
        for (n in listOf(960, 320)) {
            check(n, inverse = false)
            check(n, inverse = true)
        }
    }

    @Test
    fun matchesNaiveDftForEveryRadix() {
        // 4, 2, 3, 5 butterflies and the generic one (7, 11).
        for (n in listOf(1, 2, 3, 4, 5, 6, 7, 8, 12, 15, 16, 30, 49, 60, 77, 128, 240)) {
            check(n, inverse = false)
            check(n, inverse = true)
        }
    }

    @Test
    fun realFftRoundTrip() {
        for (n in listOf(960, 320)) {
            val fft = RealFft(n)
            val rnd = Random(n)
            val x = FloatArray(n) { rnd.nextFloat() * 2 - 1 }
            val re = FloatArray(fft.bins)
            val im = FloatArray(fft.bins)
            val y = FloatArray(n)
            fft.forward(x, re, im)
            fft.inverse(re, im, y)
            for (i in 0 until n) assertEquals(x[i], y[i], 1e-4f)
        }
    }

    @Test
    fun streamingStftIsTransparentWithIdentityFilter() {
        for (window in listOf(960, 320)) {
            val stft = StreamingStft(window) { _, _ -> }
            val hop = stft.hopSize
            val rnd = Random(window)
            val total = hop * 40
            val x = FloatArray(total) { rnd.nextFloat() * 2 - 1 }
            val y = FloatArray(total)
            val inBuf = FloatArray(hop)
            val outBuf = FloatArray(hop)
            for (f in 0 until total / hop) {
                System.arraycopy(x, f * hop, inBuf, 0, hop)
                stft.process(inBuf, outBuf)
                System.arraycopy(outBuf, 0, y, f * hop, hop)
            }
            val d = stft.framingDelay
            // Skip the first frame (window ramp-up), then output == input delayed by d.
            for (i in window until total) assertEquals("window=$window i=$i", x[i - d], y[i], 1e-4f)
        }
    }
}

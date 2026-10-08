package com.nomosi9a.app.engine.dsp

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.sin
import kotlin.math.sqrt
import kotlin.random.Random

class DecimatorTest {

    /** Streaming in hops must equal filtering the whole signal at once and keeping every 3rd sample. */
    @Test
    fun streamingMatchesDirectFilter() {
        val rnd = Random(3)
        val x = FloatArray(480 * 20) { rnd.nextFloat() * 2 - 1 }
        val taps = Decimator.lowpass(Decimator.TAPS, 7_200.0 / 48_000.0)
        val expected = ArrayList<Float>()
        for (n in x.indices step 3) {
            var acc = 0.0
            for (k in taps.indices) if (n - k >= 0) acc += taps[k] * x[n - k]
            expected += acc.toFloat()
        }
        val d = Decimator(3, 480)
        val out = FloatArray(480)
        val got = ArrayList<Float>()
        for (h in 0 until 20) {
            val n = d.process(x.copyOfRange(h * 480, (h + 1) * 480), 480, out)
            for (i in 0 until n) got += out[i]
        }
        assertEquals(expected.size, got.size)
        for (i in expected.indices) assertEquals(expected[i], got[i], 1e-5f)
    }

    /** Hops that are not a multiple of the factor keep the phase across calls. */
    @Test
    fun oddBlockSizesKeepPhase() {
        val x = FloatArray(3000) { sin(2 * PI * 440 * it / 48_000.0).toFloat() }
        val whole = FloatArray(1000)
        val a = Decimator(3, 3000)
        assertEquals(1000, a.process(x, 3000, whole))
        val b = Decimator(3, 500)
        val part = FloatArray(500)
        val got = ArrayList<Float>()
        var pos = 0
        for (size in intArrayOf(161, 500, 7, 332, 500, 500, 500, 500)) {
            val n = b.process(x.copyOfRange(pos, pos + size), size, part)
            for (i in 0 until n) got += part[i]
            pos += size
        }
        assertEquals(1000, got.size)
        for (i in 0 until 1000) assertEquals(whole[i], got[i], 1e-6f)
    }

    /** Speech band passes, content above the new Nyquist (8 kHz) is strongly attenuated. */
    @Test
    fun passesSpeechRejectsAliases() {
        fun gain(hz: Double): Double {
            val d = Decimator(3, 4800)
            val x = FloatArray(4800) { sin(2 * PI * hz * it / 48_000.0).toFloat() }
            val y = FloatArray(1600)
            d.process(x, 4800, y)
            val tail = y.copyOfRange(100, 1600)
            return sqrt(tail.sumOf { (it * it).toDouble() } / tail.size) * sqrt(2.0)
        }
        assertTrue(abs(gain(1_000.0) - 1) < 0.01)
        assertTrue(abs(gain(4_000.0) - 1) < 0.02)
        assertTrue(gain(12_000.0) < 0.01)
    }
}

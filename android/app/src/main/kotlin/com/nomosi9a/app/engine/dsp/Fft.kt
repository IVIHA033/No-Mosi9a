package com.nomosi9a.app.engine.dsp

import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Mixed-radix complex FFT (radix 2/3/4/5 + generic), a Kotlin port of the
 * KissFFT algorithm (BSD-3-Clause, Mark Borgerding).
 *
 * The speech models use frame sizes like 960 and 320 (not powers of two), so a
 * plain radix-2 FFT is not enough. Everything is preallocated: [transform]
 * never allocates, which matters because it runs 100 times per second on the
 * audio thread.
 *
 * No scaling is applied in either direction.
 */
class Fft(val size: Int, private val inverse: Boolean = false) {

    private val twRe = FloatArray(size)
    private val twIm = FloatArray(size)
    private val factors: IntArray
    private val scratchRe = FloatArray(size)
    private val scratchIm = FloatArray(size)

    init {
        require(size > 0)
        val sign = if (inverse) 1.0 else -1.0
        for (i in 0 until size) {
            val phase = sign * 2.0 * PI * i / size
            twRe[i] = cos(phase).toFloat()
            twIm[i] = sin(phase).toFloat()
        }
        factors = factor(size)
    }

    /**
     * Transforms (inRe, inIm) into (outRe, outIm). Input and output must be
     * different arrays of length [size].
     */
    fun transform(inRe: FloatArray, inIm: FloatArray, outRe: FloatArray, outIm: FloatArray) {
        work(outRe, outIm, 0, inRe, inIm, 0, 1, 0)
    }

    private fun work(
        oRe: FloatArray, oIm: FloatArray, oOff: Int,
        iRe: FloatArray, iIm: FloatArray, iOff: Int,
        fstride: Int, fIdx: Int,
    ) {
        val p = factors[fIdx]
        val m = factors[fIdx + 1]
        val end = oOff + p * m
        var o = oOff
        var f = iOff
        if (m == 1) {
            while (o < end) {
                oRe[o] = iRe[f]
                oIm[o] = iIm[f]
                f += fstride
                o++
            }
        } else {
            while (o < end) {
                work(oRe, oIm, o, iRe, iIm, f, fstride * p, fIdx + 2)
                f += fstride
                o += m
            }
        }
        when (p) {
            2 -> bfly2(oRe, oIm, oOff, fstride, m)
            3 -> bfly3(oRe, oIm, oOff, fstride, m)
            4 -> bfly4(oRe, oIm, oOff, fstride, m)
            5 -> bfly5(oRe, oIm, oOff, fstride, m)
            else -> bflyGeneric(oRe, oIm, oOff, fstride, m, p)
        }
    }

    private fun bfly2(re: FloatArray, im: FloatArray, off: Int, fstride: Int, m: Int) {
        var tw = 0
        for (k in 0 until m) {
            val a = off + k
            val b = a + m
            val tr = re[b] * twRe[tw] - im[b] * twIm[tw]
            val ti = re[b] * twIm[tw] + im[b] * twRe[tw]
            re[b] = re[a] - tr
            im[b] = im[a] - ti
            re[a] += tr
            im[a] += ti
            tw += fstride
        }
    }

    private fun bfly3(re: FloatArray, im: FloatArray, off: Int, fstride: Int, m: Int) {
        val epi3i = twIm[fstride * m]
        var tw1 = 0
        var tw2 = 0
        for (k in 0 until m) {
            val a = off + k
            val b = a + m
            val c = a + 2 * m
            val s1r = re[b] * twRe[tw1] - im[b] * twIm[tw1]
            val s1i = re[b] * twIm[tw1] + im[b] * twRe[tw1]
            val s2r = re[c] * twRe[tw2] - im[c] * twIm[tw2]
            val s2i = re[c] * twIm[tw2] + im[c] * twRe[tw2]
            val s3r = s1r + s2r
            val s3i = s1i + s2i
            var s0r = s1r - s2r
            var s0i = s1i - s2i
            tw1 += fstride
            tw2 += fstride * 2
            re[b] = re[a] - 0.5f * s3r
            im[b] = im[a] - 0.5f * s3i
            s0r *= epi3i
            s0i *= epi3i
            re[a] += s3r
            im[a] += s3i
            re[c] = re[b] + s0i
            im[c] = im[b] - s0r
            re[b] -= s0i
            im[b] += s0r
        }
    }

    private fun bfly4(re: FloatArray, im: FloatArray, off: Int, fstride: Int, m: Int) {
        var tw1 = 0
        var tw2 = 0
        var tw3 = 0
        for (k in 0 until m) {
            val a = off + k
            val b = a + m
            val c = a + 2 * m
            val d = a + 3 * m
            val s0r = re[b] * twRe[tw1] - im[b] * twIm[tw1]
            val s0i = re[b] * twIm[tw1] + im[b] * twRe[tw1]
            val s1r = re[c] * twRe[tw2] - im[c] * twIm[tw2]
            val s1i = re[c] * twIm[tw2] + im[c] * twRe[tw2]
            val s2r = re[d] * twRe[tw3] - im[d] * twIm[tw3]
            val s2i = re[d] * twIm[tw3] + im[d] * twRe[tw3]
            val s5r = re[a] - s1r
            val s5i = im[a] - s1i
            re[a] += s1r
            im[a] += s1i
            val s3r = s0r + s2r
            val s3i = s0i + s2i
            val s4r = s0r - s2r
            val s4i = s0i - s2i
            re[c] = re[a] - s3r
            im[c] = im[a] - s3i
            tw1 += fstride
            tw2 += fstride * 2
            tw3 += fstride * 3
            re[a] += s3r
            im[a] += s3i
            if (inverse) {
                re[b] = s5r - s4i
                im[b] = s5i + s4r
                re[d] = s5r + s4i
                im[d] = s5i - s4r
            } else {
                re[b] = s5r + s4i
                im[b] = s5i - s4r
                re[d] = s5r - s4i
                im[d] = s5i + s4r
            }
        }
    }

    private fun bfly5(re: FloatArray, im: FloatArray, off: Int, fstride: Int, m: Int) {
        val yaR = twRe[fstride * m]
        val yaI = twIm[fstride * m]
        val ybR = twRe[fstride * 2 * m]
        val ybI = twIm[fstride * 2 * m]
        for (u in 0 until m) {
            val i0 = off + u
            val i1 = i0 + m
            val i2 = i0 + 2 * m
            val i3 = i0 + 3 * m
            val i4 = i0 + 4 * m
            val s0r = re[i0]
            val s0i = im[i0]
            val t1 = u * fstride
            val t2 = 2 * u * fstride
            val t3 = 3 * u * fstride
            val t4 = 4 * u * fstride
            val s1r = re[i1] * twRe[t1] - im[i1] * twIm[t1]
            val s1i = re[i1] * twIm[t1] + im[i1] * twRe[t1]
            val s2r = re[i2] * twRe[t2] - im[i2] * twIm[t2]
            val s2i = re[i2] * twIm[t2] + im[i2] * twRe[t2]
            val s3r = re[i3] * twRe[t3] - im[i3] * twIm[t3]
            val s3i = re[i3] * twIm[t3] + im[i3] * twRe[t3]
            val s4r = re[i4] * twRe[t4] - im[i4] * twIm[t4]
            val s4i = re[i4] * twIm[t4] + im[i4] * twRe[t4]

            val s7r = s1r + s4r
            val s7i = s1i + s4i
            val s10r = s1r - s4r
            val s10i = s1i - s4i
            val s8r = s2r + s3r
            val s8i = s2i + s3i
            val s9r = s2r - s3r
            val s9i = s2i - s3i

            re[i0] = s0r + s7r + s8r
            im[i0] = s0i + s7i + s8i

            val s5r = s0r + s7r * yaR + s8r * ybR
            val s5i = s0i + s7i * yaR + s8i * ybR
            val s6r = s10i * yaI + s9i * ybI
            val s6i = -s10r * yaI - s9r * ybI

            re[i1] = s5r - s6r
            im[i1] = s5i - s6i
            re[i4] = s5r + s6r
            im[i4] = s5i + s6i

            val s11r = s0r + s7r * ybR + s8r * yaR
            val s11i = s0i + s7i * ybR + s8i * yaR
            val s12r = -s10i * ybI + s9i * yaI
            val s12i = s10r * ybI - s9r * yaI

            re[i2] = s11r + s12r
            im[i2] = s11i + s12i
            re[i3] = s11r - s12r
            im[i3] = s11i - s12i
        }
    }

    private fun bflyGeneric(re: FloatArray, im: FloatArray, off: Int, fstride: Int, m: Int, p: Int) {
        for (u in 0 until m) {
            var k = u
            for (q1 in 0 until p) {
                scratchRe[q1] = re[off + k]
                scratchIm[q1] = im[off + k]
                k += m
            }
            k = u
            for (q1 in 0 until p) {
                var twIdx = 0
                var accR = scratchRe[0]
                var accI = scratchIm[0]
                for (q in 1 until p) {
                    twIdx += fstride * k
                    if (twIdx >= size) twIdx -= size
                    accR += scratchRe[q] * twRe[twIdx] - scratchIm[q] * twIm[twIdx]
                    accI += scratchRe[q] * twIm[twIdx] + scratchIm[q] * twRe[twIdx]
                }
                re[off + k] = accR
                im[off + k] = accI
                k += m
            }
        }
    }

    private companion object {
        /** Same factor order as KissFFT: 4s first, then 2, then odd primes. */
        fun factor(n0: Int): IntArray {
            val out = ArrayList<Int>()
            var n = n0
            var p = 4
            val floorSqrt = floor(sqrt(n0.toDouble())).toInt()
            do {
                while (n % p != 0) {
                    p = when (p) {
                        4 -> 2
                        2 -> 3
                        else -> p + 2
                    }
                    if (p > floorSqrt) p = n
                }
                n /= p
                out += p
                out += n
            } while (n > 1)
            return out.toIntArray()
        }
    }
}

/**
 * Real-signal helper around [Fft]: forward gives bins 0..N/2, inverse takes
 * bins 0..N/2 and returns N real samples scaled by 1/N (numpy rfft/irfft
 * conventions).
 */
class RealFft(val size: Int) {
    val bins = size / 2 + 1
    private val fwd = Fft(size, inverse = false)
    private val inv = Fft(size, inverse = true)
    private val aRe = FloatArray(size)
    private val aIm = FloatArray(size)
    private val bRe = FloatArray(size)
    private val bIm = FloatArray(size)

    /** [input] has [size] samples; results go to [re]/[im] (length [bins]). */
    fun forward(input: FloatArray, re: FloatArray, im: FloatArray) {
        System.arraycopy(input, 0, aRe, 0, size)
        aIm.fill(0f)
        fwd.transform(aRe, aIm, bRe, bIm)
        System.arraycopy(bRe, 0, re, 0, bins)
        System.arraycopy(bIm, 0, im, 0, bins)
    }

    /** Hermitian-extends the half spectrum and writes [size] real samples to [out]. */
    fun inverse(re: FloatArray, im: FloatArray, out: FloatArray) {
        for (k in 0 until bins) {
            aRe[k] = re[k]
            aIm[k] = im[k]
        }
        // DC and Nyquist bins of a real signal are real.
        aIm[0] = 0f
        if (size % 2 == 0) aIm[bins - 1] = 0f
        for (k in bins until size) {
            aRe[k] = re[size - k]
            aIm[k] = -im[size - k]
        }
        inv.transform(aRe, aIm, bRe, bIm)
        val scale = 1f / size
        for (n in 0 until size) out[n] = bRe[n] * scale
    }
}

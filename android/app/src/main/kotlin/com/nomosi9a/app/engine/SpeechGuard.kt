package com.nomosi9a.app.engine

import com.nomosi9a.app.engine.dsp.Decimator
import com.nomosi9a.app.engine.dsp.RealFft
import com.nomosi9a.app.engine.dsp.StreamingStft
import kotlin.math.sqrt

/**
 * Keeps the model from cutting words.
 *
 * The music remover is a speech-enhancement network: when music is about as
 * loud as the voice, it sometimes takes parts of words for music and drops
 * them (choppy or missing speech). While someone is talking, the guard keeps
 * every frequency bin of the output at most [Level.floorDb] below the input,
 * so a word the model wrongly removed still comes through (and the music
 * under the voice by the same amount). When nobody talks it does nothing, so
 * music alone is still removed completely.
 *
 * "Someone is talking" needs two independent detectors to agree:
 *  - [inputVad] on the original sound: hears words even where the model cut
 *    them, and hears them early (the model output lags its input by
 *    [modelLag] frames, so onsets are protected from their first frame);
 *  - [outputVad] on what the model kept, before the guard touches it: some
 *    instrumental music fools a detector on its own (a lead synth, a sax),
 *    but then the model removes it and the second detector hears nothing.
 * Sung vocals rarely pass the first one (Silero VAD tells speech from
 * singing), so songs keep their instruments removed.
 *
 * Python reference and measurements: tool/speech_eval.
 */
class SpeechGuard(
    private val inputVad: SileroVad,
    private val outputVad: SileroVad,
    sampleRate: Int,
    private val hopSize: Int,
    private val bins: Int,
    modelLag: Int,
) : AutoCloseable {

    enum class Level(val id: String, val floorDb: Float) {
        OFF("off", 0f),
        NORMAL("normal", 12f),
        STRONG("strong", 6f);

        companion object {
            fun fromId(id: String?): Level = entries.firstOrNull { it.id == id } ?: NORMAL
        }
    }

    /** Can change at any time (settings screen); read once per frame on the audio thread. */
    @Volatile
    var level: Level = Level.NORMAL

    /** True while the guard considers that someone is talking (for the UI). */
    @Volatile
    var speaking = false
        private set

    private val hopMs = 1000f * hopSize / sampleRate
    private val hangFrames = (HANG_MS / hopMs).toInt()
    private val confirmFrames = (CONFIRM_HOLD_MS / hopMs).toInt()
    private val release = minOf(1f, hopMs / RELEASE_MS)

    private val inputDecimator = Decimator(sampleRate / SileroVad.SAMPLE_RATE, hopSize)
    private val outputDecimator = Decimator(sampleRate / SileroVad.SAMPLE_RATE, hopSize)
    private val decimated = FloatArray(hopSize)

    // Input spectra of the last modelLag + 1 frames: the output frame being
    // produced belongs to the oldest one.
    private val ringRe = Array(modelLag + 1) { FloatArray(bins) }
    private val ringIm = Array(modelLag + 1) { FloatArray(bins) }
    private var ringPos = 0

    // Inverse STFT of the model output, for the output detector.
    private val windowSize = 2 * hopSize
    private val fft = RealFft(windowSize)
    private val window = StreamingStft.vorbisWindow(windowSize)
    private val synth = FloatArray(windowSize)
    private val overlap = FloatArray(windowSize)
    private val modelOut = FloatArray(hopSize)

    private var framesSinceSpeech = FAR
    private var framesSinceConfirmed = FAR
    private var weight = 0f

    init {
        require(sampleRate % SileroVad.SAMPLE_RATE == 0) { "unsupported rate $sampleRate" }
    }

    /** Time-domain input hop, before the STFT. */
    fun onInput(hop: FloatArray) {
        if (level == Level.OFF) return
        val n = inputDecimator.process(hop, hop.size, decimated)
        inputVad.push(decimated, 0, n)
    }

    /** The input spectrum of the current frame, before the model replaces it. */
    fun remember(re: FloatArray, im: FloatArray) {
        System.arraycopy(re, 0, ringRe[ringPos], 0, bins)
        System.arraycopy(im, 0, ringIm[ringPos], 0, bins)
        ringPos = (ringPos + 1) % ringRe.size
    }

    /** Raises the model's output spectrum (in place) where it removed too much during speech. */
    fun apply(re: FloatArray, im: FloatArray) {
        val lvl = level
        if (lvl == Level.OFF) {
            // The detectors are not fed meanwhile: start from "nobody talks" when switched back on.
            framesSinceSpeech = FAR
            framesSinceConfirmed = FAR
            weight = 0f
            speaking = false
            return
        }
        listenToModel(re, im)

        framesSinceSpeech = if (inputVad.probability >= INPUT_THRESHOLD) 0 else framesSinceSpeech + 1
        framesSinceConfirmed = if (outputVad.probability >= OUTPUT_THRESHOLD) 0 else framesSinceConfirmed + 1
        val talking = framesSinceSpeech <= hangFrames && framesSinceConfirmed <= confirmFrames
        val target = if (talking) 1f else 0f
        // Instant attack, smooth release once the hangover has passed.
        weight = if (target >= weight) target else weight + (target - weight) * release
        if (weight < MIN_WEIGHT) weight = 0f
        speaking = talking
        if (weight <= 0f) return

        // ringPos now points at the oldest stored frame (next to be overwritten).
        val xr = ringRe[ringPos]
        val xi = ringIm[ringPos]
        val floor = weight * dbToGain(-lvl.floorDb)
        for (k in 0 until bins) {
            val ax = sqrt(xr[k] * xr[k] + xi[k] * xi[k])
            if (ax <= 0f) continue
            val ay = sqrt(re[k] * re[k] + im[k] * im[k])
            val wanted = floor * ax
            if (wanted > ay) {
                // Add the missing magnitude along the input's phase.
                val add = (wanted - ay) / ax
                re[k] += add * xr[k]
                im[k] += add * xi[k]
            }
        }
    }

    /** Feeds the model's own output (inverse STFT, overlap-add) to the output detector. */
    private fun listenToModel(re: FloatArray, im: FloatArray) {
        fft.inverse(re, im, synth)
        for (n in 0 until windowSize) overlap[n] += synth[n] * window[n]
        System.arraycopy(overlap, 0, modelOut, 0, hopSize)
        System.arraycopy(overlap, hopSize, overlap, 0, windowSize - hopSize)
        overlap.fill(0f, windowSize - hopSize, windowSize)
        val n = outputDecimator.process(modelOut, hopSize, decimated)
        outputVad.push(decimated, 0, n)
    }

    fun reset() {
        inputDecimator.reset()
        outputDecimator.reset()
        inputVad.reset()
        outputVad.reset()
        for (a in ringRe) a.fill(0f)
        for (a in ringIm) a.fill(0f)
        ringPos = 0
        overlap.fill(0f)
        framesSinceSpeech = FAR
        framesSinceConfirmed = FAR
        weight = 0f
        speaking = false
    }

    override fun close() {
        inputVad.close()
        outputVad.close()
    }

    private companion object {
        const val FAR = Int.MAX_VALUE / 2
        const val INPUT_THRESHOLD = 0.5f
        const val OUTPUT_THRESHOLD = 0.5f
        const val HANG_MS = 200f
        const val CONFIRM_HOLD_MS = 1000f
        const val RELEASE_MS = 60f

        /** Below this the floor is 60 dB under its full level: stop working. */
        const val MIN_WEIGHT = 1e-3f

        fun dbToGain(db: Float) = Math.pow(10.0, db / 20.0).toFloat()
    }
}

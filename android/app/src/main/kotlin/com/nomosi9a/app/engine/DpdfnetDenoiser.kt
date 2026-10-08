package com.nomosi9a.app.engine

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import ai.onnxruntime.TensorInfo
import com.nomosi9a.app.engine.dsp.SpectrumFilter
import com.nomosi9a.app.engine.dsp.StreamingStft
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

/**
 * DPDFNet (Ceva, Apache-2.0): a causal DeepFilterNet2 + dual-path RNN speech
 * enhancer. Each 10 ms hop: STFT frame -> model(spec, state) -> enhanced spec
 * -> inverse STFT. The recurrent state lives in two direct buffers that swap
 * roles every frame, so inference does no copying and no allocation.
 *
 * Offline tests on speech + music mixes (see README): instrumental music alone
 * is pushed down by 60-100 dB, i.e. to silence, while speech stays clear.
 */
class DpdfnetDenoiser private constructor(
    private val session: OrtSession,
    env: OrtEnvironment,
    detectors: Pair<SileroVad, SileroVad>?,
) : Denoiser, SpectrumFilter {

    override val sampleRate: Int
    override val hopSize: Int
    override val latencySamples: Int

    private val stft: StreamingStft
    private val bins: Int
    private val initState: FloatArray

    private val specIn: FloatBuffer
    private val specOut: FloatBuffer
    private val stateA: FloatBuffer
    private val stateB: FloatBuffer
    private val tensors = ArrayList<OnnxTensor>()
    private val feedA: Map<String, OnnxTensor>
    private val feedB: Map<String, OnnxTensor>
    private val pinA: Map<String, OnnxTensor>
    private val pinB: Map<String, OnnxTensor>
    private var useA = true
    private val interleaved: FloatArray

    /** Stops the model from cutting words; null when the speech detector is unavailable. */
    override val guard: SpeechGuard?

    init {
        val meta = session.metadata.customMetadata
        fun metaInt(key: String) = meta[key]?.trim()?.toInt()
            ?: throw IllegalStateException("model metadata '$key' missing")
        fun metaFloats(key: String) = meta[key]?.split(',')?.map { it.trim().toFloat() }
            ?: throw IllegalStateException("model metadata '$key' missing")

        sampleRate = metaInt("sample_rate")
        val window = metaInt("window_length")
        hopSize = metaInt("hop_length")
        require(window == 2 * hopSize) { "unexpected window/hop $window/$hopSize" }
        stft = StreamingStft(window, this)
        bins = stft.bins
        // Framing adds one hop; the network itself looks 4 hops back (measured 50 ms).
        latencySamples = stft.framingDelay + MODEL_LAG * hopSize
        guard = detectors?.let { (input, output) -> SpeechGuard(input, output, sampleRate, hopSize, bins, MODEL_LAG) }

        val stateSize = metaInt("state_size")
        val erbNorm = metaFloats("erb_norm_init")
        val specNorm = metaFloats("spec_norm_init")
        require(erbNorm.size == metaInt("erb_norm_state_size"))
        require(specNorm.size == metaInt("spec_norm_state_size"))
        initState = FloatArray(stateSize).also { s ->
            erbNorm.forEachIndexed { i, v -> s[i] = v }
            specNorm.forEachIndexed { i, v -> s[erbNorm.size + i] = v }
        }

        val (specInName, stateInName) = splitNames(session.inputInfo.mapValues { it.value.info as TensorInfo })
        val (specOutName, stateOutName) = splitNames(session.outputInfo.mapValues { it.value.info as TensorInfo })

        val specShape = longArrayOf(1, 1, bins.toLong(), 2)
        val stateShape = longArrayOf(stateSize.toLong())
        specIn = directFloats(bins * 2)
        specOut = directFloats(bins * 2)
        stateA = directFloats(stateSize)
        stateB = directFloats(stateSize)
        interleaved = FloatArray(bins * 2)

        try {
            OnnxTensor.createTensor(env, specIn, specShape).also(tensors::add)
            OnnxTensor.createTensor(env, specOut, specShape).also(tensors::add)
            OnnxTensor.createTensor(env, stateA, stateShape).also(tensors::add)
            OnnxTensor.createTensor(env, stateB, stateShape).also(tensors::add)
        } catch (t: Throwable) {
            tensors.forEach { it.close() }
            throw t
        }
        val (tSpecIn, tSpecOut, tStateA, tStateB) = tensors
        feedA = mapOf(specInName to tSpecIn, stateInName to tStateA)
        pinA = mapOf(specOutName to tSpecOut, stateOutName to tStateB)
        feedB = mapOf(specInName to tSpecIn, stateInName to tStateB)
        pinB = mapOf(specOutName to tSpecOut, stateOutName to tStateA)
        reset()
    }

    override fun process(input: FloatArray, output: FloatArray) {
        guard?.onInput(input)
        stft.process(input, output)
    }

    /** Called by the STFT once per frame with the current spectrum. */
    override fun filter(re: FloatArray, im: FloatArray) {
        guard?.remember(re, im)
        for (k in 0 until bins) {
            interleaved[2 * k] = re[k]
            interleaved[2 * k + 1] = im[k]
        }
        specIn.clear()
        specIn.put(interleaved)
        if (useA) session.run(feedA, pinA).close() else session.run(feedB, pinB).close()
        useA = !useA
        specOut.clear()
        specOut.get(interleaved)
        for (k in 0 until bins) {
            re[k] = interleaved[2 * k]
            im[k] = interleaved[2 * k + 1]
        }
        guard?.apply(re, im)
    }

    override fun reset() {
        stft.reset()
        stateA.clear()
        stateA.put(initState)
        useA = true
        guard?.reset()
    }

    override fun close() {
        tensors.forEach { it.close() }
        session.close()
        guard?.close()
    }

    companion object {
        /** Frames between a model input and the output that belongs to it (measured). */
        const val MODEL_LAG = 4

        /**
         * [detectors] (input, output speech detectors for [SpeechGuard]) are owned
         * by the returned denoiser from here on: closed with it, or right away if
         * loading fails.
         */
        fun load(
            env: OrtEnvironment,
            model: ByteBuffer,
            detectors: Pair<SileroVad, SileroVad>? = null,
            threads: Int = 1,
        ): DpdfnetDenoiser {
            val options = OrtSession.SessionOptions().apply {
                setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
                setExecutionMode(OrtSession.SessionOptions.ExecutionMode.SEQUENTIAL)
                setIntraOpNumThreads(threads)
                setInterOpNumThreads(1)
                // Busy-waiting threads burn battery for nothing at 100 calls/s.
                addConfigEntry("session.intra_op.allow_spinning", "0")
                addConfigEntry("session.inter_op.allow_spinning", "0")
                // Recurrent state decays towards tiny values during silence;
                // denormals would make those frames much slower on x86.
                addConfigEntry("session.set_denormal_as_zero", "1")
            }
            val session = try {
                options.use { env.createSession(model, it) }
            } catch (t: Throwable) {
                detectors?.let { it.first.close(); it.second.close() }
                throw t
            }
            return try {
                DpdfnetDenoiser(session, env, detectors)
            } catch (t: Throwable) {
                session.close()
                detectors?.let { it.first.close(); it.second.close() }
                throw t
            }
        }

        /** The spectrum tensor is 4-D, the state tensor 1-D; names differ per export. */
        private fun splitNames(infos: Map<String, TensorInfo>): Pair<String, String> {
            val spec = infos.entries.first { it.value.shape.size == 4 }.key
            val state = infos.entries.first { it.value.shape.size == 1 }.key
            return spec to state
        }

        private fun directFloats(n: Int): FloatBuffer =
            ByteBuffer.allocateDirect(n * 4).order(ByteOrder.nativeOrder()).asFloatBuffer()
    }
}

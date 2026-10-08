package com.nomosi9a.app.engine

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

/**
 * Silero VAD v5 (MIT): "is someone talking right now?", on 16 kHz audio.
 *
 * Chosen because it stays reliable under music and tells speech apart from
 * singing (offline tests: 0.1 % false alarms on instrumental music, 6 % on sung
 * vocals, 93 % of speech frames found with music as loud as the voice).
 *
 * Audio is pushed in any block size; every 512 samples (32 ms) the model runs
 * once, on that chunk plus the 64 samples before it, and [probability] is
 * updated. Like [DpdfnetDenoiser], tensors are pinned and the recurrent state
 * ping-pongs between two buffers, so [push] never allocates.
 */
class SileroVad private constructor(
    private val session: OrtSession,
    env: OrtEnvironment,
) : AutoCloseable {

    /** Speech probability of the latest complete chunk, 0..1. */
    var probability = 0f
        private set

    private val chunk = FloatArray(CHUNK)
    private var filled = 0
    private val window = FloatArray(CONTEXT + CHUNK)

    private val input = directFloats(CONTEXT + CHUNK)
    private val stateA = directFloats(STATE_SIZE)
    private val stateB = directFloats(STATE_SIZE)
    private val output = directFloats(1)
    private val tensors = ArrayList<OnnxTensor>()
    private val feedA: Map<String, OnnxTensor>
    private val feedB: Map<String, OnnxTensor>
    private val pinA: Map<String, OnnxTensor>
    private val pinB: Map<String, OnnxTensor>
    private var useA = true

    init {
        try {
            val tInput = OnnxTensor.createTensor(env, input, longArrayOf(1, (CONTEXT + CHUNK).toLong())).also(tensors::add)
            val stateShape = longArrayOf(2, 1, 128)
            val tStateA = OnnxTensor.createTensor(env, stateA, stateShape).also(tensors::add)
            val tStateB = OnnxTensor.createTensor(env, stateB, stateShape).also(tensors::add)
            val tOutput = OnnxTensor.createTensor(env, output, longArrayOf(1, 1)).also(tensors::add)
            val tRate = OnnxTensor.createTensor(env, SAMPLE_RATE.toLong()).also(tensors::add)
            feedA = mapOf("input" to tInput, "state" to tStateA, "sr" to tRate)
            feedB = mapOf("input" to tInput, "state" to tStateB, "sr" to tRate)
            pinA = mapOf("output" to tOutput, "stateN" to tStateB)
            pinB = mapOf("output" to tOutput, "stateN" to tStateA)
        } catch (t: Throwable) {
            tensors.forEach { it.close() }
            throw t
        }
        reset()
    }

    /** Feeds [count] samples at 16 kHz. */
    fun push(samples: FloatArray, offset: Int, count: Int) {
        var i = offset
        val end = offset + count
        while (i < end) {
            val n = minOf(CHUNK - filled, end - i)
            System.arraycopy(samples, i, chunk, filled, n)
            filled += n
            i += n
            if (filled == CHUNK) {
                run()
                filled = 0
            }
        }
    }

    private fun run() {
        // window = [last 64 samples of the previous chunk, this chunk]
        System.arraycopy(window, CHUNK, window, 0, CONTEXT)
        System.arraycopy(chunk, 0, window, CONTEXT, CHUNK)
        input.clear()
        input.put(window)
        if (useA) session.run(feedA, pinA).close() else session.run(feedB, pinB).close()
        useA = !useA
        probability = output.get(0)
    }

    fun reset() {
        stateA.clear()
        for (i in 0 until STATE_SIZE) stateA.put(0f)
        useA = true
        window.fill(0f)
        filled = 0
        probability = 0f
    }

    override fun close() {
        tensors.forEach { it.close() }
        session.close()
    }

    companion object {
        const val SAMPLE_RATE = 16_000
        private const val CHUNK = 512
        private const val CONTEXT = 64
        private const val STATE_SIZE = 2 * 128

        fun load(env: OrtEnvironment, model: ByteBuffer): SileroVad {
            val options = OrtSession.SessionOptions().apply {
                setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
                setExecutionMode(OrtSession.SessionOptions.ExecutionMode.SEQUENTIAL)
                setIntraOpNumThreads(1)
                setInterOpNumThreads(1)
                addConfigEntry("session.intra_op.allow_spinning", "0")
                addConfigEntry("session.inter_op.allow_spinning", "0")
                addConfigEntry("session.set_denormal_as_zero", "1")
            }
            val session = options.use { env.createSession(model, it) }
            return try {
                SileroVad(session, env)
            } catch (t: Throwable) {
                session.close()
                throw t
            }
        }

        private fun directFloats(n: Int): FloatBuffer =
            ByteBuffer.allocateDirect(n * 4).order(ByteOrder.nativeOrder()).asFloatBuffer()
    }
}

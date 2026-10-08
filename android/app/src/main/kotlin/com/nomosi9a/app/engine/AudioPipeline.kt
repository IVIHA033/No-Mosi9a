package com.nomosi9a.app.engine

import android.annotation.SuppressLint
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.projection.MediaProjection
import android.os.Process
import android.os.SystemClock
import android.util.Log
import com.nomosi9a.app.NoMosi9aApp.Companion.TAG
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.abs
import kotlin.math.log10
import kotlin.math.max
import kotlin.math.pow

/**
 * The real-time loop: capture other apps' audio -> model -> speaker.
 *
 * One thread does everything, paced by the capture clock (which is the
 * speaker clock, so input and output never drift apart).
 */
class AudioPipeline(
    private val projection: MediaProjection,
    private val createDenoiser: () -> Denoiser,
    private val excludedUids: () -> Collection<Int>,
    private val latencyMode: String,
    private val listener: Listener,
    /** Debug builds only: where to save the first seconds of input/output. */
    private val debugDir: File? = null,
) {
    interface Listener {
        fun onStarted(sampleRate: Int, latencyMs: Int)
        /** [speaking]: the speech guard hears someone talking (their words are protected). */
        fun onLevels(inputDb: Float, outputDb: Float, load: Float, speaking: Boolean)
        /** The model cannot keep up with real time on this phone. */
        fun onOverload()
        fun onFatal(reason: String, error: Throwable?)
    }

    @Volatile
    private var running = false

    @Volatile
    private var recaptureRequested = false

    @Volatile
    var boostDb: Float = 0f

    private var thread: Thread? = null

    fun start() {
        running = true
        thread = Thread(::run, "NoMosi9a-audio").apply { start() }
    }

    fun stop() {
        running = false
        thread?.let {
            it.interrupt()
            it.join(1500)
        }
        thread = null
    }

    /** Rebuild the capture (the excluded-apps list changed). */
    fun recapture() {
        recaptureRequested = true
    }

    private fun run() {
        Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO)
        var denoiser: Denoiser? = null
        var record: AudioRecord? = null
        var track: AudioTrack? = null
        var tap: DebugTap? = null
        try {
            denoiser = createDenoiser()
            // Stopped while the model was loading (restart, shutdown): don't open anything.
            if (!running) return
            val sr = denoiser.sampleRate
            val hop = denoiser.hopSize
            val prefillHops = when (latencyMode) {
                "low" -> 2
                "stable" -> 8
                else -> 4
            }
            var capture = buildRecord(sr, hop)
            record = capture
            val output = buildTrack(sr, hop, prefillHops + 6)
            track = output
            capture.startRecording()
            if (capture.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
                throw IllegalStateException("capture did not start")
            }

            val input = FloatArray(hop)
            val clean = FloatArray(hop)
            val silence = FloatArray(hop)
            repeat(prefillHops) { output.write(silence, 0, hop, AudioTrack.WRITE_BLOCKING) }
            output.play()
            if (running) {
                listener.onStarted(sr, ((prefillHops * hop + denoiser.latencySamples) * 1000L / sr).toInt())
            }

            tap = debugDir?.let { DebugTap(it, sr, hop) }
            val limiter = Limiter(sr)
            val hopNanos = hop * 1_000_000_000L / sr
            var load = 0f
            var overloadSince = 0L
            var silentHops = 0
            var inSum = 0.0
            var outSum = 0.0
            var meterCount = 0
            var lastUnderruns = output.underrunCount
            var lastUnderrunCheck = SystemClock.uptimeMillis()
            var extraHops = 0

            while (running) {
                if (recaptureRequested) {
                    recaptureRequested = false
                    capture.stop()
                    capture.release()
                    record = null
                    capture = buildRecord(sr, hop)
                    record = capture
                    capture.startRecording()
                }

                if (!readFully(capture, input, hop)) {
                    throw IllegalStateException("capture stopped")
                }

                var peak = 0f
                var energy = 0.0
                for (i in 0 until hop) {
                    val v = input[i]
                    energy += v * v
                    peak = max(peak, abs(v))
                }

                // Paused video: after flushing the model with ~1 s of silence,
                // stop running it (saves battery) and just output silence.
                silentHops = if (peak < SILENCE_PEAK) silentHops + 1 else 0
                if (silentHops > SILENT_HOPS_BEFORE_IDLE) {
                    clean.fill(0f)
                    load *= 0.9f
                } else {
                    val t0 = System.nanoTime()
                    denoiser.process(input, clean)
                    val used = (System.nanoTime() - t0).toFloat() / hopNanos
                    load = load * 0.97f + used * 0.03f
                }

                val gain = 10f.pow(boostDb / 20f)
                var outEnergy = 0.0
                for (i in 0 until hop) {
                    val y = limiter.process(clean[i] * gain)
                    clean[i] = y
                    outEnergy += y * y
                }
                tap?.write(input, clean)
                val written = output.write(clean, 0, hop, AudioTrack.WRITE_BLOCKING)
                if (written < 0) throw IllegalStateException("playback error $written")

                inSum += energy
                outSum += outEnergy
                meterCount += hop
                if (meterCount >= sr / METER_HZ) {
                    if (running) {
                        val speaking = denoiser.guard?.speaking == true && silentHops <= SILENT_HOPS_BEFORE_IDLE
                        listener.onLevels(toDb(inSum / meterCount), toDb(outSum / meterCount), load, speaking)
                    }
                    inSum = 0.0
                    outSum = 0.0
                    meterCount = 0
                }

                val now = SystemClock.uptimeMillis()
                if (load > OVERLOAD_LOAD) {
                    if (overloadSince == 0L) overloadSince = now
                    if (now - overloadSince > OVERLOAD_MS) {
                        listener.onOverload()
                        overloadSince = now
                    }
                } else {
                    overloadSince = 0L
                }

                // Output ran dry (phone busy): keep one more hop in flight, up to a limit.
                if (now - lastUnderrunCheck > 1000) {
                    val underruns = output.underrunCount
                    if (underruns > lastUnderruns && extraHops < MAX_EXTRA_HOPS) {
                        output.write(silence, 0, hop, AudioTrack.WRITE_NON_BLOCKING)
                        extraHops++
                    }
                    lastUnderruns = underruns
                    lastUnderrunCheck = now
                }
            }
        } catch (t: Throwable) {
            if (running) {
                Log.e(TAG, "audio pipeline failed", t)
                listener.onFatal(if (t is SecurityException) "capture_denied" else "engine_failed", t)
            }
        } finally {
            try {
                record?.stop()
            } catch (_: Throwable) {
            }
            record?.release()
            try {
                track?.pause()
                track?.flush()
            } catch (_: Throwable) {
            }
            track?.release()
            denoiser?.close()
            tap?.close()
        }
    }

    /** Blocking read that tolerates short reads; false when capture is dead. */
    private fun readFully(record: AudioRecord, buffer: FloatArray, count: Int): Boolean {
        var offset = 0
        while (offset < count) {
            if (!running) return false
            val n = record.read(buffer, offset, count - offset, AudioRecord.READ_BLOCKING)
            if (n < 0) return false
            offset += n
        }
        return true
    }

    @SuppressLint("MissingPermission")
    private fun buildRecord(sampleRate: Int, hop: Int): AudioRecord {
        val capture = AudioPlaybackCaptureConfiguration.Builder(projection)
            .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
            .addMatchingUsage(AudioAttributes.USAGE_GAME)
            .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
        (excludedUids() + Process.myUid()).toSet().forEach { capture.excludeUid(it) }
        val format = AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
            .setSampleRate(sampleRate)
            .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
            .build()
        val minBytes = AudioRecord.getMinBufferSize(
            sampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_FLOAT,
        )
        return AudioRecord.Builder()
            .setAudioFormat(format)
            .setBufferSizeInBytes(max(minBytes, hop * 4 * 16))
            .setAudioPlaybackCaptureConfig(capture.build())
            .build()
    }

    private fun buildTrack(sampleRate: Int, hop: Int, bufferHops: Int): AudioTrack {
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_MOVIE)
            // System services (Live Caption) may still hear the clean voice;
            // screen recorders and our own capture may not.
            .setAllowedCapturePolicy(AudioAttributes.ALLOW_CAPTURE_BY_SYSTEM)
            .build()
        val format = AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
            .setSampleRate(sampleRate)
            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
            .build()
        val minBytes = AudioTrack.getMinBufferSize(
            sampleRate, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_FLOAT,
        )
        return AudioTrack.Builder()
            .setAudioAttributes(attributes)
            .setAudioFormat(format)
            .setTransferMode(AudioTrack.MODE_STREAM)
            .setPerformanceMode(
                if (latencyMode == "low") AudioTrack.PERFORMANCE_MODE_LOW_LATENCY
                else AudioTrack.PERFORMANCE_MODE_NONE,
            )
            .setBufferSizeInBytes(max(minBytes, bufferHops * hop * 4))
            .build()
    }

    /**
     * Saves the first seconds of what we captured and what we played as raw
     * little-endian float32 (debug builds, when `files/debug_record` exists),
     * so the result can be pulled with adb and checked on a computer.
     */
    private class DebugTap(dir: File, sampleRate: Int, hop: Int) {
        private val maxFrames = sampleRate * 40
        private var frames = 0
        private val inOut = BufferedOutputStream(FileOutputStream(File(dir, "debug_in_$sampleRate.f32")))
        private val outOut = BufferedOutputStream(FileOutputStream(File(dir, "debug_out_$sampleRate.f32")))
        private val bytes = ByteBuffer.allocate(hop * 4).order(ByteOrder.LITTLE_ENDIAN)

        private var closed = false

        fun write(input: FloatArray, output: FloatArray) {
            if (closed) return
            put(inOut, input)
            put(outOut, output)
            frames += input.size
            if (frames >= maxFrames) close()
        }

        fun close() {
            if (closed) return
            closed = true
            try {
                inOut.close()
                outOut.close()
            } catch (_: Throwable) {
            }
            Log.i(TAG, "debug tap: saved $frames frames")
        }

        private fun put(stream: BufferedOutputStream, data: FloatArray) {
            bytes.clear()
            bytes.asFloatBuffer().put(data)
            stream.write(bytes.array(), 0, data.size * 4)
        }
    }

    /** Soft ceiling so the voice boost never clips. */
    private class Limiter(sampleRate: Int) {
        private val release = 0.1.pow(1.0 / (0.12 * sampleRate)).toFloat()
        private var envelope = 0f

        fun process(x: Float): Float {
            val a = abs(x)
            envelope = if (a > envelope) a else envelope * release + a * (1 - release)
            return if (envelope > CEILING) x * (CEILING / envelope) else x
        }
    }

    private companion object {
        const val CEILING = 0.95f
        const val SILENCE_PEAK = 1e-5f
        const val SILENT_HOPS_BEFORE_IDLE = 100
        const val METER_HZ = 15
        const val OVERLOAD_LOAD = 0.85f
        const val OVERLOAD_MS = 4_000L
        const val MAX_EXTRA_HOPS = 6

        fun toDb(meanSquare: Double): Float =
            if (meanSquare <= 1e-12) EngineStatus.SILENCE_DB else (10 * log10(meanSquare)).toFloat()
    }
}

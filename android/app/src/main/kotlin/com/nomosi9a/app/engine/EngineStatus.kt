package com.nomosi9a.app.engine

import android.os.Handler
import android.os.Looper
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Process-wide engine state. The service writes it, the Flutter event channel
 * and the quick settings tile read it. Listeners are always called on the
 * main thread.
 */
object EngineStatus {

    enum class State { STOPPED, STARTING, RUNNING, ERROR }

    /** One app whose audio is (or could not be) cleaned. */
    data class App(
        val packageName: String,
        val label: String,
        val muted: Boolean,
        val blocked: Boolean,
    )

    data class Snapshot(
        val state: State = State.STOPPED,
        /** Machine-readable reason when [state] is ERROR, e.g. "projection_revoked". */
        val error: String? = null,
        val model: String? = null,
        /** True when the engine dropped to the light model because the phone was too slow. */
        val autoSwitched: Boolean = false,
        val sampleRate: Int = 0,
        val latencyMs: Int = 0,
        /** Share of the real-time budget used by the model (1.0 = just keeping up). */
        val load: Float = 0f,
        val inputDb: Float = SILENCE_DB,
        val outputDb: Float = SILENCE_DB,
        /** Someone is talking and the speech guard is protecting their words. */
        val speaking: Boolean = false,
        val apps: List<App> = emptyList(),
        val startedAt: Long = 0L,
    ) {
        fun toMap(): Map<String, Any?> = mapOf(
            "state" to state.name.lowercase(),
            "error" to error,
            "model" to model,
            "autoSwitched" to autoSwitched,
            "sampleRate" to sampleRate,
            "latencyMs" to latencyMs,
            "load" to load.toDouble(),
            "inputDb" to inputDb.toDouble(),
            "outputDb" to outputDb.toDouble(),
            "speaking" to speaking,
            "startedAt" to startedAt,
            "apps" to apps.map {
                mapOf(
                    "package" to it.packageName,
                    "label" to it.label,
                    "muted" to it.muted,
                    "blocked" to it.blocked,
                )
            },
        )
    }

    const val SILENCE_DB = -120f

    private val main = Handler(Looper.getMainLooper())
    private val listeners = CopyOnWriteArrayList<(Snapshot) -> Unit>()
    private val dispatchPending = AtomicBoolean(false)

    @Volatile
    var current = Snapshot()
        private set

    val isActive: Boolean
        get() = current.state == State.RUNNING || current.state == State.STARTING

    fun update(transform: (Snapshot) -> Snapshot) {
        synchronized(this) { current = transform(current) }
        // Deliver on the main thread, always the latest snapshot at delivery
        // time: a level update posted by the audio thread just before a stop
        // must never overwrite the STOPPED state that follows it.
        if (dispatchPending.compareAndSet(false, true)) {
            main.post {
                dispatchPending.set(false)
                val snapshot = current
                listeners.forEach { it(snapshot) }
            }
        }
    }

    fun addListener(listener: (Snapshot) -> Unit) {
        listeners += listener
        listener(current)
    }

    fun removeListener(listener: (Snapshot) -> Unit) {
        listeners -= listener
    }
}

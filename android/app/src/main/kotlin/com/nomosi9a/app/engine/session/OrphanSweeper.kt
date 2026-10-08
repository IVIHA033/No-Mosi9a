package com.nomosi9a.app.engine.session

import android.content.Context
import android.util.Log
import com.nomosi9a.app.NoMosi9aApp.Companion.TAG
import com.nomosi9a.app.platform.Setup
import java.util.concurrent.Executors

/**
 * Removes mute effects that outlived the engine.
 *
 * AudioFlinger pins session effects while the app's track exists; when our
 * process is killed (force stop, update, crash that skipped the handler) our
 * effects stay behind and keep that app silent until it recreates its audio.
 * This finds them in the AudioFlinger dump (effect of our types, no client)
 * and removes them. It runs whenever our process starts: opening the app,
 * pulling down quick settings (the tile binds us), after an update, and
 * right before the engine starts.
 */
object OrphanSweeper {

    private val executor = Executors.newSingleThreadExecutor { Thread(it, "NoMosi9a-sweeper") }
    private val types = setOf(MuteEffect.TYPE_DYNAMICS, MuteEffect.TYPE_VOLUME)

    fun sweepAsync(context: Context) {
        val app = context.applicationContext
        executor.execute { sweep(app) }
    }

    /** Blocking. Returns how many sessions were cleaned. */
    fun sweep(context: Context): Int {
        if (!Setup.hasDump(context)) return 0
        var cleaned = 0
        // Right after a process death AudioFlinger may still refuse new handles
        // on the session for a moment (NO_INIT): retry with a short backoff.
        repeat(ATTEMPTS) { attempt ->
            val text = AudioDump.read("media.audio_flinger") ?: return cleaned
            val orphans = types.associateWith { AudioDumpParser.parseOrphanEffects(text, setOf(it)) }
            if (orphans.values.all { it.isEmpty() }) return cleaned
            orphans.forEach { (type, sessions) ->
                sessions.forEach { sid ->
                    if (MuteEffect.clearOrphan(sid, type)) {
                        cleaned++
                        Log.i(TAG, "removed orphaned mute effect on session $sid")
                    }
                }
            }
            if (attempt < ATTEMPTS - 1) Thread.sleep(300L * (attempt + 1))
        }
        return cleaned
    }

    private const val ATTEMPTS = 3
}

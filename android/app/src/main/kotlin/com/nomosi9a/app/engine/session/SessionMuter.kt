package com.nomosi9a.app.engine.session

import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.AudioPlaybackConfiguration
import android.media.audiofx.AudioEffect
import android.os.Handler
import android.os.HandlerThread
import android.os.Process
import android.os.SystemClock
import android.util.Log
import com.nomosi9a.app.NoMosi9aApp.Companion.TAG
import com.nomosi9a.app.engine.EngineStatus
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Keeps every capturable audio session of other apps muted at the speaker, so
 * the user only hears our cleaned copy.
 *
 * Sessions are discovered from the audio policy dump, re-checked whenever
 * Android reports a playback change, and polled as a safety net. Mute effects
 * are kept a while after a session goes quiet: players (ExoPlayer, YouTube...)
 * reuse their session id for the next video, which is then muted from its
 * very first sample.
 *
 * The rule that matters most: never mute a session we cannot capture, or the
 * user would hear nothing at all from that app.
 */
class SessionMuter(
    context: Context,
    /** Uids the user excluded (their audio is neither captured nor muted). */
    private val isExcluded: (uid: Int) -> Boolean,
    private val onAppsChanged: (List<EngineStatus.App>) -> Unit,
) {
    private val pm: PackageManager = context.applicationContext.packageManager
    private val audioManager = context.applicationContext.getSystemService(AudioManager::class.java)
    private val thread = HandlerThread("NoMosi9a-sessions").apply { start() }
    private val handler = Handler(thread.looper)
    private val myUid = Process.myUid()

    private class Muted(
        val sessionId: Int,
        val uid: Int,
        val packageName: String?,
        var effect: AudioEffect?,
        var lastSeen: Long,
        var active: Boolean,
        var failures: Int = 0,
    )

    private val muted = HashMap<Int, Muted>()
    private val blocked = HashMap<String, Long>()
    private val labels = HashMap<String, String>()
    private var lastPublished: List<EngineStatus.App>? = null
    private var dumpFailures = 0
    private var stopped = false

    /** Called once dumps keep failing (DUMP permission revoked, ...). */
    var onDumpUnavailable: (() -> Unit)? = null

    private val playbackCallback = object : AudioManager.AudioPlaybackCallback() {
        override fun onPlaybackConfigChanged(configs: MutableList<AudioPlaybackConfiguration>?) {
            pollSoon()
        }
    }

    private val periodic = object : Runnable {
        override fun run() {
            poll()
            val anyActive = muted.values.any { it.active }
            handler.postDelayed(this, if (anyActive) POLL_ACTIVE_MS else POLL_IDLE_MS)
        }
    }

    private val pollNow = Runnable { poll() }

    fun start() {
        audioManager.registerAudioPlaybackCallback(playbackCallback, handler)
        handler.post(periodic)
    }

    /** Re-evaluate right away (e.g. the excluded-apps list changed). */
    fun refresh() = pollSoon()

    /** Unmutes everything. Blocks up to 1 s so apps are audible again when this returns. */
    fun stop() {
        val done = CountDownLatch(1)
        handler.post {
            stopped = true
            handler.removeCallbacksAndMessages(null)
            try {
                audioManager.unregisterAudioPlaybackCallback(playbackCallback)
            } catch (_: Throwable) {
            }
            muted.values.forEach { MuteEffect.release(it.effect) }
            muted.clear()
            done.countDown()
        }
        done.await(1, TimeUnit.SECONDS)
        thread.quitSafely()
    }

    private fun pollSoon() {
        handler.removeCallbacks(pollNow)
        handler.postDelayed(pollNow, 15)
    }

    private fun poll() {
        if (stopped) return
        val dump = AudioDump.readSessions()
        if (dump == null) {
            if (++dumpFailures == 3) onDumpUnavailable?.invoke()
            return
        }
        dumpFailures = 0
        val now = SystemClock.uptimeMillis()
        val seen = HashSet<Int>()

        // A session can have several clients (tracks); judge it on all of them.
        for ((sessionId, clients) in dump.sessions.groupBy { it.sessionId }) {
            if (sessionId <= 0) continue
            val uid = clients.first().uid
            if (clients.any { it.uid == myUid } || !isAppUid(uid)) continue
            val pkg = packageOf(uid)
            val excluded = clients.any { isExcluded(it.uid) }
            val playable = clients.all { it.isCapturableUsage }
            val capturable = clients.all {
                it.flagsKnown && !it.blocksCapture && dump.captureAllowedByUid[it.uid] != false
            }
            if (excluded || !playable || !capturable) {
                // Muting what we don't capture would silence it completely.
                muted.remove(sessionId)?.let { MuteEffect.release(it.effect) }
                if (!excluded && playable && pkg != null) blocked[pkg] = now
                continue
            }
            seen += sessionId
            val entry = muted.getOrPut(sessionId) {
                Muted(sessionId, uid, pkg, null, now, active = true)
            }
            entry.lastSeen = now
            entry.active = clients.any { it.active != false }
            entry.effect?.let { fx ->
                // Audio server restarted, or another app grabbed the effect.
                if (!MuteEffect.isHealthy(fx)) {
                    MuteEffect.release(fx)
                    entry.effect = null
                    entry.failures++
                }
            }
            if (entry.effect == null && entry.failures < MAX_ATTACH_FAILURES) {
                entry.effect = MuteEffect.attach(sessionId) { lost -> onEffectLost(sessionId, lost) }
                if (entry.effect == null) entry.failures++
            }
        }

        val iterator = muted.values.iterator()
        while (iterator.hasNext()) {
            val m = iterator.next()
            val gone = m.sessionId !in seen
            if (gone) m.active = false
            if ((gone && now - m.lastSeen > KEEP_IDLE_MS) || isExcluded(m.uid)) {
                MuteEffect.release(m.effect)
                iterator.remove()
            }
        }
        blocked.entries.removeAll { now - it.value > SHOW_BLOCKED_MS }
        if (!stopped) publish(now)
    }

    private fun onEffectLost(sessionId: Int, lost: AudioEffect) {
        handler.post {
            val m = muted[sessionId] ?: return@post
            // A late callback from an effect we already replaced: ignore it.
            if (m.effect !== lost) return@post
            Log.w(TAG, "lost control of mute effect on session $sessionId")
            MuteEffect.release(lost)
            m.effect = null
            m.failures++
            pollSoon()
        }
    }

    private fun publish(now: Long) {
        val apps = LinkedHashMap<String, EngineStatus.App>()
        muted.values
            .filter { it.active || now - it.lastSeen < SHOW_RECENT_MS }
            .forEach { m ->
                val pkg = m.packageName ?: "uid:${m.uid}"
                val isMuted = m.effect != null || apps[pkg]?.muted == true
                apps[pkg] = EngineStatus.App(pkg, labelOf(m.packageName, m.uid), isMuted, blocked = false)
            }
        blocked.keys.forEach { pkg ->
            if (pkg !in apps) apps[pkg] = EngineStatus.App(pkg, labelOf(pkg, -1), muted = false, blocked = true)
        }
        val list = apps.values.toList()
        if (list != lastPublished) {
            lastPublished = list
            onAppsChanged(list)
        }
    }

    private fun isAppUid(uid: Int): Boolean {
        val appId = uid % 100_000
        // Regular apps, or mediaserver playing on an app's behalf.
        return appId >= Process.FIRST_APPLICATION_UID || appId == MEDIA_UID
    }

    private fun packageOf(uid: Int): String? = try {
        pm.getPackagesForUid(uid)?.firstOrNull()
    } catch (_: Throwable) {
        null
    }

    private fun labelOf(pkg: String?, uid: Int): String {
        if (pkg == null) return "uid $uid"
        return labels.getOrPut(pkg) {
            try {
                pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
            } catch (_: Throwable) {
                pkg
            }
        }
    }

    companion object {
        private const val POLL_ACTIVE_MS = 1_500L
        private const val POLL_IDLE_MS = 5_000L
        private const val KEEP_IDLE_MS = 15 * 60_000L
        private const val SHOW_RECENT_MS = 20_000L
        private const val SHOW_BLOCKED_MS = 60_000L
        private const val MAX_ATTACH_FAILURES = 5
        private const val MEDIA_UID = 1013

        /**
         * Assistant / system-intelligence packages known to misbehave when
         * muted. They are excluded from capture too, so they play normally
         * instead of being heard twice.
         */
        val NEVER_TOUCH = setOf(
            "com.google.android.googlequicksearchbox",
            "com.google.android.as",
            "com.google.android.tts",
        )
    }
}

package com.nomosi9a.app.engine.session

import android.os.IBinder
import android.os.ParcelFileDescriptor
import android.os.SystemClock
import android.system.Os
import android.system.OsConstants
import android.system.StructPollfd
import android.util.Log
import com.nomosi9a.app.NoMosi9aApp.Companion.TAG
import org.lsposed.hiddenapibypass.HiddenApiBypass
import java.io.ByteArrayOutputStream

/** One playback client (an AudioTrack/MediaPlayer of some app) seen in a system dump. */
data class PlaybackSession(
    val sessionId: Int,
    val uid: Int,
    /** Usage as printed by the dump, e.g. "AUDIO_USAGE_MEDIA" or "USAGE_MEDIA". */
    val usage: String,
    /** audio_flags_mask_t, or -1 when the dump does not show it. */
    val flags: Int,
    /** null when the dump does not say. */
    val active: Boolean?,
) {
    /** Usages that Android lets a MediaProjection capture. */
    val isCapturableUsage: Boolean
        get() = usage.contains("USAGE_MEDIA") || usage.contains("USAGE_GAME") ||
            usage.contains("USAGE_UNKNOWN")

    /** The app (or this player) opted out of capture: it must stay unmuted. */
    val blocksCapture: Boolean
        get() = flags >= 0 && (flags and FLAG_NO_MEDIA_PROJECTION) != 0

    /** Without the flags we cannot tell whether capture is allowed. */
    val flagsKnown: Boolean
        get() = flags >= 0

    companion object {
        /** AUDIO_FLAG_NO_MEDIA_PROJECTION / AudioAttributes.FLAG_NO_MEDIA_PROJECTION. */
        const val FLAG_NO_MEDIA_PROJECTION = 0x400
    }
}

data class SessionDump(
    val sessions: List<PlaybackSession>,
    /** From the "Allow playback capture log": uid -> manifest allows capture. */
    val captureAllowedByUid: Map<Int, Boolean>,
)

/**
 * Parsers for `dumpsys media.audio_policy` and `dumpsys audio`. Formats differ
 * between Android versions, so each client block is parsed field by field
 * instead of with one brittle regex.
 */
object AudioDumpParser {

    private val sessionMarker = Regex("""Session I[dD]:\s*(\d+)""")
    private val uidField = Regex("""(?i)\buid:?\s*(\d+)""")
    private val usageField = Regex("""Usage:\s*(\w+)""")
    private val sourceField = Regex("""Source:\s*(\w+)""")
    private val flagsField = Regex("""Flags:\s*0x([0-9a-fA-F]+)""")
    private val stateField = Regex("""State:\s*(\w+)""")
    private val captureLog = Regex("""uid=\s*(\d+),\s*allowPlaybackCapture=(\w+)""")

    private val effectMarker = Regex("""Effect ID \d+:""")
    private val effectType = Regex("""- TYPE:\s*([0-9a-fA-F-]{36})""")
    private val effectClients = Regex("""(\d+)\s+Clients:""")
    private val effectSession = Regex("""Session[^\n]*\n\s*(\d+)\s""")

    private val playbackConfig = Regex(
        """AudioPlaybackConfiguration\b.*?u/pid:(\d+)/\d+.*?state:(\w+).*?usage=(\w+).*?flags=0x([0-9a-fA-F]+).*?sessionId:(\d+)""",
    )

    /** `dumpsys media.audio_policy` (Android 10+). */
    fun parseAudioPolicy(text: String): SessionDump {
        val markers = sessionMarker.findAll(text).toList()
        val sessions = ArrayList<PlaybackSession>()
        markers.forEachIndexed { i, m ->
            val end = if (i + 1 < markers.size) markers[i + 1].range.first else text.length
            val block = text.substring(m.range.first, minOf(end, m.range.first + 1200))
            val sessionId = m.groupValues[1].toIntOrNull() ?: return@forEachIndexed
            val uid = uidField.find(block, m.value.length)?.groupValues?.get(1)?.toIntOrNull()
                ?: return@forEachIndexed
            val usage = usageField.find(block)?.groupValues?.get(1) ?: return@forEachIndexed
            // Record clients carry a real source (MIC, REMOTE_SUBMIX...); playback ones don't.
            val source = sourceField.find(block)?.groupValues?.get(1)
            if (source != null && !source.endsWith("DEFAULT") && !source.endsWith("INVALID") &&
                source != "0" && source != "-1"
            ) return@forEachIndexed
            val flags = flagsField.find(block)?.groupValues?.get(1)?.toLongOrNull(16)?.toInt() ?: -1
            val active = stateField.find(block)?.groupValues?.get(1)?.let { it.equals("Active", true) }
            sessions += PlaybackSession(sessionId, uid, usage, flags, active)
        }
        return SessionDump(sessions.distinctBy { it.sessionId }, parseCaptureLog(text))
    }

    /** `dumpsys audio` (AudioService). Session ids are printed from Android 12. */
    fun parseAudioService(text: String): SessionDump {
        val sessions = playbackConfig.findAll(text).mapNotNull { m ->
            val (uid, state, usage, flags, sid) = m.destructured
            val sessionId = sid.toIntOrNull() ?: return@mapNotNull null
            if (state == "released") return@mapNotNull null
            PlaybackSession(
                sessionId = sessionId,
                uid = uid.toIntOrNull() ?: return@mapNotNull null,
                usage = usage,
                flags = flags.toLongOrNull(16)?.toInt() ?: -1,
                active = state == "started",
            )
        }.distinctBy { it.sessionId }.toList()
        return SessionDump(sessions, parseCaptureLog(text))
    }

    /**
     * `dumpsys media.audio_flinger`: sessions holding an effect of one of
     * [types] that no client owns any more. Session effects are pinned while
     * the app's track exists, so when a process dies without releasing its
     * effect (force stop, crash) the effect keeps running on its own.
     */
    fun parseOrphanEffects(text: String, types: Set<String>): Set<Int> {
        val markers = effectMarker.findAll(text).toList()
        val sessions = HashSet<Int>()
        markers.forEachIndexed { i, m ->
            val end = if (i + 1 < markers.size) markers[i + 1].range.first else text.length
            val block = text.substring(m.range.first, minOf(end, m.range.first + 3000))
            val type = effectType.find(block)?.groupValues?.get(1)?.lowercase() ?: return@forEachIndexed
            if (type !in types) return@forEachIndexed
            val clients = effectClients.find(block)?.groupValues?.get(1)?.toIntOrNull() ?: return@forEachIndexed
            val session = effectSession.find(block)?.groupValues?.get(1)?.toIntOrNull() ?: return@forEachIndexed
            if (clients == 0 && session > 0) sessions += session
        }
        return sessions
    }

    /** A uid shared by several packages is capturable only if all of them allow it. */
    private fun parseCaptureLog(text: String): Map<Int, Boolean> {
        val result = HashMap<Int, Boolean>()
        captureLog.findAll(text).forEach { m ->
            val uid = m.groupValues[1].toIntOrNull() ?: return@forEach
            val allowed = m.groupValues[2].equals("true", ignoreCase = true)
            result[uid] = (result[uid] ?: true) && allowed
        }
        return result
    }
}

/**
 * Reads system service dumps in-process. Needs android.permission.DUMP, which a
 * normal app can only get from ADB/Shizuku (`pm grant <pkg> android.permission.DUMP`).
 */
object AudioDump {

    private val getService by lazy {
        HiddenApiBypass.getDeclaredMethod(
            Class.forName("android.os.ServiceManager"), "getService", String::class.java,
        )
    }

    /** Which dump has produced sessions on this device; null until one has. */
    @Volatile
    private var trusted: String? = null

    fun readSessions(): SessionDump? {
        // The policy dump is required every time: besides the sessions it
        // holds the per-app "allow playback capture" log. Without it we could
        // mute an app that forbids capture, which would silence it for good.
        val policy = read(SERVICE_POLICY)?.let { AudioDumpParser.parseAudioPolicy(it) } ?: return null
        if (trusted != SERVICE_AUDIO) {
            if (policy.sessions.isNotEmpty()) {
                trusted = SERVICE_POLICY
                return policy
            }
            if (trusted == SERVICE_POLICY) return policy
        }
        // No client parsed from the policy dump: either nothing plays, or this
        // Android build prints it differently. Ask AudioService as well.
        val service = read(SERVICE_AUDIO)?.let { AudioDumpParser.parseAudioService(it) } ?: return policy
        // Only switch sources on evidence: something is actually playing there.
        if (trusted == null && service.sessions.any { it.active == true && it.isCapturableUsage }) {
            trusted = SERVICE_AUDIO
        }
        return if (trusted == SERVICE_AUDIO) {
            service.copy(captureAllowedByUid = policy.captureAllowedByUid)
        } else {
            policy
        }
    }

    private const val SERVICE_POLICY = "media.audio_policy"
    private const val SERVICE_AUDIO = "audio"

    /** Returns the dump text, or null on any failure (missing permission, timeout...). */
    fun read(service: String, timeoutMs: Long = 1500): String? {
        val binder = try {
            getService.invoke(null, service) as? IBinder
        } catch (t: Throwable) {
            Log.w(TAG, "ServiceManager.getService($service) failed", t)
            null
        } ?: return null

        val pipe = try {
            ParcelFileDescriptor.createPipe()
        } catch (t: Throwable) {
            return null
        }
        val readEnd = pipe[0]
        val writeEnd = pipe[1]
        try {
            // dumpAsync: the service writes while we read, so a big dump can't
            // deadlock on a full pipe.
            writeEnd.use { binder.dumpAsync(it.fileDescriptor, emptyArray()) }
            return readAll(readEnd, timeoutMs)
        } catch (t: Throwable) {
            Log.w(TAG, "dump of $service failed", t)
            return null
        } finally {
            try {
                readEnd.close()
            } catch (_: Throwable) {
            }
        }
    }

    private fun readAll(pfd: ParcelFileDescriptor, timeoutMs: Long): String? {
        val fd = pfd.fileDescriptor
        val poll = StructPollfd().apply {
            this.fd = fd
            events = OsConstants.POLLIN.toShort()
        }
        val out = ByteArrayOutputStream(64 * 1024)
        val buffer = ByteArray(32 * 1024)
        val deadline = SystemClock.uptimeMillis() + timeoutMs
        while (true) {
            val remaining = deadline - SystemClock.uptimeMillis()
            if (remaining <= 0) return null
            poll.revents = 0
            if (Os.poll(arrayOf(poll), remaining.toInt()) == 0) return null
            val n = Os.read(fd, buffer, 0, buffer.size)
            if (n <= 0) break
            out.write(buffer, 0, n)
        }
        return out.toString(Charsets.UTF_8.name())
    }
}

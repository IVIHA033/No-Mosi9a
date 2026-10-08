package com.nomosi9a.app.engine.session

import android.media.audiofx.AudioEffect
import android.media.audiofx.DynamicsProcessing
import android.util.Log
import com.nomosi9a.app.NoMosi9aApp.Companion.TAG
import org.lsposed.hiddenapibypass.HiddenApiBypass
import java.lang.reflect.Method
import java.util.Collections
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/**
 * Silences another app's audio session at the speaker while leaving the copy
 * that playback capture receives untouched: capture taps the track before
 * session effects run, so the app is muted for the listener only.
 *
 * Uses the public DynamicsProcessing effect (-200 dB input gain) when the
 * phone has it, otherwise the hidden OpenSL "Volume" effect. One kind per
 * phone, so a retry never stacks a second effect type on the same session.
 *
 * Session effects are pinned by AudioFlinger while the app's track exists:
 * if our process dies without releasing them, they keep muting. Every live
 * effect is tracked here so a crash can release them, and [OrphanSweeper]
 * removes the ones a force-stop left behind.
 */
object MuteEffect {

    const val TYPE_DYNAMICS = "7261676f-6d75-7369-6364-28e2fd3ac39e"
    const val TYPE_VOLUME = "09e8ede0-ddde-11db-b4f6-0002a5d5c51b"
    private val TYPE_NULL: UUID = UUID.fromString("ec7178ec-e5e1-4432-a3f4-4657e6795210")
    private const val MUTE_DB = -200f
    private const val VOLUME_PARAM_LEVEL = 0
    private const val VOLUME_PARAM_MUTE = 2

    private val live: MutableSet<AudioEffect> = Collections.newSetFromMap(ConcurrentHashMap())

    private val available: Set<String> by lazy {
        try {
            AudioEffect.queryEffects().orEmpty().map { it.type.toString().lowercase() }.toSet()
        } catch (_: Throwable) {
            emptySet()
        }
    }

    private val useDynamics: Boolean
        get() = TYPE_DYNAMICS in available

    // Hidden APIs, resolved through HiddenApiBypass: plain reflection on
    // these members is blocked for apps targeting SDK 36.
    private val volumeSetParameter: Method? by lazy {
        try {
            HiddenApiBypass.getDeclaredMethod(
                AudioEffect::class.java, "setParameter", Int::class.javaPrimitiveType, Int::class.javaPrimitiveType,
            )
        } catch (t: Throwable) {
            null
        }
    }

    /** True if this phone ships at least one effect we can mute with. */
    fun isSupported(): Boolean = TYPE_DYNAMICS in available || TYPE_VOLUME in available

    /**
     * Must be called on a thread with a Looper: effect callbacks are delivered there.
     * [onLost] receives the effect that another app took away from us.
     */
    fun attach(sessionId: Int, onLost: (AudioEffect) -> Unit): AudioEffect? {
        val effect = (if (useDynamics) newDynamics(sessionId) else newVolume(sessionId)) ?: return null
        try {
            mute(effect)
        } catch (t: Throwable) {
            Log.w(TAG, "could not mute session $sessionId: ${t.message}")
            release(effect)
            return null
        }
        effect.setEnableStatusListener { fx, enabled ->
            if (!enabled) {
                try {
                    mute(fx)
                } catch (t: Throwable) {
                    onLost(fx)
                }
            }
        }
        effect.setControlStatusListener { fx, granted ->
            if (granted) {
                try {
                    mute(fx)
                } catch (t: Throwable) {
                    onLost(fx)
                }
            } else {
                onLost(fx)
            }
        }
        return effect
    }

    /** True while we still own the effect engine of that session. */
    fun isHealthy(effect: AudioEffect): Boolean = try {
        effect.hasControl() && effect.enabled
    } catch (_: Throwable) {
        false
    }

    /**
     * Unmutes, then releases. The effect module is shared per session: if
     * another app also uses it, it must not inherit our -200 dB.
     */
    fun release(effect: AudioEffect?) {
        if (effect == null) return
        live.remove(effect)
        try {
            if (effect.hasControl()) {
                unmute(effect)
                effect.enabled = false
            }
        } catch (_: Throwable) {
        }
        try {
            effect.release()
        } catch (_: Throwable) {
        }
    }

    /** Last resort from the crash handler: let every app be heard again. */
    fun releaseAll() {
        live.toList().forEach { release(it) }
    }

    /**
     * Attaches to an orphaned mute effect on [sessionId], neutralizes it and
     * releases it for good (an explicit release unpins it, so AudioFlinger
     * removes it). Returns false if the session could not be reached.
     */
    fun clearOrphan(sessionId: Int, type: String): Boolean {
        val fx = (if (type == TYPE_DYNAMICS) newDynamics(sessionId) else newVolume(sessionId)) ?: return false
        release(fx)
        return true
    }

    private fun mute(fx: AudioEffect) {
        if (fx is DynamicsProcessing) {
            fx.setInputGainAllChannelsTo(MUTE_DB)
        } else {
            val set = volumeSetParameter ?: throw IllegalStateException("no setParameter")
            set.invoke(fx, VOLUME_PARAM_MUTE, 1)
            set.invoke(fx, VOLUME_PARAM_LEVEL, -9600)
        }
        fx.enabled = true
    }

    private fun unmute(fx: AudioEffect) {
        if (fx is DynamicsProcessing) {
            fx.setInputGainAllChannelsTo(0f)
        } else {
            volumeSetParameter?.invoke(fx, VOLUME_PARAM_MUTE, 0)
            volumeSetParameter?.invoke(fx, VOLUME_PARAM_LEVEL, 0)
        }
    }

    private fun newDynamics(sessionId: Int): AudioEffect? = try {
        DynamicsProcessing(Int.MAX_VALUE, sessionId, null).also { live += it }
    } catch (t: Throwable) {
        Log.w(TAG, "DynamicsProcessing on session $sessionId failed: ${t.message}")
        null
    }

    private fun newVolume(sessionId: Int): AudioEffect? = try {
        val ctor = HiddenApiBypass.getDeclaredConstructor(
            AudioEffect::class.java,
            UUID::class.java, UUID::class.java, Int::class.javaPrimitiveType, Int::class.javaPrimitiveType,
        )
        (ctor.newInstance(UUID.fromString(TYPE_VOLUME), TYPE_NULL, Int.MAX_VALUE, sessionId) as AudioEffect)
            .also { live += it }
    } catch (t: Throwable) {
        Log.w(TAG, "Volume effect on session $sessionId failed: ${t.message}")
        null
    }
}

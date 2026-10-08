package com.nomosi9a.app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.util.Log
import com.nomosi9a.app.engine.session.MuteEffect
import com.nomosi9a.app.engine.session.OrphanSweeper
import org.lsposed.hiddenapibypass.HiddenApiBypass

class NoMosi9aApp : Application() {

    override fun onCreate() {
        super.onCreate()
        try {
            // ServiceManager (to read the audio session list) and the hidden
            // AudioEffect constructor (mute fallback) are not public SDK.
            HiddenApiBypass.addHiddenApiExemptions(
                "Landroid/os/ServiceManager;",
                "Landroid/media/audiofx/AudioEffect;",
            )
        } catch (t: Throwable) {
            Log.w(TAG, "hidden API exemption failed", t)
        }
        createNotificationChannel()
        installCrashGuard()
        // A previous run may have been killed while muting apps (force stop,
        // update): make sure nothing stays silent because of us.
        OrphanSweeper.sweepAsync(this)
    }

    /** On a crash, unmute every app before the process dies. */
    private fun installCrashGuard() {
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, error ->
            try {
                MuteEffect.releaseAll()
            } catch (_: Throwable) {
            }
            previous?.uncaughtException(thread, error)
        }
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ENGINE,
            getString(R.string.channel_engine),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            setShowBadge(false)
            setSound(null, null)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    companion object {
        const val TAG = "NoMosi9a"
        const val CHANNEL_ENGINE = "engine"
    }
}

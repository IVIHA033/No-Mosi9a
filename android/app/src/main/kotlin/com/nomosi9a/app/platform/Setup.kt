package com.nomosi9a.app.platform

import android.Manifest
import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionConfig
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.util.Log
import com.nomosi9a.app.NoMosi9aApp.Companion.TAG
import com.nomosi9a.app.engine.session.MuteEffect
import rikka.shizuku.Shizuku
import java.util.concurrent.TimeUnit

/** What the app needs from the system, and the helpers that obtain it. */
object Setup {

    fun hasRecordAudio(context: Context) = granted(context, Manifest.permission.RECORD_AUDIO)

    fun hasNotifications(context: Context) =
        Build.VERSION.SDK_INT < 33 || granted(context, Manifest.permission.POST_NOTIFICATIONS)

    /** Granted once over ADB/Shizuku: lets us find (and mute) other apps' audio sessions. */
    fun hasDump(context: Context) = granted(context, Manifest.permission.DUMP)

    /** Optional: skips the capture consent dialog and keeps capturing on the lock screen. */
    fun hasProjectMediaOp(context: Context): Boolean = try {
        val ops = context.getSystemService(AppOpsManager::class.java)
        ops.unsafeCheckOpNoThrow("android:project_media", Process.myUid(), context.packageName) ==
            AppOpsManager.MODE_ALLOWED
    } catch (_: Throwable) {
        false
    }

    fun isReady(context: Context) = hasRecordAudio(context) && hasDump(context)

    fun runtimePermissions(): Array<String> =
        if (Build.VERSION.SDK_INT >= 33) {
            arrayOf(Manifest.permission.RECORD_AUDIO, Manifest.permission.POST_NOTIFICATIONS)
        } else {
            arrayOf(Manifest.permission.RECORD_AUDIO)
        }

    fun projectionIntent(context: Context): Intent {
        val mpm = context.getSystemService(MediaProjectionManager::class.java)
        // Whole-screen config: no "single app" picker, audio of every app is capturable.
        return if (Build.VERSION.SDK_INT >= 34) {
            mpm.createScreenCaptureIntent(MediaProjectionConfig.createConfigForDefaultDisplay())
        } else {
            mpm.createScreenCaptureIntent()
        }
    }

    fun read(context: Context): Map<String, Any?> {
        val pm = context.getSystemService(PowerManager::class.java)
        return mapOf(
            "recordAudio" to hasRecordAudio(context),
            "notifications" to hasNotifications(context),
            "dump" to hasDump(context),
            "projectMedia" to hasProjectMediaOp(context),
            "muteSupported" to MuteEffect.isSupported(),
            "batteryUnrestricted" to pm.isIgnoringBatteryOptimizations(context.packageName),
            "shizukuInstalled" to ShizukuSetup.isInstalled(context),
            "shizukuRunning" to ShizukuSetup.isRunning(),
            "shizukuGranted" to ShizukuSetup.isGranted(),
            "sdk" to Build.VERSION.SDK_INT,
            "release" to Build.VERSION.RELEASE,
            "device" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "packageName" to context.packageName,
            "version" to versionName(context),
            "adbCommands" to adbCommands(context.packageName),
        )
    }

    /** The one-time commands, shown in the UI with a copy button. */
    fun adbCommands(pkg: String): List<String> = listOf(
        "adb shell pm grant $pkg android.permission.DUMP",
        "adb shell appops set $pkg PROJECT_MEDIA allow",
    )

    private fun versionName(context: Context): String = try {
        context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: ""
    } catch (_: Throwable) {
        ""
    }

    private fun granted(context: Context, permission: String) =
        context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
}

/**
 * Optional path for people without a computer: Shizuku runs a shell-level
 * service on the phone (wireless debugging), which can grant the same
 * permissions the ADB commands grant.
 */
object ShizukuSetup {
    const val PACKAGE = "moe.shizuku.privileged.api"
    const val REQUEST_CODE = 4711

    fun isInstalled(context: Context): Boolean = try {
        context.packageManager.getPackageInfo(PACKAGE, 0)
        true
    } catch (_: Throwable) {
        false
    }

    fun isRunning(): Boolean = try {
        Shizuku.pingBinder()
    } catch (_: Throwable) {
        false
    }

    fun isGranted(): Boolean = try {
        isRunning() && !Shizuku.isPreV11() &&
            Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
    } catch (_: Throwable) {
        false
    }

    fun requestPermission(onResult: (Boolean) -> Unit) {
        val listener = object : Shizuku.OnRequestPermissionResultListener {
            override fun onRequestPermissionResult(requestCode: Int, grantResult: Int) {
                if (requestCode != REQUEST_CODE) return
                Shizuku.removeRequestPermissionResultListener(this)
                onResult(grantResult == PackageManager.PERMISSION_GRANTED)
            }
        }
        Shizuku.addRequestPermissionResultListener(listener)
        Shizuku.requestPermission(REQUEST_CODE)
    }

    /** Runs the grant commands as the shell user. Blocking; call off the main thread. */
    fun grantAll(context: Context): Boolean {
        val pkg = context.packageName
        val commands = buildList {
            add("pm grant $pkg android.permission.DUMP")
            add("appops set $pkg PROJECT_MEDIA allow")
            add("pm grant $pkg android.permission.RECORD_AUDIO")
            if (Build.VERSION.SDK_INT >= 33) add("pm grant $pkg android.permission.POST_NOTIFICATIONS")
        }
        return try {
            // Shizuku 13 keeps newProcess private; it is still the simplest way to run a command.
            val newProcess = Shizuku::class.java.getDeclaredMethod(
                "newProcess", Array<String>::class.java, Array<String>::class.java, String::class.java,
            ).apply { isAccessible = true }
            val process = newProcess.invoke(
                null, arrayOf("sh", "-c", commands.joinToString(" ; ")), null, null,
            ) as java.lang.Process
            if (!process.waitFor(10, TimeUnit.SECONDS)) process.destroy()
            Setup.hasDump(context)
        } catch (t: Throwable) {
            Log.e(TAG, "Shizuku grant failed", t)
            false
        }
    }
}

package com.nomosi9a.app

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import com.nomosi9a.app.engine.EngineService
import com.nomosi9a.app.engine.EngineStatus
import com.nomosi9a.app.platform.EngineSettings
import com.nomosi9a.app.platform.Setup
import com.nomosi9a.app.platform.ShizukuSetup
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    private val main = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()
    private lateinit var settings: EngineSettings
    private var pendingStart: MethodChannel.Result? = null
    private var pendingPermissions: MethodChannel.Result? = null
    private var sink: EventChannel.EventSink? = null
    private val statusListener: (EngineStatus.Snapshot) -> Unit = { sink?.success(it.toMap()) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        settings = EngineSettings(this)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "nomosi9a/engine").setMethodCallHandler(::onMethodCall)
        EventChannel(messenger, "nomosi9a/status").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                sink = events
                EngineStatus.addListener(statusListener)
            }

            override fun onCancel(arguments: Any?) {
                EngineStatus.removeListener(statusListener)
                sink = null
            }
        })
    }

    override fun onDestroy() {
        EngineStatus.removeListener(statusListener)
        io.shutdown()
        super.onDestroy()
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSetup" -> result.success(Setup.read(this))
            "requestPermissions" -> requestRuntimePermissions(result)
            "grantWithShizuku" -> grantWithShizuku(result)
            "start" -> startEngine(result)
            "stop" -> {
                EngineService.stop(this)
                result.success(null)
            }
            "getStatus" -> result.success(EngineStatus.current.toMap())
            "getSettings" -> result.success(settings.toMap())
            "updateSettings" -> {
                (call.arguments as? Map<*, *>)?.let(settings::update)
                result.success(settings.toMap())
            }
            "rerunSpeedTest" -> {
                settings.autoModel = null
                result.success(null)
            }
            "listApps" -> background(result) { listLaunchableApps() }
            "appIcons" -> {
                val packages = (call.arguments as? List<*>)?.filterIsInstance<String>().orEmpty()
                background(result) { packages.associateWith { iconPng(it) }.filterValues { it != null } }
            }
            "openBatterySettings" -> result.success(
                open(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)),
            )
            "openAppSettings" -> result.success(
                open(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))),
            )
            "openShizuku" -> {
                val launch = packageManager.getLaunchIntentForPackage(ShizukuSetup.PACKAGE)
                result.success(
                    if (launch != null) open(launch)
                    else open(Intent(Intent.ACTION_VIEW, Uri.parse("https://shizuku.rikka.app/download/"))),
                )
            }
            "openUrl" -> result.success(
                (call.arguments as? String)?.let { open(Intent(Intent.ACTION_VIEW, Uri.parse(it))) } ?: false,
            )
            else -> result.notImplemented()
        }
    }

    private fun requestRuntimePermissions(result: MethodChannel.Result) {
        val missing = Setup.runtimePermissions().filter {
            checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isEmpty()) {
            result.success(Setup.read(this))
            return
        }
        pendingPermissions?.success(Setup.read(this))
        pendingPermissions = result
        requestPermissions(missing.toTypedArray(), REQUEST_PERMISSIONS)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_PERMISSIONS) {
            pendingPermissions?.success(Setup.read(this))
            pendingPermissions = null
        }
    }

    private fun grantWithShizuku(result: MethodChannel.Result) {
        if (!ShizukuSetup.isRunning()) {
            result.success(Setup.read(this) + ("shizukuError" to "not_running"))
            return
        }
        val grant = {
            background(result) {
                val ok = ShizukuSetup.grantAll(this)
                Setup.read(this) + ("shizukuError" to if (ok) null else "grant_failed")
            }
        }
        if (ShizukuSetup.isGranted()) {
            grant()
        } else {
            ShizukuSetup.requestPermission { granted ->
                main.post {
                    if (granted) grant()
                    else result.success(Setup.read(this) + ("shizukuError" to "denied"))
                }
            }
        }
    }

    private fun startEngine(result: MethodChannel.Result) {
        if (EngineStatus.isActive) {
            result.success(true)
            return
        }
        if (!Setup.isReady(this)) {
            result.error("setup_missing", "Finish the setup first", null)
            return
        }
        pendingStart?.success(false)
        pendingStart = result
        try {
            @Suppress("DEPRECATION")
            startActivityForResult(Setup.projectionIntent(this), REQUEST_PROJECTION)
        } catch (e: ActivityNotFoundException) {
            pendingStart = null
            result.error("projection_unavailable", e.message, null)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_PROJECTION) return
        val result = pendingStart ?: return
        pendingStart = null
        if (resultCode == RESULT_OK && data != null) {
            EngineService.start(this, resultCode, data)
            result.success(true)
        } else {
            result.success(false)
        }
    }

    private fun listLaunchableApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return pm.queryIntentActivities(launcher, 0)
            .map { it.activityInfo.packageName }
            .distinct()
            .filter { it != packageName }
            .mapNotNull { pkg ->
                try {
                    val info = pm.getApplicationInfo(pkg, 0)
                    mapOf(
                        "package" to pkg,
                        "label" to pm.getApplicationLabel(info).toString(),
                        "icon" to iconPng(pkg),
                    )
                } catch (_: Throwable) {
                    null
                }
            }
            .sortedBy { (it["label"] as String).lowercase() }
    }

    private fun iconPng(pkg: String, size: Int = 96): ByteArray? = try {
        val drawable = packageManager.getApplicationIcon(pkg)
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(canvas)
        ByteArrayOutputStream().use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            bitmap.recycle()
            out.toByteArray()
        }
    } catch (_: Throwable) {
        null
    }

    private fun open(intent: Intent): Boolean = try {
        startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (_: Throwable) {
        false
    }

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        io.execute {
            val value = try {
                Result.success(work())
            } catch (t: Throwable) {
                Result.failure(t)
            }
            main.post {
                value.fold(
                    onSuccess = { result.success(it) },
                    onFailure = { result.error("failed", it.message, null) },
                )
            }
        }
    }

    private companion object {
        const val REQUEST_PROJECTION = 100
        const val REQUEST_PERMISSIONS = 101
    }
}

package com.nomosi9a.app.engine

import ai.onnxruntime.OrtEnvironment
import android.app.Activity
import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ApplicationInfo
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.widget.Toast
import com.nomosi9a.app.MainActivity
import com.nomosi9a.app.NoMosi9aApp
import com.nomosi9a.app.NoMosi9aApp.Companion.TAG
import com.nomosi9a.app.R
import com.nomosi9a.app.engine.session.OrphanSweeper
import com.nomosi9a.app.engine.session.SessionMuter
import com.nomosi9a.app.platform.EngineSettings
import java.io.File
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.util.concurrent.Executors
import kotlin.random.Random

/**
 * Foreground service that owns the capture session: it keeps other apps
 * muted at the speaker and plays back their audio with the music removed.
 *
 * Fields are touched on the main thread only; anything that blocks (stopping
 * the audio thread, releasing effects) runs on [worker], in order.
 */
class EngineService : Service() {

    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor { Thread(it, "NoMosi9a-lifecycle") }
    private lateinit var settings: EngineSettings
    private var projection: MediaProjection? = null
    private var muter: SessionMuter? = null
    private var pipeline: AudioPipeline? = null

    /** Bumped on every start, so late work from a previous run can't touch the new one. */
    private var generation = 0

    @Volatile
    private var activeModel: ModelSpec? = null

    /** Word-cut protection of the denoiser currently playing (set on the audio thread). */
    @Volatile
    private var guard: SpeechGuard? = null

    @Volatile
    private var stopping = false

    @Volatile
    private var excludedUids: Set<Int> = emptySet()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        settings = EngineSettings(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> shutdown(error = null)
            ACTION_START -> {
                if (projection != null) return START_NOT_STICKY
                val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, Activity.RESULT_CANCELED)
                @Suppress("DEPRECATION")
                val data: Intent? = if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(EXTRA_RESULT_DATA, Intent::class.java)
                } else {
                    intent.getParcelableExtra(EXTRA_RESULT_DATA)
                }
                begin(resultCode, data)
            }
            // Restarted by the system without a projection token: nothing to do.
            else -> if (projection == null) stopSelf()
        }
        return START_NOT_STICKY
    }

    private fun begin(resultCode: Int, data: Intent?) {
        stopping = false
        generation++
        EngineStatus.update { EngineStatus.Snapshot(state = EngineStatus.State.STARTING) }
        // Android 14+: the service must be in the foreground before it may use the token.
        startForeground(NOTIFICATION_ID, buildNotification(emptyList()), foregroundType())
        val mpm = getSystemService(MediaProjectionManager::class.java)
        val mp = try {
            if (data == null) null else mpm.getMediaProjection(resultCode, data)
        } catch (t: Throwable) {
            Log.e(TAG, "getMediaProjection failed", t)
            null
        }
        if (mp == null) {
            shutdown(error = "projection_denied")
            return
        }
        projection = mp
        mp.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                if (!stopping) main.post { shutdown(error = "projection_revoked") }
            }
        }, main)
        refreshExcludedUids()
        settings.register(settingsListener)
        // Leftovers from a killed run would fight our fresh effects.
        worker.execute { OrphanSweeper.sweep(this) }
        // The muter starts once capture is live (see onStarted): muting first
        // would leave the video silent while the model loads.
        startPipeline()
    }

    /**
     * Android 11 gates playback capture on the microphone app-op, which a
     * background service only holds with the microphone type. Android 12+
     * uses a separate op for it, so the plain media projection type suffices.
     */
    private fun foregroundType(): Int =
        if (Build.VERSION.SDK_INT == Build.VERSION_CODES.R) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
        } else {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
        }

    private fun startPipeline() {
        val mp = projection ?: return
        val p = AudioPipeline(
            projection = mp,
            createDenoiser = ::createDenoiser,
            excludedUids = { excludedUids },
            latencyMode = settings.latency,
            listener = pipelineListener,
            debugDir = filesDir.takeIf {
                (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0 &&
                    File(it, "debug_record").exists()
            },
        )
        p.boostDb = settings.boostDb
        pipeline = p
        p.start()
    }

    private fun restartPipeline() {
        val old = pipeline ?: return
        pipeline = null
        val gen = generation
        worker.execute {
            old.stop()
            main.post {
                if (!stopping && gen == generation && pipeline == null) startPipeline()
            }
        }
    }

    private fun startMuterIfNeeded() {
        if (muter != null || stopping || projection == null) return
        muter = SessionMuter(
            this,
            isExcluded = { uid -> uid in excludedUids },
            onAppsChanged = { apps ->
                if (!stopping) {
                    EngineStatus.update { it.copy(apps = apps) }
                    main.post { updateNotification(apps) }
                }
            },
        ).also {
            it.onDumpUnavailable = { main.post { shutdown(error = "setup_missing") } }
            it.start()
        }
    }

    /** User exclusions plus the packages we never touch, as uids (capture works on uids). */
    private fun refreshExcludedUids() {
        excludedUids = (settings.excludedPackages + SessionMuter.NEVER_TOUCH).mapNotNull { pkg ->
            try {
                packageManager.getApplicationInfo(pkg, 0).uid
            } catch (_: Throwable) {
                null
            }
        }.toSet()
    }

    /** Runs on the audio thread. */
    private fun createDenoiser(): Denoiser {
        val env = OrtEnvironment.getEnvironment()
        try {
            env.setTelemetry(false)
        } catch (_: Throwable) {
        }
        // A model chosen by hand wins; otherwise the result of the speed test.
        val chosen = if (settings.quality == "auto") settings.autoModel else settings.quality
        val spec = ModelSpec.fromId(chosen)
        val denoiser = if (spec == null) {
            benchmarkAndPick(env)
        } else {
            activeModel = spec
            load(env, spec)
        }
        // Publish first, then apply the setting: a change made in between still reaches it.
        guard = denoiser.guard
        guard?.level = SpeechGuard.Level.fromId(settings.voiceProtection)
        return denoiser
    }

    /**
     * First start in "auto": try the models from best to lightest and keep the
     * first one this phone runs in at most [MAX_MODEL_LOAD] of real time.
     */
    private fun benchmarkAndPick(env: OrtEnvironment): Denoiser {
        val candidates = ModelSpec.entries
        for (spec in candidates) {
            val model = load(env, spec)
            val share = try {
                realTimeShare(model)
            } catch (t: Throwable) {
                model.close()
                throw t
            }
            Log.i(TAG, "speed test: ${spec.id} uses %.0f%% of real time".format(share * 100))
            if (share <= MAX_MODEL_LOAD || spec == candidates.last()) {
                settings.autoModel = spec.id
                activeModel = spec
                model.reset()
                return model
            }
            model.close()
        }
        error("no model")
    }

    /** Time spent per hop divided by the hop duration, on noise. */
    private fun realTimeShare(model: Denoiser): Double {
        val hop = model.hopSize
        val input = FloatArray(hop)
        val output = FloatArray(hop)
        val rnd = Random(7)
        repeat(20) {
            for (i in 0 until hop) input[i] = (rnd.nextFloat() - 0.5f) * 0.1f
            model.process(input, output)
        }
        val runs = 80
        val t0 = System.nanoTime()
        repeat(runs) {
            for (i in 0 until hop) input[i] = (rnd.nextFloat() - 0.5f) * 0.1f
            model.process(input, output)
        }
        val perHopNs = (System.nanoTime() - t0).toDouble() / runs
        return perHopNs / (hop * 1e9 / model.sampleRate)
    }

    private fun load(env: OrtEnvironment, spec: ModelSpec): Denoiser =
        DpdfnetDenoiser.load(env, mapAsset(spec.asset), loadDetectors(env))

    /** The speech guard is a safety net: without its detectors the engine still runs, as before. */
    private fun loadDetectors(env: OrtEnvironment): Pair<SileroVad, SileroVad>? {
        var first: SileroVad? = null
        return try {
            first = SileroVad.load(env, mapAsset(VAD_ASSET))
            first to SileroVad.load(env, mapAsset(VAD_ASSET))
        } catch (t: Throwable) {
            first?.close()
            Log.e(TAG, "speech detector unavailable, words are not protected", t)
            null
        }
    }

    /** Models are stored uncompressed in the APK, so they can be memory-mapped. */
    private fun mapAsset(path: String): ByteBuffer =
        assets.openFd(path).use { afd ->
            FileInputStream(afd.fileDescriptor).use { stream ->
                stream.channel.map(FileChannel.MapMode.READ_ONLY, afd.startOffset, afd.declaredLength)
            }
        }

    /** Called on the audio thread. */
    private val pipelineListener = object : AudioPipeline.Listener {
        override fun onStarted(sampleRate: Int, latencyMs: Int) {
            if (stopping) return
            EngineStatus.update {
                it.copy(
                    state = EngineStatus.State.RUNNING,
                    error = null,
                    model = activeModel?.id,
                    sampleRate = sampleRate,
                    latencyMs = latencyMs,
                    startedAt = if (it.startedAt == 0L) System.currentTimeMillis() else it.startedAt,
                )
            }
            main.post { startMuterIfNeeded() }
        }

        override fun onLevels(inputDb: Float, outputDb: Float, load: Float, speaking: Boolean) {
            if (stopping) return
            EngineStatus.update { it.copy(inputDb = inputDb, outputDb = outputDb, load = load, speaking = speaking) }
        }

        override fun onOverload() {
            main.post {
                val lighter = activeModel?.let { ModelSpec.entries.getOrNull(it.ordinal + 1) }
                if (!stopping && settings.quality == "auto" && lighter != null) {
                    Log.w(TAG, "${activeModel?.id} too slow here, switching to ${lighter.id}")
                    settings.autoModel = lighter.id
                    EngineStatus.update { it.copy(autoSwitched = true) }
                    restartPipeline()
                }
            }
        }

        override fun onFatal(reason: String, error: Throwable?) {
            main.post { shutdown(error = reason) }
        }
    }

    private val settingsListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        when (key) {
            EngineSettings.KEY_BOOST -> pipeline?.boostDb = settings.boostDb
            EngineSettings.KEY_PROTECTION -> guard?.level = SpeechGuard.Level.fromId(settings.voiceProtection)
            EngineSettings.KEY_EXCLUDED -> {
                refreshExcludedUids()
                muter?.refresh()
                pipeline?.recapture()
            }
            EngineSettings.KEY_QUALITY, EngineSettings.KEY_LATENCY -> restartPipeline()
        }
    }

    private fun shutdown(error: String?) {
        if (stopping) return
        stopping = true
        settings.unregister(settingsListener)
        EngineStatus.update {
            EngineStatus.Snapshot(
                state = if (error == null) EngineStatus.State.STOPPED else EngineStatus.State.ERROR,
                error = error,
            )
        }
        if (error == "projection_revoked") toast(R.string.toast_projection_revoked)
        if (error == "projection_denied") toast(R.string.toast_projection_denied)

        val m = muter
        val p = pipeline
        val mp = projection
        val gen = generation
        muter = null
        pipeline = null
        projection = null
        worker.execute {
            m?.stop() // other apps are audible again first...
            p?.stop() // ...then our copy goes quiet
            try {
                mp?.stop()
            } catch (_: Throwable) {
            }
            main.post {
                if (stopping && gen == generation) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                }
            }
        }
    }

    override fun onDestroy() {
        shutdown(error = null)
        worker.shutdown()
        super.onDestroy()
    }

    private fun toast(res: Int) = Toast.makeText(applicationContext, res, Toast.LENGTH_LONG).show()

    private fun updateNotification(apps: List<EngineStatus.App>) {
        if (stopping) return
        getSystemService(NotificationManager::class.java).notify(NOTIFICATION_ID, buildNotification(apps))
    }

    private fun buildNotification(apps: List<EngineStatus.App>): Notification {
        val open = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val stop = PendingIntent.getService(
            this, 1,
            Intent(this, EngineService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val cleaned = apps.filter { it.muted }.joinToString(", ") { it.label }
        val text = if (cleaned.isEmpty()) getString(R.string.notif_text_idle)
        else getString(R.string.notif_text_apps, cleaned)
        return Notification.Builder(this, NoMosi9aApp.CHANNEL_ENGINE)
            .setSmallIcon(R.drawable.ic_stat_engine)
            .setContentTitle(getString(R.string.notif_title))
            .setContentText(text)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setContentIntent(open)
            .addAction(
                Notification.Action.Builder(null as Icon?, getString(R.string.notif_action_stop), stop).build(),
            )
            .apply {
                if (Build.VERSION.SDK_INT >= 31) {
                    setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
                }
            }
            .build()
    }

    companion object {
        const val ACTION_START = "com.nomosi9a.app.START"
        const val ACTION_STOP = "com.nomosi9a.app.STOP"
        private const val EXTRA_RESULT_CODE = "resultCode"
        private const val EXTRA_RESULT_DATA = "resultData"
        private const val NOTIFICATION_ID = 42

        private const val VAD_ASSET = "models/silero_vad.onnx"

        /** A model is picked only if it needs at most this share of real time (headroom for heat). */
        private const val MAX_MODEL_LOAD = 0.45

        fun start(context: Context, resultCode: Int, data: Intent) {
            val intent = Intent(context, EngineService::class.java)
                .setAction(ACTION_START)
                .putExtra(EXTRA_RESULT_CODE, resultCode)
                .putExtra(EXTRA_RESULT_DATA, data)
            context.startForegroundService(intent)
        }

        fun stop(context: Context) {
            if (!EngineStatus.isActive) return
            context.startService(Intent(context, EngineService::class.java).setAction(ACTION_STOP))
        }
    }
}

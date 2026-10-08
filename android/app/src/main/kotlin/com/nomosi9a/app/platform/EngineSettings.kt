package com.nomosi9a.app.platform

import android.content.Context
import android.content.SharedPreferences

/**
 * Settings shared by the Flutter UI (through the method channel) and the
 * engine service, which runs even when the UI is closed.
 */
class EngineSettings(context: Context) {

    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences("engine_settings", Context.MODE_PRIVATE)

    /** "auto", "full", "balanced" or "light". */
    var quality: String
        get() = prefs.getString(KEY_QUALITY, "auto") ?: "auto"
        set(value) = prefs.edit().putString(KEY_QUALITY, value).apply()

    /** Extra loudness applied to the cleaned voice, 0..12 dB. */
    var boostDb: Float
        get() = prefs.getFloat(KEY_BOOST, 3f)
        set(value) = prefs.edit().putFloat(KEY_BOOST, value.coerceIn(0f, 12f)).apply()

    /**
     * "off", "normal" or "strong": how much the speech guard keeps words the
     * model would cut (see SpeechGuard). Stronger keeps more speech and lets a
     * little more music through while someone talks.
     */
    var voiceProtection: String
        get() = prefs.getString(KEY_PROTECTION, "normal") ?: "normal"
        set(value) = prefs.edit().putString(KEY_PROTECTION, value).apply()

    /** "low", "normal" or "stable": how much audio we buffer on the way out. */
    var latency: String
        get() = prefs.getString(KEY_LATENCY, "normal") ?: "normal"
        set(value) = prefs.edit().putString(KEY_LATENCY, value).apply()

    /** Packages left untouched (not captured, not muted). */
    var excludedPackages: Set<String>
        get() = prefs.getStringSet(KEY_EXCLUDED, emptySet())?.toSet() ?: emptySet()
        set(value) = prefs.edit().putStringSet(KEY_EXCLUDED, value.toSet()).apply()

    /** "system", "en", "ar" or "fr" (read by the Flutter UI only). */
    var locale: String
        get() = prefs.getString(KEY_LOCALE, "system") ?: "system"
        set(value) = prefs.edit().putString(KEY_LOCALE, value).apply()

    /** Result of the one-time speed test used by quality = "auto". */
    var autoModel: String?
        get() = prefs.getString(KEY_AUTO_MODEL, null)
        set(value) = prefs.edit().putString(KEY_AUTO_MODEL, value).apply()

    var onboardingDone: Boolean
        get() = prefs.getBoolean(KEY_ONBOARDING, false)
        set(value) = prefs.edit().putBoolean(KEY_ONBOARDING, value).apply()

    fun toMap(): Map<String, Any?> = mapOf(
        KEY_QUALITY to quality,
        KEY_BOOST to boostDb.toDouble(),
        KEY_LATENCY to latency,
        KEY_PROTECTION to voiceProtection,
        KEY_EXCLUDED to excludedPackages.sorted(),
        KEY_LOCALE to locale,
        KEY_AUTO_MODEL to autoModel,
        KEY_ONBOARDING to onboardingDone,
    )

    fun update(values: Map<*, *>) {
        (values[KEY_QUALITY] as? String)?.let { if (it in QUALITIES) quality = it }
        (values[KEY_BOOST] as? Number)?.let { boostDb = it.toFloat() }
        (values[KEY_LATENCY] as? String)?.let { if (it in LATENCIES) latency = it }
        (values[KEY_PROTECTION] as? String)?.let { if (it in PROTECTIONS) voiceProtection = it }
        (values[KEY_EXCLUDED] as? List<*>)?.let { list -> excludedPackages = list.filterIsInstance<String>().toSet() }
        (values[KEY_LOCALE] as? String)?.let { locale = it }
        (values[KEY_ONBOARDING] as? Boolean)?.let { onboardingDone = it }
    }

    fun register(listener: SharedPreferences.OnSharedPreferenceChangeListener) =
        prefs.registerOnSharedPreferenceChangeListener(listener)

    fun unregister(listener: SharedPreferences.OnSharedPreferenceChangeListener) =
        prefs.unregisterOnSharedPreferenceChangeListener(listener)

    companion object {
        const val KEY_QUALITY = "quality"
        const val KEY_BOOST = "boostDb"
        const val KEY_LATENCY = "latency"
        const val KEY_PROTECTION = "voiceProtection"
        const val KEY_EXCLUDED = "excludedPackages"
        const val KEY_LOCALE = "locale"
        const val KEY_AUTO_MODEL = "autoModel"
        const val KEY_ONBOARDING = "onboardingDone"

        private val QUALITIES = setOf("auto", "full", "balanced", "light")
        private val LATENCIES = setOf("low", "normal", "stable")
        private val PROTECTIONS = setOf("off", "normal", "strong")
    }
}

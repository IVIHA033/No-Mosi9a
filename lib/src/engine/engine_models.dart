import 'package:flutter/foundation.dart';

enum EngineState { stopped, starting, running, error }

/// One app whose audio the engine is handling.
@immutable
class EngineApp {
  const EngineApp({
    required this.packageName,
    required this.label,
    required this.muted,
    required this.blocked,
  });

  factory EngineApp.fromMap(Map<Object?, Object?> map) => EngineApp(
        packageName: map['package'] as String? ?? '',
        label: map['label'] as String? ?? '',
        muted: map['muted'] as bool? ?? false,
        blocked: map['blocked'] as bool? ?? false,
      );

  final String packageName;
  final String label;

  /// The original sound is silenced and the user hears the cleaned copy.
  final bool muted;

  /// The app forbids audio capture: it keeps playing unchanged.
  final bool blocked;
}

/// Live state pushed by the native engine (~15 times per second while running).
@immutable
class EngineStatus {
  const EngineStatus({
    this.state = EngineState.stopped,
    this.error,
    this.model,
    this.autoSwitched = false,
    this.sampleRate = 0,
    this.latencyMs = 0,
    this.load = 0,
    this.inputDb = -120,
    this.outputDb = -120,
    this.speaking = false,
    this.apps = const [],
  });

  factory EngineStatus.fromMap(Map<Object?, Object?> map) => EngineStatus(
        state: EngineState.values.firstWhere(
          (s) => s.name == map['state'],
          orElse: () => EngineState.stopped,
        ),
        error: map['error'] as String?,
        model: map['model'] as String?,
        autoSwitched: map['autoSwitched'] as bool? ?? false,
        sampleRate: (map['sampleRate'] as num?)?.toInt() ?? 0,
        latencyMs: (map['latencyMs'] as num?)?.toInt() ?? 0,
        load: (map['load'] as num?)?.toDouble() ?? 0,
        inputDb: (map['inputDb'] as num?)?.toDouble() ?? -120,
        outputDb: (map['outputDb'] as num?)?.toDouble() ?? -120,
        speaking: map['speaking'] as bool? ?? false,
        apps: [
          for (final a in (map['apps'] as List<Object?>? ?? const []))
            EngineApp.fromMap(a! as Map<Object?, Object?>),
        ],
      );

  final EngineState state;

  /// Machine-readable reason when [state] is [EngineState.error].
  final String? error;

  /// "full", "balanced" or "light".
  final String? model;
  final bool autoSwitched;
  final int sampleRate;
  final int latencyMs;

  /// Share of the real-time budget the model uses (1.0 = barely keeping up).
  final double load;
  final double inputDb;
  final double outputDb;

  /// Someone is talking and voice protection is keeping their words.
  final bool speaking;
  final List<EngineApp> apps;

  bool get isActive => state == EngineState.running || state == EngineState.starting;
}

/// What the phone has granted so far.
@immutable
class SetupInfo {
  const SetupInfo({
    this.recordAudio = false,
    this.notifications = false,
    this.dump = false,
    this.projectMedia = false,
    this.muteSupported = true,
    this.batteryUnrestricted = false,
    this.shizukuInstalled = false,
    this.shizukuRunning = false,
    this.shizukuGranted = false,
    this.shizukuError,
    this.sdk = 0,
    this.device = '',
    this.packageName = '',
    this.version = '',
    this.adbCommands = const [],
  });

  factory SetupInfo.fromMap(Map<Object?, Object?> map) => SetupInfo(
        recordAudio: map['recordAudio'] as bool? ?? false,
        notifications: map['notifications'] as bool? ?? false,
        dump: map['dump'] as bool? ?? false,
        projectMedia: map['projectMedia'] as bool? ?? false,
        muteSupported: map['muteSupported'] as bool? ?? true,
        batteryUnrestricted: map['batteryUnrestricted'] as bool? ?? false,
        shizukuInstalled: map['shizukuInstalled'] as bool? ?? false,
        shizukuRunning: map['shizukuRunning'] as bool? ?? false,
        shizukuGranted: map['shizukuGranted'] as bool? ?? false,
        shizukuError: map['shizukuError'] as String?,
        sdk: (map['sdk'] as num?)?.toInt() ?? 0,
        device: map['device'] as String? ?? '',
        packageName: map['packageName'] as String? ?? '',
        version: map['version'] as String? ?? '',
        adbCommands: [
          for (final c in (map['adbCommands'] as List<Object?>? ?? const [])) c! as String,
        ],
      );

  final bool recordAudio;
  final bool notifications;
  final bool dump;
  final bool projectMedia;
  final bool muteSupported;
  final bool batteryUnrestricted;
  final bool shizukuInstalled;
  final bool shizukuRunning;
  final bool shizukuGranted;

  /// Set only in the reply to a Shizuku grant attempt.
  final String? shizukuError;
  final int sdk;
  final String device;
  final String packageName;
  final String version;
  final List<String> adbCommands;

  /// Everything the engine strictly needs.
  bool get ready => recordAudio && dump && muteSupported;
}

@immutable
class EngineSettings {
  const EngineSettings({
    this.quality = 'auto',
    this.boostDb = 3,
    this.latency = 'normal',
    this.voiceProtection = 'normal',
    this.excludedPackages = const [],
    this.locale = 'system',
    this.autoModel,
    this.onboardingDone = false,
  });

  factory EngineSettings.fromMap(Map<Object?, Object?> map) => EngineSettings(
        quality: map['quality'] as String? ?? 'auto',
        boostDb: (map['boostDb'] as num?)?.toDouble() ?? 3,
        latency: map['latency'] as String? ?? 'normal',
        voiceProtection: map['voiceProtection'] as String? ?? 'normal',
        excludedPackages: [
          for (final p in (map['excludedPackages'] as List<Object?>? ?? const [])) p! as String,
        ],
        locale: map['locale'] as String? ?? 'system',
        autoModel: map['autoModel'] as String?,
        onboardingDone: map['onboardingDone'] as bool? ?? false,
      );

  /// "auto", "full", "balanced" or "light".
  final String quality;
  final double boostDb;

  /// "low", "normal" or "stable".
  final String latency;

  /// "off", "normal" or "strong": how hard the engine keeps words the model would cut.
  final String voiceProtection;
  final List<String> excludedPackages;

  /// "system", "en", "ar" or "fr".
  final String locale;

  /// Model picked by the speed test when [quality] is "auto".
  final String? autoModel;
  final bool onboardingDone;
}

/// An installed app, for the "leave untouched" list.
@immutable
class InstalledApp {
  const InstalledApp({required this.packageName, required this.label, this.icon});

  factory InstalledApp.fromMap(Map<Object?, Object?> map) => InstalledApp(
        packageName: map['package'] as String? ?? '',
        label: map['label'] as String? ?? '',
        icon: map['icon'] as Uint8List?,
      );

  final String packageName;
  final String label;
  final Uint8List? icon;
}

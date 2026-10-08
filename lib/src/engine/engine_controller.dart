import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'engine_models.dart';

/// Talks to the native engine (Kotlin) and exposes its state to the UI.
///
/// Live status arrives ~15 times per second, so each piece of state is its own
/// [ValueNotifier]: the level meters rebuild on every tick, the rest of the
/// screen only when something it shows actually changes.
class EngineController with WidgetsBindingObserver {
  EngineController({
    MethodChannel method = const MethodChannel('nomosi9a/engine'),
    EventChannel events = const EventChannel('nomosi9a/status'),
  })  : _method = method,
        _events = events;

  final MethodChannel _method;
  final EventChannel _events;
  StreamSubscription<Object?>? _subscription;

  final ValueNotifier<EngineStatus> status = ValueNotifier(const EngineStatus());
  final ValueNotifier<SetupInfo> setup = ValueNotifier(const SetupInfo());
  final ValueNotifier<EngineSettings> settings = ValueNotifier(const EngineSettings());
  final ValueNotifier<Map<String, Uint8List>> icons = ValueNotifier(const {});
  final Set<String> _iconRequests = {};

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    try {
      await Future.wait([refreshSetup(), reloadSettings()]);
    } on PlatformException {
      // Keep the defaults; the setup screen will retry when the app resumes.
    }
    _subscription = _events.receiveBroadcastStream().listen(_onStatus, onError: (Object _) {});
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    status.dispose();
    setup.dispose();
    settings.dispose();
    icons.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Permissions are granted outside the app (ADB, Shizuku, system settings).
    if (state == AppLifecycleState.resumed) refreshSetup();
  }

  void _onStatus(Object? event) {
    if (event is! Map) return;
    final next = EngineStatus.fromMap(event);
    status.value = next;
    _requestIcons(next.apps.map((a) => a.packageName));
  }

  Future<SetupInfo> refreshSetup() async {
    final map = await _method.invokeMapMethod<Object?, Object?>('getSetup');
    return setup.value = SetupInfo.fromMap(map ?? const {});
  }

  /// The engine changes some settings itself (speed test, auto-switch to Light).
  Future<void> reloadSettings() async {
    final map = await _method.invokeMapMethod<Object?, Object?>('getSettings');
    settings.value = EngineSettings.fromMap(map ?? const {});
  }

  Future<SetupInfo> requestPermissions() async {
    final map = await _method.invokeMapMethod<Object?, Object?>('requestPermissions');
    return setup.value = SetupInfo.fromMap(map ?? const {});
  }

  /// Returns the new setup; [SetupInfo.shizukuError] explains a failure.
  Future<SetupInfo> grantWithShizuku() async {
    final map = await _method.invokeMapMethod<Object?, Object?>('grantWithShizuku');
    return setup.value = SetupInfo.fromMap(map ?? const {});
  }

  /// False when the user declined Android's capture prompt.
  Future<bool> start() async => await _method.invokeMethod<bool>('start') ?? false;

  Future<void> stop() => _method.invokeMethod<void>('stop');

  Future<void> updateSettings(Map<String, Object?> patch) async {
    final map = await _method.invokeMapMethod<Object?, Object?>('updateSettings', patch);
    settings.value = EngineSettings.fromMap(map ?? const {});
  }

  Future<void> rerunSpeedTest() async {
    await _method.invokeMethod<void>('rerunSpeedTest');
    await reloadSettings();
  }

  Future<List<InstalledApp>> listApps() async {
    final list = await _method.invokeListMethod<Object?>('listApps') ?? const [];
    final apps = [for (final m in list) InstalledApp.fromMap(m! as Map<Object?, Object?>)];
    icons.value = {
      ...icons.value,
      for (final a in apps)
        if (a.icon != null) a.packageName: a.icon!,
    };
    return apps;
  }

  Future<void> _requestIcons(Iterable<String> packages) async {
    final missing = packages
        .where((p) => !icons.value.containsKey(p) && !_iconRequests.contains(p) && !p.startsWith('uid:'))
        .toList();
    if (missing.isEmpty) return;
    _iconRequests.addAll(missing);
    try {
      final map = await _method.invokeMapMethod<String, Uint8List>('appIcons', missing);
      if (map != null && map.isNotEmpty) icons.value = {...icons.value, ...map};
    } on PlatformException {
      // Icons are cosmetic; the label is still shown.
    }
  }

  Future<bool> openBatterySettings() async =>
      await _method.invokeMethod<bool>('openBatterySettings') ?? false;

  Future<bool> openAppSettings() async => await _method.invokeMethod<bool>('openAppSettings') ?? false;

  Future<bool> openShizuku() async => await _method.invokeMethod<bool>('openShizuku') ?? false;
}

/// Makes the [EngineController] available to the widget tree.
class EngineScope extends InheritedWidget {
  const EngineScope({super.key, required this.controller, required super.child});

  final EngineController controller;

  static EngineController of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<EngineScope>()!.controller;

  @override
  bool updateShouldNotify(EngineScope oldWidget) => controller != oldWidget.controller;
}

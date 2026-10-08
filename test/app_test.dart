import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_mosi9a/src/app.dart';
import 'package:no_mosi9a/src/engine/engine_controller.dart';
import 'package:no_mosi9a/src/ui/home/power_button.dart';

/// Fake native engine: answers the method channel like the Kotlin side does.
class FakeEngine {
  FakeEngine({this.ready = true, this.onboardingDone = true});

  bool ready;
  bool onboardingDone;
  final calls = <String>[];
  MockStreamHandlerEventSink? sink;

  Map<String, Object?> get setup => {
        'recordAudio': ready,
        'notifications': true,
        'dump': ready,
        'projectMedia': false,
        'muteSupported': true,
        'adbCommands': ['adb shell pm grant com.nomosi9a.app android.permission.DUMP'],
        'version': '1.0.0',
      };

  Map<String, Object?> get settings => {
        'quality': 'auto',
        'boostDb': 3.0,
        'latency': 'normal',
        'excludedPackages': <String>[],
        'locale': 'en',
        'onboardingDone': onboardingDone,
      };

  void install() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('nomosi9a/engine'), (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'getSetup':
        case 'requestPermissions':
          return setup;
        case 'getSettings':
          return settings;
        case 'updateSettings':
          final patch = call.arguments as Map;
          if (patch['onboardingDone'] == true) onboardingDone = true;
          return settings;
        case 'start':
          sink?.success({'state': 'running', 'model': 'full', 'latencyMs': 90, 'apps': []});
          return true;
        case 'stop':
          sink?.success({'state': 'stopped'});
          return null;
        case 'appIcons':
          return <String, Object?>{};
      }
      return null;
    });
    messenger.setMockStreamHandler(
      const EventChannel('nomosi9a/status'),
      MockStreamHandler.inline(
        onListen: (args, events) {
          sink = events;
          events.success({'state': 'stopped'});
        },
      ),
    );
  }
}

Future<EngineController> pumpApp(WidgetTester tester, FakeEngine fake) async {
  fake.install();
  final controller = EngineController();
  await controller.init();
  await tester.pumpWidget(NoMosi9aApp(controller: controller));
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the setup until the one-time activation is done', (tester) async {
    await pumpApp(tester, FakeEngine(ready: false, onboardingDone: false));
    expect(find.text('One-time activation'), findsOneWidget);
    expect(find.text('adb shell pm grant com.nomosi9a.app android.permission.DUMP'), findsOneWidget);
  });

  testWidgets('home screen starts and stops the engine', (tester) async {
    final semantics = tester.ensureSemantics();
    final fake = FakeEngine();
    await pumpApp(tester, fake);
    expect(find.text('Music removal is off'), findsOneWidget);
    expect(find.bySemanticsLabel('Start music removal'), findsOneWidget);

    await tester.tap(find.byType(PowerButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(fake.calls, contains('start'));
    expect(find.text('Music removal is on'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);

    expect(find.bySemanticsLabel('Stop music removal'), findsOneWidget);
    await tester.tap(find.byType(PowerButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(fake.calls, contains('stop'));
    expect(find.text('Music removal is off'), findsOneWidget);
    semantics.dispose();
  });
}

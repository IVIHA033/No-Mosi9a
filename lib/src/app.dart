import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'engine/engine_controller.dart';
import 'engine/engine_models.dart';
import 'ui/home/home_screen.dart';
import 'ui/setup/setup_screen.dart';
import 'ui/theme.dart';

class NoMosi9aApp extends StatelessWidget {
  const NoMosi9aApp({super.key, required this.controller});

  final EngineController controller;

  @override
  Widget build(BuildContext context) {
    return EngineScope(
      controller: controller,
      child: ValueListenableBuilder<EngineSettings>(
        valueListenable: controller.settings,
        builder: (context, settings, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: buildTheme(),
          locale: settings.locale == 'system' ? null : Locale(settings.locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const _RootGate(),
        ),
      ),
    );
  }
}

/// Shows the setup until the phone is ready and the user went through it once.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final engine = EngineScope.of(context);
    return ValueListenableBuilder<SetupInfo>(
      valueListenable: engine.setup,
      builder: (context, setup, _) => ValueListenableBuilder<EngineSettings>(
        valueListenable: engine.settings,
        builder: (context, settings, _) {
          final showSetup = !setup.ready || !settings.onboardingDone;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: showSetup
                ? SetupScreen(
                    key: const ValueKey('setup'),
                    onFinished: () => engine.updateSettings({'onboardingDone': true}),
                  )
                : const HomeScreen(key: ValueKey('home')),
          );
        },
      ),
    );
  }
}

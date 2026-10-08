import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../engine/engine_controller.dart';
import '../../engine/engine_models.dart';
import '../help/help_screen.dart';
import '../settings/settings_screen.dart';
import '../setup/setup_screen.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'apps_card.dart';
import 'live_card.dart';
import 'power_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final engine = EngineScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primaryDeep,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.music_off_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.helpTitle,
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => _push(context, const HelpScreen()),
          ),
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _push(context, const SettingsScreen()),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ValueListenableBuilder<EngineStatus>(
        valueListenable: engine.status,
        builder: (context, status, _) {
          final running = status.state == EngineState.running;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              _Hero(status: status, onToggle: () => _toggle(context, status)),
              if (status.state == EngineState.error && status.error != null) ...[
                const SizedBox(height: 16),
                _ErrorBanner(code: status.error!),
              ],
              if (status.autoSwitched) ...[
                const SizedBox(height: 16),
                _Note(icon: Icons.speed_rounded, text: l10n.autoSwitchedNote),
              ],
              if (running) ...[
                const SizedBox(height: 16),
                ValueListenableBuilder<EngineSettings>(
                  valueListenable: engine.settings,
                  builder: (context, settings, _) =>
                      LiveCard(status: status, voiceProtection: settings.voiceProtection != 'off'),
                ),
              ],
              if (running || status.apps.isNotEmpty) ...[
                const SizedBox(height: 16),
                AppsCard(apps: status.apps),
              ],
              const SizedBox(height: 16),
              const _BoostCard(),
              if (!status.isActive) ...[
                const SizedBox(height: 16),
                SectionCard(
                  title: l10n.tipTileTitle,
                  icon: Icons.lightbulb_outline_rounded,
                  child: Text(l10n.tipTileBody, style: const TextStyle(color: AppColors.textMuted, height: 1.4)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggle(BuildContext context, EngineStatus status) async {
    final engine = EngineScope.of(context);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.mediumImpact();
    if (status.isActive) {
      await engine.stop();
      return;
    }
    try {
      final started = await engine.start();
      if (!started) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorProjectionDenied)));
      }
    } on PlatformException catch (e) {
      if (e.code == 'setup_missing') {
        await engine.refreshSetup();
      } else {
        messenger.showSnackBar(SnackBar(content: Text(e.message ?? l10n.errorEngineFailed)));
      }
    }
  }
}

void _push(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

class _Hero extends StatelessWidget {
  const _Hero({required this.status, required this.onToggle});

  final EngineStatus status;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (title, subtitle) = switch (status.state) {
      EngineState.running => (l10n.homeOnTitle, l10n.homeOnSubtitle),
      EngineState.starting => (l10n.homeStartingTitle, l10n.homeStartingSubtitle),
      _ => (l10n.homeOffTitle, l10n.homeOffSubtitle),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          PowerButton(
            state: status.state,
            onPressed: status.state == EngineState.starting ? null : onToggle,
            semanticLabel: status.isActive ? l10n.powerStop : l10n.powerStart,
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Column(
              key: ValueKey(status.state),
              children: [
                Text(title, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = switch (code) {
      'projection_denied' => l10n.errorProjectionDenied,
      'projection_revoked' => l10n.errorProjectionRevoked,
      'setup_missing' => l10n.errorSetupMissing,
      'capture_denied' => l10n.errorCaptureDenied,
      _ => l10n.errorEngineFailed,
    };
    final needsSetup = code == 'setup_missing' || code == 'capture_denied';
    return _Note(
      icon: Icons.error_outline_rounded,
      color: AppColors.danger,
      text: text,
      action: needsSetup
          ? TextButton(
              onPressed: () => _push(context, SetupScreen(onFinished: () => Navigator.of(context).pop())),
              child: Text(l10n.actionOpenSetup),
            )
          : null,
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.color = AppColors.gold, this.action});

  final IconData icon;
  final String text;
  final Color color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
          ?action,
        ],
      ),
    );
  }
}

class _BoostCard extends StatefulWidget {
  const _BoostCard();

  @override
  State<_BoostCard> createState() => _BoostCardState();
}

class _BoostCardState extends State<_BoostCard> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final engine = EngineScope.of(context);
    return ValueListenableBuilder<EngineSettings>(
      valueListenable: engine.settings,
      builder: (context, settings, _) {
        final value = _dragging ?? settings.boostDb;
        return SectionCard(
          title: l10n.boostTitle,
          icon: Icons.record_voice_over_rounded,
          trailing: Text(
            l10n.boostValue(value.round()),
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Slider(
                value: value.clamp(0, 12),
                min: 0,
                max: 12,
                divisions: 12,
                onChanged: (v) => setState(() => _dragging = v),
                onChangeEnd: (v) async {
                  await engine.updateSettings({'boostDb': v});
                  if (mounted) setState(() => _dragging = null);
                },
              ),
              Text(l10n.boostHint, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../engine/engine_controller.dart';
import '../../engine/engine_models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// First-run wizard: runtime permission, one-time activation (ADB or
/// Shizuku), battery. Re-checks automatically when the user comes back from
/// another app or the computer.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _busy = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // Grants done over ADB don't notify the app: re-check every few seconds
    // while something is still missing, so the steps tick themselves off.
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      final setup = EngineScope.of(context).setup.value;
      if (!setup.ready || !setup.projectMedia) EngineScope.of(context).refreshSetup();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _grantWithShizuku() => _run(() async {
        final engine = EngineScope.of(context);
        final l10n = AppLocalizations.of(context);
        final messenger = ScaffoldMessenger.of(context);
        final result = await engine.grantWithShizuku();
        final message = switch (result.shizukuError) {
          'not_running' => l10n.setupShizukuNotRunning,
          'denied' => l10n.setupShizukuDenied,
          'grant_failed' => l10n.setupShizukuFailed,
          _ => null,
        };
        if (message != null) messenger.showSnackBar(SnackBar(content: Text(message)));
      });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final engine = EngineScope.of(context);
    final theme = Theme.of(context);
    return ValueListenableBuilder<SetupInfo>(
      valueListenable: engine.setup,
      builder: (context, setup, _) {
        final step1Done = setup.recordAudio && setup.notifications;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.setupTitle),
            actions: [
              IconButton(
                tooltip: l10n.setupCheckAgain,
                onPressed: engine.refreshSetup,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDeep,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.music_off_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.appTitle, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(l10n.tagline, style: const TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l10n.setupIntro, style: const TextStyle(height: 1.4)),
              if (!setup.muteSupported) ...[
                const SizedBox(height: 16),
                _Warning(text: l10n.setupMuteUnsupported),
              ],
              const SizedBox(height: 18),
              _StepCard(
                number: 1,
                title: l10n.setupStep1Title,
                chip: StatusChip(
                  label: step1Done ? l10n.setupStatusDone : l10n.setupStatusMissing,
                  tone: step1Done ? ChipTone.good : ChipTone.todo,
                ),
                body: l10n.setupStep1Body,
                children: [
                  if (!step1Done)
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _run(engine.requestPermissions),
                      icon: const Icon(Icons.mic_none_rounded),
                      label: Text(l10n.setupStep1Button),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _StepCard(
                number: 2,
                title: l10n.setupStep2Title,
                chip: StatusChip(
                  label: setup.dump ? l10n.setupStatusDone : l10n.setupStatusMissing,
                  tone: setup.dump ? ChipTone.good : ChipTone.todo,
                ),
                body: l10n.setupStep2Body,
                children: [
                  _PermRow(label: l10n.setupPermDump, done: setup.dump, doneText: l10n.setupStatusDone, todoText: l10n.setupStatusMissing),
                  _PermRow(
                    label: l10n.setupPermProjection,
                    done: setup.projectMedia,
                    doneText: l10n.setupStatusDone,
                    todoText: l10n.setupStatusOptional,
                    optional: true,
                  ),
                  if (!setup.dump || !setup.projectMedia) ...[
                    const SizedBox(height: 8),
                    _Method(
                      icon: Icons.computer_rounded,
                      title: l10n.setupWithPc,
                      initiallyExpanded: true,
                      children: [
                        Text(l10n.setupWithPcSteps, style: const TextStyle(height: 1.5)),
                        for (final command in setup.adbCommands) CommandBox(command: command),
                        const SizedBox(height: 8),
                        Text(l10n.setupCommandsHint, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _Method(
                      icon: Icons.phone_android_rounded,
                      title: l10n.setupWithoutPc,
                      children: [
                        Text(l10n.setupShizukuSteps, style: const TextStyle(height: 1.5)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (!setup.shizukuInstalled)
                              OutlinedButton.icon(
                                onPressed: engine.openShizuku,
                                icon: const Icon(Icons.download_rounded),
                                label: Text(l10n.setupShizukuGet),
                              ),
                            FilledButton.icon(
                              onPressed: _busy ? null : _grantWithShizuku,
                              icon: _busy
                                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.key_rounded),
                              label: Text(l10n.setupShizukuButton),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: engine.refreshSetup,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.setupCheckAgain),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              _StepCard(
                number: 3,
                title: l10n.setupStep3Title,
                chip: StatusChip(
                  label: setup.batteryUnrestricted ? l10n.setupStatusDone : l10n.setupStatusOptional,
                  tone: setup.batteryUnrestricted ? ChipTone.good : ChipTone.info,
                ),
                body: l10n.setupStep3Body,
                children: [
                  if (!setup.batteryUnrestricted)
                    OutlinedButton.icon(
                      onPressed: engine.openBatterySettings,
                      icon: const Icon(Icons.battery_charging_full_rounded),
                      label: Text(l10n.setupStep3Button),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: setup.ready ? widget.onFinished : null,
                child: Text(l10n.setupFinish),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.chip,
    required this.body,
    this.children = const [],
  });

  final int number;
  final String title;
  final Widget chip;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.surfaceHigh,
                  child: Text('$number', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
                chip,
              ],
            ),
            const SizedBox(height: 10),
            Text(body, style: const TextStyle(color: AppColors.textMuted, height: 1.45)),
            if (children.isNotEmpty) const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  const _PermRow({
    required this.label,
    required this.done,
    required this.doneText,
    required this.todoText,
    this.optional = false,
  });

  final String label;
  final bool done;
  final String doneText;
  final String todoText;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          StatusChip(
            label: done ? doneText : todoText,
            tone: done ? ChipTone.good : (optional ? ChipTone.info : ChipTone.todo),
          ),
        ],
      ),
    );
  }
}

class _Method extends StatelessWidget {
  const _Method({
    required this.icon,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.outline),
    );
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      shape: shape,
      collapsedShape: shape,
      backgroundColor: AppColors.surfaceHigh,
      collapsedBackgroundColor: AppColors.surfaceHigh,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.block_rounded, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

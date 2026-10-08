import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../engine/engine_controller.dart';
import '../../engine/engine_models.dart';
import '../setup/setup_screen.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'excluded_apps_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _languages = {'system': null, 'en': 'English', 'ar': 'العربية', 'fr': 'Français'};

  @override
  void initState() {
    super.initState();
    // Show the model the speed test (or the auto-switch) picked meanwhile.
    EngineScope.of(context).reloadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final engine = EngineScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ValueListenableBuilder<EngineSettings>(
        valueListenable: engine.settings,
        builder: (context, settings, _) {
          final autoPick = switch (settings.autoModel) {
            'full' => l10n.qualityFull,
            'balanced' => l10n.qualityBalanced,
            'light' => l10n.qualityLight,
            _ => null,
          };
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
            children: [
              SectionCard(
                title: l10n.settingsQuality,
                icon: Icons.high_quality_rounded,
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                child: RadioGroup<String>(
                  groupValue: settings.quality,
                  onChanged: (v) {
                    if (v != null) engine.updateSettings({'quality': v});
                  },
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: 'auto',
                        title: Text(l10n.qualityAuto),
                        subtitle: Text(
                          autoPick == null
                              ? l10n.settingsQualityAutoDesc
                              : '${l10n.settingsQualityAutoDesc} · $autoPick',
                        ),
                      ),
                      RadioListTile<String>(
                        value: 'full',
                        title: Text(l10n.qualityFull),
                        subtitle: Text(l10n.settingsQualityFullDesc),
                      ),
                      RadioListTile<String>(
                        value: 'balanced',
                        title: Text(l10n.qualityBalanced),
                        subtitle: Text(l10n.settingsQualityBalancedDesc),
                      ),
                      RadioListTile<String>(
                        value: 'light',
                        title: Text(l10n.qualityLight),
                        subtitle: Text(l10n.settingsQualityLightDesc),
                      ),
                      if (settings.quality == 'auto')
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await engine.rerunSpeedTest();
                              messenger.showSnackBar(SnackBar(content: Text(l10n.settingsSpeedTestDone)));
                            },
                            icon: const Icon(Icons.speed_rounded),
                            label: Text(l10n.settingsSpeedTest),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: l10n.settingsProtection,
                icon: Icons.record_voice_over_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.settingsProtectionDesc, style: const TextStyle(color: AppColors.textMuted, height: 1.45)),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'off', label: Text(l10n.protectionOff)),
                        ButtonSegment(value: 'normal', label: Text(l10n.protectionNormal)),
                        ButtonSegment(value: 'strong', label: Text(l10n.protectionStrong)),
                      ],
                      selected: {settings.voiceProtection},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => engine.updateSettings({'voiceProtection': s.first}),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      switch (settings.voiceProtection) {
                        'off' => l10n.protectionOffDesc,
                        'strong' => l10n.protectionStrongDesc,
                        _ => l10n.protectionNormalDesc,
                      },
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: l10n.settingsLatency,
                icon: Icons.timer_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'low', label: Text(l10n.latencyLow)),
                        ButtonSegment(value: 'normal', label: Text(l10n.latencyNormal)),
                        ButtonSegment(value: 'stable', label: Text(l10n.latencyStable)),
                      ],
                      selected: {settings.latency},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => engine.updateSettings({'latency': s.first}),
                    ),
                    const SizedBox(height: 10),
                    Text(l10n.settingsLatencyDesc, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.do_not_disturb_on_outlined),
                      title: Text(l10n.settingsExcluded),
                      subtitle: Text(l10n.settingsExcludedCount(settings.excludedPackages.length)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const ExcludedAppsScreen()),
                      ),
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.translate_rounded),
                      title: Text(l10n.settingsLanguage),
                      subtitle: Text(_languages[settings.locale] ?? l10n.languageSystem),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _pickLanguage(context, settings.locale),
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.battery_saver_rounded),
                      title: Text(l10n.settingsBattery),
                      subtitle: Text(l10n.settingsBatteryDesc),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                      onTap: engine.openBatterySettings,
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: Text(l10n.settingsSetup),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => SetupScreen(onFinished: () => Navigator.of(context).pop()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: l10n.settingsPrivacyTitle,
                icon: Icons.wifi_off_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.settingsPrivacy, style: const TextStyle(color: AppColors.textMuted, height: 1.45)),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<SetupInfo>(
                      valueListenable: engine.setup,
                      builder: (context, setup, _) => Text(
                        l10n.settingsVersion(setup.version),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: () => showLicensePage(
                          context: context,
                          applicationName: l10n.appTitle,
                          applicationVersion: engine.setup.value.version,
                        ),
                        child: Text(l10n.settingsLicenses),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickLanguage(BuildContext context, String current) async {
    final l10n = AppLocalizations.of(context);
    final engine = EngineScope.of(context);
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.settingsLanguage),
        children: [
          RadioGroup<String>(
            groupValue: current,
            onChanged: (v) => Navigator.of(context).pop(v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in _languages.entries)
                  RadioListTile<String>(
                    value: entry.key,
                    title: Text(entry.value ?? l10n.languageSystem),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked != null && picked != current) await engine.updateSettings({'locale': picked});
  }
}

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../setup/setup_screen.dart';
import '../theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = <(IconData, String, String)>[
      (Icons.auto_awesome_rounded, l10n.helpHowTitle, l10n.helpHowBody),
      (Icons.percent_rounded, l10n.help100Title, l10n.help100Body),
      (Icons.apps_rounded, l10n.helpAppsTitle, l10n.helpAppsBody),
      (Icons.key_rounded, l10n.helpAdbTitle, l10n.helpAdbBody),
      (Icons.hearing_rounded, l10n.helpTroubleTitle, l10n.helpTroubleBody),
      (Icons.record_voice_over_rounded, l10n.helpCutTitle, l10n.helpCutBody),
      (Icons.volume_off_rounded, l10n.helpSilentTitle, l10n.helpSilentBody),
      (Icons.timer_outlined, l10n.helpDelayTitle, l10n.helpDelayBody),
      (Icons.battery_std_rounded, l10n.helpBatteryTitle, l10n.helpBatteryBody),
      (Icons.lock_outline_rounded, l10n.helpPrivacyTitle, l10n.helpPrivacyBody),
    ];
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.outline),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
        children: [
          for (final (icon, title, body) in entries) ...[
            ExpansionTile(
              shape: shape,
              collapsedShape: shape,
              backgroundColor: AppColors.surface,
              collapsedBackgroundColor: AppColors.surface,
              leading: Icon(icon, color: AppColors.primary),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(body, style: const TextStyle(color: AppColors.textMuted, height: 1.5))],
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => SetupScreen(onFinished: () => Navigator.of(context).pop()),
              ),
            ),
            icon: const Icon(Icons.verified_user_outlined),
            label: Text(l10n.helpSetupAction),
          ),
        ],
      ),
    );
  }
}

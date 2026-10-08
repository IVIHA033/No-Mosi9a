import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../engine/engine_models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Which apps are playing and whether their music is being removed.
class AppsCard extends StatelessWidget {
  const AppsCard({super.key, required this.apps});

  final List<EngineApp> apps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      title: l10n.appsTitle,
      icon: Icons.apps_rounded,
      child: apps.isEmpty
          ? Text(l10n.appsEmpty, style: const TextStyle(color: AppColors.textMuted))
          : Column(
              children: [
                for (final app in apps)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        AppIcon(packageName: app.packageName, label: app.label),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(app.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                app.blocked
                                    ? l10n.appBlocked
                                    : app.muted
                                        ? l10n.appCleaning
                                        : l10n.appNotMuted,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: app.muted ? AppColors.primary : AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          app.muted ? Icons.music_off_rounded : Icons.music_note_rounded,
                          color: app.muted ? AppColors.primary : AppColors.gold,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

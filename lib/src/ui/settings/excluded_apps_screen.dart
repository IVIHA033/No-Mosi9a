import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../engine/engine_controller.dart';
import '../../engine/engine_models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Apps whose sound is neither captured nor muted (Quran, podcasts, calls...).
class ExcludedAppsScreen extends StatefulWidget {
  const ExcludedAppsScreen({super.key});

  @override
  State<ExcludedAppsScreen> createState() => _ExcludedAppsScreenState();
}

class _ExcludedAppsScreenState extends State<ExcludedAppsScreen> {
  late final Future<List<InstalledApp>> _apps = EngineScope.of(context).listApps();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final engine = EngineScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.excludedTitle)),
      body: FutureBuilder<List<InstalledApp>>(
        future: _apps,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final q = _query.trim().toLowerCase();
          final apps = snapshot.data!
              .where((a) => q.isEmpty || a.label.toLowerCase().contains(q) || a.packageName.contains(q))
              .toList();
          return ValueListenableBuilder<EngineSettings>(
            valueListenable: engine.settings,
            builder: (context, settings, _) {
              final excluded = settings.excludedPackages.toSet();
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: apps.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.excludedHint, style: const TextStyle(color: AppColors.textMuted, height: 1.4)),
                          const SizedBox(height: 12),
                          TextField(
                            onChanged: (v) => setState(() => _query = v),
                            decoration: InputDecoration(
                              hintText: l10n.excludedSearch,
                              prefixIcon: const Icon(Icons.search_rounded),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final app = apps[i - 1];
                  final isExcluded = excluded.contains(app.packageName);
                  return CheckboxListTile(
                    value: isExcluded,
                    secondary: AppIcon(packageName: app.packageName, label: app.label, size: 36),
                    title: Text(app.label),
                    subtitle: Text(
                      app.packageName,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      textDirection: TextDirection.ltr,
                    ),
                    onChanged: (checked) {
                      final next = {...excluded};
                      if (checked ?? false) {
                        next.add(app.packageName);
                      } else {
                        next.remove(app.packageName);
                      }
                      engine.updateSettings({'excludedPackages': next.toList()});
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

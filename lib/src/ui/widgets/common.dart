import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../engine/engine_controller.dart';
import '../theme.dart';

/// Rounded card with an optional title row.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.icon,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 18),
  });

  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                  ],
                  Expanded(child: Text(title!, style: theme.textTheme.titleMedium)),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 14),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

enum ChipTone { good, todo, info }

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  final String label;
  final ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      ChipTone.good => AppColors.primary,
      ChipTone.todo => AppColors.gold,
      ChipTone.info => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tone == ChipTone.good ? Icons.check_rounded : Icons.circle_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// A shell command with a copy button. Commands are always left-to-right.
class CommandBox extends StatelessWidget {
  const CommandBox({super.key, required this.command});

  final String command;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 4, 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(
                command,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.4),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.setupCopy,
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: command));
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(l10n.setupCopied), duration: const Duration(seconds: 1)));
            },
          ),
        ],
      ),
    );
  }
}

/// App icon from the native side, or the first letter of its name.
class AppIcon extends StatelessWidget {
  const AppIcon({super.key, required this.packageName, required this.label, this.size = 40});

  final String packageName;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final engine = EngineScope.of(context);
    return ValueListenableBuilder<Map<String, Uint8List>>(
      valueListenable: engine.icons,
      builder: (context, icons, _) {
        final bytes = icons[packageName];
        if (bytes != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.24),
            child: Image.memory(bytes, width: size, height: size, gaplessPlayback: true),
          );
        }
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(size * 0.24),
          ),
          child: Text(
            label.isEmpty ? '?' : label.characters.first.toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: size * 0.42),
          ),
        );
      },
    );
  }
}

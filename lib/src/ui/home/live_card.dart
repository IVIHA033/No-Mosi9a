import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../engine/engine_models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Real-time before/after meters plus delay, model and processor load.
class LiveCard extends StatelessWidget {
  const LiveCard({super.key, required this.status, this.voiceProtection = true});

  final EngineStatus status;

  /// Voice protection is on: show when it is keeping someone's words.
  final bool voiceProtection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quality = switch (status.model) {
      'full' => l10n.qualityFull,
      'balanced' => l10n.qualityBalanced,
      'light' => l10n.qualityLight,
      _ => '—',
    };
    return SectionCard(
      title: l10n.liveTitle,
      icon: Icons.graphic_eq_rounded,
      trailing: const _LiveDot(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Meter(label: l10n.meterOriginal, db: status.inputDb, color: AppColors.gold),
          const SizedBox(height: 12),
          _Meter(label: l10n.meterClean, db: status.outputDb, color: AppColors.primary),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(label: l10n.statDelay, value: l10n.delayValue(status.latencyMs)),
              _Stat(label: l10n.statQuality, value: quality),
              _Stat(
                label: l10n.statCpu,
                value: l10n.percentValue((status.load * 100).round().clamp(0, 999)),
                warn: status.load > 0.8,
              ),
            ],
          ),
          if (voiceProtection) ...[
            const SizedBox(height: 12),
            _VoiceIndicator(active: status.speaking, label: l10n.liveVoice),
          ],
        ],
      ),
    );
  }
}

/// Lights up while voice protection hears someone talking.
class _VoiceIndicator extends StatelessWidget {
  const _VoiceIndicator({required this.active, required this.label});

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textMuted;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: active ? 1 : 0.35,
      child: Row(
        children: [
          Icon(Icons.record_voice_over_rounded, size: 18, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({required this.label, required this.db, required this.color});

  final String label;
  final double db;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final level = ((db + 60) / 60).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Container(
            height: 10,
            color: AppColors.background,
            alignment: AlignmentDirectional.centerStart,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeOut,
              widthFactor: level,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withValues(alpha: 0.55), color]),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.warn = false});

  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: warn ? AppColors.gold : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _blink =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_blink),
      child: Container(
        width: 9,
        height: 9,
        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../engine/engine_models.dart';
import '../theme.dart';

/// The big on/off switch. Breathes while running, spins while starting.
class PowerButton extends StatefulWidget {
  const PowerButton({
    super.key,
    required this.state,
    required this.onPressed,
    required this.semanticLabel,
    this.size = 188,
  });

  final EngineState state;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final double size;

  @override
  State<PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<PowerButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ticker =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(PowerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) _sync();
  }

  void _sync() {
    final animate = widget.state == EngineState.running || widget.state == EngineState.starting;
    if (animate && !_ticker.isAnimating) {
      _ticker.repeat();
    } else if (!animate) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.state == EngineState.running;
    final starting = widget.state == EngineState.starting;
    return Semantics(
      container: true,
      button: true,
      enabled: widget.onPressed != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _ticker,
          builder: (context, _) => CustomPaint(
            size: Size.square(widget.size),
            painter: _RingPainter(
              phase: _ticker.value,
              on: on,
              starting: starting,
            ),
            child: SizedBox.square(
              dimension: widget.size,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    on ? Icons.music_off_rounded : Icons.power_settings_new_rounded,
                    key: ValueKey(on),
                    size: widget.size * 0.30,
                    color: on ? const Color(0xFF00241B) : AppColors.text,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.phase, required this.on, required this.starting});

  final double phase;
  final bool on;
  final bool starting;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final inner = radius * 0.72;

    if (on) {
      // Two expanding halos, half a cycle apart.
      for (final offset in [0.0, 0.5]) {
        final t = (phase + offset) % 1.0;
        final r = inner + (radius - inner) * t;
        canvas.drawCircle(
          center,
          r,
          Paint()..color = AppColors.primary.withValues(alpha: 0.28 * (1 - t)),
        );
      }
    }

    canvas.drawCircle(
      center,
      radius * 0.86,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = (on ? AppColors.primary : AppColors.outline).withValues(alpha: on ? 0.55 : 1),
    );

    final fill = Paint()
      ..shader = RadialGradient(
        colors: on
            ? const [Color(0xFF3BE0B8), AppColors.primary, AppColors.primaryDeep]
            : const [AppColors.surfaceHigh, AppColors.surface, AppColors.surface],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: inner));
    canvas.drawCircle(center, inner, fill);
    if (!on) {
      canvas.drawCircle(
        center,
        inner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppColors.outline,
      );
    }

    if (starting) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4
        ..color = AppColors.primary;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.86),
        phase * 2 * math.pi * 2,
        math.pi * 0.6,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.phase != phase || old.on != on || old.starting != starting;
}

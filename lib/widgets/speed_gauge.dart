import 'dart:math';
import 'package:flutter/material.dart';
import '../controllers/SpeedTestController.dart';
import '../theme/app_theme.dart';

class SpeedGauge extends StatefulWidget {
  final double speed;
  final TestPhase phase;

  const SpeedGauge({
    super.key,
    required this.speed,
    required this.phase,
  });

  @override
  State<SpeedGauge> createState() => _SpeedGaugeState();
}

class _SpeedGaugeState extends State<SpeedGauge>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;


  double _previousSpeed = 0;


  static const double _maxSpeed = 300;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,

      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }


  @override
  void didUpdateWidget(SpeedGauge oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.speed != widget.speed) {

      _previousSpeed = oldWidget.speed;
      _animation = Tween<double>(
        begin: _previousSpeed,
        end: widget.speed,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );

      _controller
        ..reset()
        ..forward();
    }

    if (widget.phase == TestPhase.idle && oldWidget.phase != TestPhase.idle) {
      _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
      _previousSpeed = 0;
    }
  }

  @override
  void dispose() {

    _controller.dispose();
    super.dispose();
  }

  // ── Phase label ─────────────────────────────────────────────
  String get _phaseLabel {
    switch (widget.phase) {
      case TestPhase.ping:
        return 'Ping';
      case TestPhase.download:
        return 'Download';
      case TestPhase.upload:
        return 'Upload';
      case TestPhase.done:
        return 'Done';
      case TestPhase.error:
        return 'Error';
      case TestPhase.idle:
        return 'Tap GO to start';
    }
  }


  // the arc color changes depending on what we're measuring
  Color get _phaseColor {
    switch (widget.phase) {
      case TestPhase.ping:
        return AppTheme.accentPurple;
      case TestPhase.download:
        return AppTheme.accentBlue;
      case TestPhase.upload:
        return AppTheme.accentPink;
      case TestPhase.done:
        return AppTheme.accentBlue;
      default:
        return AppTheme.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      // while the animation is runningrebuilds this widget every frame
      animation: _animation,
      builder: (context, child) {
        final speed = _animation.value;

        return SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The arc drawn by CustomPainter
              CustomPaint(
                size: const Size(240, 240),
                painter: _GaugePainter(
                  speed: speed,
                  maxSpeed: _maxSpeed,
                  color: _phaseColor,
                  phase: widget.phase,
                ),
              ),

              // The text in the center of the gauge
              _buildCenterText(speed),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCenterText(double speed) {
    final bool showSpeed = widget.phase != TestPhase.idle &&
        widget.phase != TestPhase.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // speed number
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: showSpeed
              ? Text(
            speed.toStringAsFixed(1),
            key: const ValueKey('speed'),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 44,
              fontWeight: FontWeight.w300,
              letterSpacing: -1,
            ),
          )
              : const Text(
            '—',
            key: ValueKey('idle'),
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 44,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),

        // mbps unit label
        if (showSpeed)
          const Text(
            'Mbps',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.5,
            ),
          ),

        const SizedBox(height: 6),

        // label —ping / download / upload / done
        Text(
          _phaseLabel,
          style: TextStyle(
            color: widget.phase == TestPhase.idle
                ? AppTheme.textMuted
                : _phaseColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// the painter
class _GaugePainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final Color color;
  final TestPhase phase;

  _GaugePainter({
    required this.speed,
    required this.maxSpeed,
    required this.color,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;


    const double startAngle = 150 * pi / 180;
    const double totalSweep = 240 * pi / 180;

    // clamp speed between 0 and maxSpeed so it never overflows
    final double progress = (speed / maxSpeed).clamp(0.0, 1.0);
    final double sweepAngle = totalSweep * progress;

    //background track
    final trackPaint = Paint()
      ..color = AppTheme.surfacelight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    //only draw if testing
    if (phase == TestPhase.idle) return;

    // ── 2. glow layer we draw the same arc but wider and more transparent

    final glowPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );

    // main speed arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );


    // gives the arc a nice lit tip effect
    if (sweepAngle > 0.05) {
      final double tipAngle = startAngle + sweepAngle;
      final Offset tipPosition = Offset(
        center.dx + radius * cos(tipAngle),
        center.dy + radius * sin(tipAngle),
      );

      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(tipPosition, 5, dotPaint);
    }

    // tick marks around the trak

    _drawTicks(canvas, center, radius, startAngle, totalSweep);
  }

  void _drawTicks(Canvas canvas, Offset center, double radius,
      double startAngle, double totalSweep) {
    const int tickCount = 10;
    final double tickRadius = radius + 14;
    final double progress = (speed / maxSpeed).clamp(0.0, 1.0);

    for (int i = 0; i <= tickCount; i++) {
      final double angle = startAngle + (totalSweep / tickCount) * i;
      final double tickProgress = i / tickCount;


      final Color tickColor = tickProgress <= progress
          ? color.withOpacity(0.6)
          : AppTheme.textMuted.withOpacity(0.3);

      final tickPaint = Paint()
        ..color = tickColor
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;


      final Offset tickStart = Offset(
        center.dx + (tickRadius - 6) * cos(angle),
        center.dy + (tickRadius - 6) * sin(angle),
      );
      final Offset tickEnd = Offset(
        center.dx + tickRadius * cos(angle),
        center.dy + tickRadius * sin(angle),
      );

      canvas.drawLine(tickStart, tickEnd, tickPaint);
    }
  }


  // repaint  whenever the speed or color changes
  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.speed != speed || oldDelegate.color != color;
  }
}




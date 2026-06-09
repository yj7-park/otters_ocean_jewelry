import 'dart:math';
import 'package:flutter/material.dart';

class UnderwaterBackground extends StatefulWidget {
  final Widget? child;
  const UnderwaterBackground({super.key, this.child});

  @override
  State<UnderwaterBackground> createState() => _UnderwaterBackgroundState();
}

class _UnderwaterBackgroundState extends State<UnderwaterBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Bubble> _bubbles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize some bubbles
    for (int i = 0; i < 40; i++) {
      _bubbles.add(Bubble(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: _random.nextDouble() * 5 + 2,
        speed: _random.nextDouble() * 0.05 + 0.02,
        swaySpeed: _random.nextDouble() * 2 + 0.5,
        swayAmount: _random.nextDouble() * 15 + 5,
        phase: _random.nextDouble() * pi * 2,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update bubble positions
        for (var bubble in _bubbles) {
          bubble.y -= bubble.speed * 0.1;
          if (bubble.y < -0.1) {
            bubble.y = 1.1;
            bubble.x = _random.nextDouble();
          }
        }

        return CustomPaint(
          painter: UnderwaterPainter(
            bubbles: _bubbles,
            animationValue: _controller.value,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class Bubble {
  double x; // Percentage 0..1
  double y; // Percentage 0..1
  final double radius;
  final double speed;
  final double swaySpeed;
  final double swayAmount;
  final double phase;

  Bubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.swaySpeed,
    required this.swayAmount,
    required this.phase,
  });
}

class UnderwaterPainter extends CustomPainter {
  final List<Bubble> bubbles;
  final double animationValue;

  UnderwaterPainter({
    required this.bubbles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Deep Water Gradient
    final Rect rect = Offset.zero & size;
    final Gradient gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const HSLColor.fromAHSL(1.0, 195, 0.85, 0.45).toColor(), // Light Teal Top
        const HSLColor.fromAHSL(1.0, 215, 0.90, 0.18).toColor(), // Indigo Medium
        const HSLColor.fromAHSL(1.0, 235, 0.95, 0.06).toColor(), // Deep Navy Bottom
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final Paint paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // 2. Draw Sunlight Rays from top-left
    final Paint rayPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final double baseAngle = sin(animationValue * pi * 2) * 0.05;
    final List<double> rayWidths = [40, 80, 120, 60];
    final List<double> rayOffsets = [0.1, 0.35, 0.6, 0.8];

    for (int i = 0; i < rayOffsets.length; i++) {
      final double startX = size.width * rayOffsets[i] + sin(animationValue * pi * 2 + i) * 30;
      final double width = rayWidths[i];

      final path = Path()
        ..moveTo(startX, 0)
        ..lineTo(startX + width, 0)
        ..lineTo(startX + width * 2.5 + baseAngle * size.height, size.height)
        ..lineTo(startX - width * 0.5 + baseAngle * size.height, size.height)
        ..close();

      canvas.drawPath(path, rayPaint);
    }

    // 3. Draw Rising Bubbles
    final Paint bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Paint bubbleGlow = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    for (var bubble in bubbles) {
      // Calculate sway
      final double sway = sin(animationValue * pi * 2 * bubble.swaySpeed + bubble.phase) * bubble.swayAmount;
      final double cx = bubble.x * size.width + sway;
      final double cy = bubble.y * size.height;

      // Draw bubble outline
      canvas.drawCircle(Offset(cx, cy), bubble.radius, bubblePaint);
      
      // Draw highlight inside bubble
      canvas.drawCircle(
        Offset(cx - bubble.radius * 0.3, cy - bubble.radius * 0.3),
        bubble.radius * 0.3,
        Paint()..color = Colors.white.withOpacity(0.4)..style = PaintingStyle.fill,
      );

      // Draw soft glow
      canvas.drawCircle(Offset(cx, cy), bubble.radius + 2, bubbleGlow);
    }
  }

  @override
  bool shouldRepaint(covariant UnderwaterPainter oldDelegate) => true;
}

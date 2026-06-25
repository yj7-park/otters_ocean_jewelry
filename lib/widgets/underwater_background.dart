import 'dart:math';
import 'package:flutter/material.dart';

class UnderwaterBackground extends StatefulWidget {
  final Widget? child;
  final String themeId;
  const UnderwaterBackground({super.key, this.child, this.themeId = 'default'});

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
            themeId: widget.themeId,
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
  final String themeId;

  UnderwaterPainter({
    required this.bubbles,
    required this.animationValue,
    required this.themeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Deep Water Gradient based on themeId
    final Rect rect = Offset.zero & size;
    Gradient gradient;

    if (themeId == 'coral') {
      gradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFA4A2), // Coral Rose Light
          Color(0xFFEC407A), // Vibrant Pink
          Color(0xFF3F1D70), // Dark Purple Bottom
        ],
        stops: [0.0, 0.5, 1.0],
      );
    } else if (themeId == 'jellyfish') {
      gradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFD1C4E9), // Pale Lavender
          Color(0xFF7E57C2), // Deep Violet
          Color(0xFF151B54), // Midnight Navy
        ],
        stops: [0.0, 0.5, 1.0],
      );
    } else {
      gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const HSLColor.fromAHSL(1.0, 195, 0.85, 0.45).toColor(), // Light Teal Top
          const HSLColor.fromAHSL(1.0, 215, 0.90, 0.18).toColor(), // Indigo Medium
          const HSLColor.fromAHSL(1.0, 235, 0.95, 0.06).toColor(), // Deep Navy Bottom
        ],
        stops: const [0.0, 0.6, 1.0],
      );
    }

    final Paint paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Draw Theme Decorations
    if (themeId == 'coral') {
      final coralPaint = Paint()..color = const Color(0xFFF50057).withOpacity(0.08)..style = PaintingStyle.fill;
      for (double x = 40; x < size.width; x += 180) {
        final path = Path()
          ..moveTo(x, size.height)
          ..quadraticBezierTo(x - 10, size.height - 30, x - 5, size.height - 45)
          ..quadraticBezierTo(x, size.height - 50, x + 5, size.height - 45)
          ..quadraticBezierTo(x + 10, size.height - 30, x, size.height)
          ..moveTo(x - 5, size.height - 25)
          ..quadraticBezierTo(x - 25, size.height - 35, x - 30, size.height - 50)
          ..quadraticBezierTo(x - 20, size.height - 55, x - 10, size.height - 35)
          ..close();
        canvas.drawPath(path, coralPaint);
      }
    } else if (themeId == 'jellyfish') {
      final time = DateTime.now().millisecondsSinceEpoch * 0.001;
      final jPaint = Paint()..color = const Color(0xFFE040FB).withOpacity(0.05);
      
      // Jelly 1
      double j1x = size.width * 0.25;
      double j1y = size.height * 0.45 + sin(time) * 15;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(j1x, j1y), radius: 24),
        pi, pi, true, jPaint
      );
      
      // Jelly 2
      double j2x = size.width * 0.75;
      double j2y = size.height * 0.3 + cos(time) * 10;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(j2x, j2y), radius: 18),
        pi, pi, true, jPaint
      );
    }

    // 2. Draw Sunlight Rays
    final Paint rayPaint = Paint()
      ..color = themeId == 'coral' 
          ? Colors.orangeAccent.withOpacity(0.03) 
          : (themeId == 'jellyfish' ? Colors.purpleAccent.withOpacity(0.03) : Colors.white.withOpacity(0.05))
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
      ..color = themeId == 'coral'
          ? const Color(0xFFFF8A80).withOpacity(0.25)
          : (themeId == 'jellyfish' ? const Color(0xFFEA80FC).withOpacity(0.25) : Colors.white.withOpacity(0.25))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Paint bubbleGlow = Paint()
      ..color = themeId == 'coral'
          ? const Color(0xFFFF8A80).withOpacity(0.08)
          : (themeId == 'jellyfish' ? const Color(0xFFEA80FC).withOpacity(0.08) : Colors.white.withOpacity(0.08))
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

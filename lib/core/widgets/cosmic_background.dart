import 'dart:math';
import 'package:flutter/material.dart';
/// Animated starfield background for cosmic screens.
class CosmicBackground extends StatefulWidget {
  const CosmicBackground({super.key, required this.child, this.showStars = true});

  final Widget child;
  final bool showStars;

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0A0A12),
                Color(0xFF1A1035),
                Color(0xFF0A0A12),
              ],
            ),
          ),
        ),
        if (widget.showStars)
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => CustomPaint(
              painter: _StarPainter(_controller.value),
              size: Size.infinite,
            ),
          ),
        widget.child,
      ],
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.phase);

  final double phase;
  final _random = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for (var i = 0; i < 80; i++) {
      final x = _random.nextDouble() * size.width;
      final y = (_random.nextDouble() * size.height + phase * 50) % size.height;
      final r = _random.nextDouble() * 1.5 + 0.5;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

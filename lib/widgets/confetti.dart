import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiWidget extends StatefulWidget {
  final int particleCount;
  final Duration animationDuration;

  const ConfettiWidget({
    super.key,
    this.particleCount = 50,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with TickerProviderStateMixin {
  late List<ConfettiParticle> _particles;
  late AnimationController _controller;

  final List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _particles = List.generate(
      widget.particleCount,
      (index) => ConfettiParticle(
        x: Random().nextDouble(),
        y: -Random().nextDouble() * 0.5,
        vx: (Random().nextDouble() - 0.5) * 0.02,
        vy: Random().nextDouble() * 0.02 + 0.01,
        rotation: Random().nextDouble() * 2 * pi,
        rotationSpeed: (Random().nextDouble() - 0.5) * 0.2,
        size: Random().nextDouble() * 8 + 4,
        color: _colors[Random().nextInt(_colors.length)],
        shape: Random().nextBool() ? ParticleShape.rectangle : ParticleShape.circle,
      ),
    );

    _controller.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
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
        return CustomPaint(
          painter: ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

enum ParticleShape { rectangle, circle }

class ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double rotationSpeed;
  double size;
  Color color;
  ParticleShape shape;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.shape,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var particle in particles) {
      // Update position
      particle.x += particle.vx;
      particle.y += particle.vy;
      particle.rotation += particle.rotationSpeed;

      // Apply gravity
      particle.vy += 0.0005;

      // Calculate position based on progress
      final drawX = particle.x * size.width;
      final drawY = particle.y * size.height + (progress * size.height * 1.5);

      // Skip if off screen
      if (drawY > size.height + 50) continue;

      paint.color = particle.color.withOpacity(1 - progress * 0.5);
      paint.style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(drawX, drawY);
      canvas.rotate(particle.rotation);

      if (particle.shape == ParticleShape.rectangle) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}

// Show confetti overlay
void showConfetti(BuildContext context, {int particleCount = 50}) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) => IgnorePointer(
      child: ConfettiWidget(particleCount: particleCount),
    ),
  );

  overlay.insert(entry);

  // Auto-remove after animation
  Future.delayed(const Duration(milliseconds: 1600), () {
    entry.remove();
  });
}

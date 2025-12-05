import 'dart:math';

import 'package:flutter/material.dart';

class StepsProgressIcon extends StatefulWidget {
  const StepsProgressIcon({super.key});

  @override
  State<StepsProgressIcon> createState() => _StepsProgressIconState();
}

class _StepsProgressIconState extends State<StepsProgressIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuart);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: curve,
      builder: (_, _) => CustomPaint(
        size: const Size(120, 120),
        painter: StepIconPainter(progress: curve.value),
      ),
    );
  }
}

class StepIconPainter extends CustomPainter {
  final double progress;
  StepIconPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double rev = 1 - progress;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.46;
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 2 * pi - pi / 2,
        colors: [
          const Color.fromARGB(255, 234, 137, 137),
          const Color(0xFFB60015),
        ],
        stops: const [0.0, 1.0],
        transform: GradientRotation(-pi / 2),
      ).createShader(arcRect)
      ..strokeWidth = size.width * 0.12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const startAngle = -pi / 2;
    const sweepAngle = 1.55 * pi;
    canvas.drawArc(arcRect, startAngle, sweepAngle, false, arcPaint);
    final roadWidth = size.width * 0.22;
    final roadHeight = size.height * 0.60;
    final roadTop = center.dy - roadHeight / 2;
    final roadRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx - roadWidth / 2, roadTop, roadWidth, roadHeight),
      Radius.circular(roadWidth * 0.5),
    );
    canvas.drawRRect(roadRect, Paint()..color = const Color(0xffE5E5E5));
    final dashPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = roadWidth * 0.13
      ..strokeCap = StrokeCap.round;
    final dashLength = roadHeight * 0.13;
    final gapLength = dashLength * 0.85;
    final totalLength = dashLength + gapLength;
    final offset = rev * totalLength * 6;
    double y = roadTop - offset;
    for (int i = 0; i < 12; i++) {
      final yStart = y;
      final yEnd = y + dashLength;
      if (yEnd > roadTop && yStart < roadTop + roadHeight) {
        canvas.drawLine(
          Offset(center.dx, yStart.clamp(roadTop, roadTop + roadHeight)),
          Offset(center.dx, yEnd.clamp(roadTop, roadTop + roadHeight)),
          dashPaint,
        );
      }
      y += totalLength;
    }
    const double footSize = 24;
    final footStart = roadTop + dashLength;
    final footEnd = roadTop + roadHeight - dashLength;
    final footY = footStart + (footEnd - footStart) * rev;
    final shadow = TextPainter(
      text: const TextSpan(
        text: "👣",
        style: TextStyle(fontSize: footSize, color: Colors.black26),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    shadow.paint(
      canvas,
      Offset(center.dx - shadow.width / 2 + 2, footY - shadow.height / 2 + 5),
    );
    final painter = TextPainter(
      text: const TextSpan(
        text: "👣",
        style: TextStyle(fontSize: footSize, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, footY - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant StepIconPainter oldDelegate) => true;
}

import 'dart:math';

import 'package:flutter/material.dart';

class HydrationCard extends StatelessWidget {
  final double remainingLiters;
  final VoidCallback onAddWater;

  const HydrationCard({
    super.key,
    required this.remainingLiters,
    required this.onAddWater,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double buttonHPad = screenWidth * 0.045;
    final double buttonVPad = screenWidth * 0.022;
    final double buttonFontSize = screenWidth * 0.040;
    return HydrationWaveProvider(
      child: Center(
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.green.withOpacity(0.4),
              width: 1.2,
            ),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE8FBE9), Color(0xFFD9F5DA)],
            ),
          ),
          child: Stack(
            children: [
              // Waves Background
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedBuilder(
                    animation: _HydrationWaveController.of(context),
                    builder: (context, _) {
                      return CustomPaint(
                        painter: OceanWavePainter(
                          _HydrationWaveController.of(context).value,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Hydration",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            "${remainingLiters.toStringAsFixed(1)}ltr Remaining",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: screenWidth * 0.025,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // button
                    GestureDetector(
                      onTap: onAddWater,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: buttonHPad,
                          vertical: buttonVPad,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3DBE57), Color(0xFF5EDB72)],
                          ),
                        ),
                        child: Text(
                          "Add Water",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: buttonFontSize,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OceanWavePainter extends CustomPainter {
  final double progress;
  OceanWavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final double phase = progress * 2 * pi;
    final Paint deepWave = Paint()
      ..color = const Color(0xFF65B86A).withOpacity(0.75)
      ..style = PaintingStyle.fill;
    final Paint lightWave = Paint()
      ..color = const Color(0xFFA8EFB5).withOpacity(0.95)
      ..style = PaintingStyle.fill;
    final double baseHeight = size.height * 0.62;
    Path generateWave({
      required double amplitude,
      required double phaseShift,
      required double yOffset,
    }) {
      final Path path = Path();
      path.moveTo(0, baseHeight + yOffset);
      for (double x = 0; x <= size.width; x++) {
        double y =
            amplitude * sin((x / size.width * 2 * pi) + phase + phaseShift);
        path.lineTo(x, baseHeight + y + yOffset);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      return path;
    }

    canvas.drawPath(
      generateWave(amplitude: 14, phaseShift: pi, yOffset: 16),
      deepWave,
    );
    canvas.drawPath(
      generateWave(amplitude: 20, phaseShift: 0, yOffset: 2),
      lightWave,
    );
  }

  @override
  bool shouldRepaint(OceanWavePainter oldDelegate) => true;
}

class HydrationWaveProvider extends StatefulWidget {
  final Widget child;
  const HydrationWaveProvider({super.key, required this.child});
  @override
  State<HydrationWaveProvider> createState() => _HydrationWaveProviderState();
}

class _HydrationWaveProviderState extends State<HydrationWaveProvider>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _HydrationWaveController(value: controller, child: widget.child);
  }
}

class _HydrationWaveController extends InheritedWidget {
  final AnimationController value;
  const _HydrationWaveController({required super.child, required this.value});
  static AnimationController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_HydrationWaveController>()!
      .value;
  @override
  bool updateShouldNotify(_) => true;
}

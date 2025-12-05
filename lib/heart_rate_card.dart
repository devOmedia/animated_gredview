import 'package:flutter/material.dart';

class HeartRateCard extends StatefulWidget {
  const HeartRateCard({super.key});

  @override
  State<HeartRateCard> createState() => _HeartRateCardState();
}

class _HeartRateCardState extends State<HeartRateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _ecgAnim;
  final int bpm = 80;

  String get heartLabel {
    if (bpm < 60) {
      return "Low";
    } else if (bpm < 100) {
      return "Normal";
    } else if (bpm < 140) {
      return "Elevated";
    } else {
      return "High";
    }
  }

  @override
  void initState() {
    super.initState();
    final beatDuration = Duration(milliseconds: ((60000 / bpm) * 1.2).round());
    _controller = AnimationController(vsync: this, duration: beatDuration)
      ..repeat();
    _ecgAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return SizedBox(
      height: 130,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.32), width: 1.1),
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 236, 242, 251),
              Color.fromARGB(255, 198, 221, 248),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated ECG (heartbeat) diagram in the background
            AnimatedBuilder(
              animation: _ecgAnim,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.32,
                  child: Center(
                    child: CustomPaint(
                      size: const Size(120, 48),
                      painter: _ECGDiagramPainter(progress: _ecgAnim.value),
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Text(
                        "Heart Rate & HRV",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      );
                    },
                  ),
                  Spacer(),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          "$bpm",
                          style: textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          "bpm",
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            heartLabel,
                            style: textTheme.titleSmall?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ECGDiagramPainter extends CustomPainter {
  final double progress; // 0..1
  const _ECGDiagramPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFEA1D2C)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;
    final double margin = w * 0.06;
    final double left = margin;
    final double right = w - margin;
    final double mid = h * 0.5;
    final double peak = h * 0.18;
    final double dip = h * 0.82;

    // ECG path: flat, up, sharp down, up, flat
    final Path path = Path();
    final double totalLen = right - left;
    final double animX = left + totalLen * progress;
    path.moveTo(left, mid);
    // Animate the "pulse" moving across
    if (animX < left + totalLen * 0.18) {
      path.lineTo(animX, mid);
    } else if (animX < left + totalLen * 0.28) {
      path.lineTo(left + totalLen * 0.18, mid);
      path.lineTo(animX, peak);
    } else if (animX < left + totalLen * 0.38) {
      path.lineTo(left + totalLen * 0.18, mid);
      path.lineTo(left + totalLen * 0.28, peak);
      path.lineTo(animX, dip);
    } else if (animX < left + totalLen * 0.48) {
      path.lineTo(left + totalLen * 0.18, mid);
      path.lineTo(left + totalLen * 0.28, peak);
      path.lineTo(left + totalLen * 0.38, dip);
      path.lineTo(animX, mid);
    } else {
      path.lineTo(left + totalLen * 0.18, mid);
      path.lineTo(left + totalLen * 0.28, peak);
      path.lineTo(left + totalLen * 0.38, dip);
      path.lineTo(left + totalLen * 0.48, mid);
      path.lineTo(animX, mid);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ECGDiagramPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

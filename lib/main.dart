import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'heart_rate_card.dart';
import 'hydration_card.dart';
import 'steps_card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metrics Dashboard',
      theme: ThemeData.light(),
      home: const Scaffold(body: SafeArea(child: MetricsGridPage())),
    );
  }
}

class GridItem {
  final String title;
  final Color color;
  final int heightCells;
  final int widthCells; // new: how many columns to span
  GridItem(this.title, this.color, this.heightCells, [this.widthCells = 1]);
}

class MetricsGridPage extends StatefulWidget {
  const MetricsGridPage({super.key});

  @override
  State<MetricsGridPage> createState() => _MetricsGridPageState();
}

class _MetricsGridPageState extends State<MetricsGridPage> {
  List<GridItem> items = [
    GridItem("Steps", Colors.red.shade300, 2, 1), // spans 2 columns
    GridItem("Hydration", Colors.blue.shade300, 1, 1),
    GridItem("Heart Rate", Colors.green.shade300, 1, 1),
    GridItem("Calories", Colors.orange.shade300, 1, 1), // spans 2 columns
    GridItem("Sleep", Colors.purple.shade300, 2, 1),
    GridItem("Protein", Colors.teal.shade300, 1, 1),
  ];

  int crossAxisCount = 2;
  double spacing = 12;
  double baseCellHeight = 100;

  bool isEditMode = false;

  int? draggingIndex;
  Offset? dragOffset;
  bool isDeleting = false;

  void enterEditMode() {
    if (!isEditMode) {
      setState(() => isEditMode = true);
    }
  }

  void exitEditMode() {
    if (isEditMode) {
      setState(() => isEditMode = false);
    }
  }

  void addMetric() {
    final next = items.length + 1;
    final tall = next % 4 == 0;

    setState(() {
      items.add(
        GridItem(
          "Metric $next",
          Colors.primaries[next % Colors.primaries.length].shade300,
          tall ? 2 : 1,
        ),
      );
    });
  }

  void swapItems(int from, int to) {
    if (from == to) return;
    setState(() {
      final item = items.removeAt(from);
      items.insert(to, item);
    });
  }

  double tileHeight(int h) => baseCellHeight * h + spacing * (h - 1);

  double tileWidth(BuildContext context) {
    final totalPad = 12 * 2;
    final spacingTotal = spacing * (crossAxisCount - 1);
    final width = MediaQuery.of(context).size.width;
    return (width - totalPad - spacingTotal) / crossAxisCount;
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => exitEditMode(),
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              // Top bar
              if (isEditMode)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: addMetric,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.deepPurpleAccent.withOpacity(0.25),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.deepPurpleAccent,
                            size: 16,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () => exitEditMode(),
                        child: const Text("Done"),
                      ),
                    ],
                  ),
                ),

              // GRID
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ListView.builder(
                    itemCount: (items.length / 2).ceil(),
                    itemBuilder: (context, rowIdx) {
                      final leftIdx = rowIdx * 2;
                      final rightIdx = leftIdx + 1;
                      final leftItem = items[leftIdx];
                      final rightItem = rightIdx < items.length
                          ? items[rightIdx]
                          : null;
                      // Determine flex: tall = 4, short = 5
                      int leftFlex = leftItem.heightCells == 2 ? 4 : 5;
                      int rightFlex =
                          rightItem != null && rightItem.heightCells == 2
                          ? 4
                          : 5;
                      return Row(
                        children: [
                          Expanded(
                            flex: leftFlex,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 6,
                                bottom: 12,
                              ),
                              child: buildDragTile(leftItem, leftIdx, context),
                            ),
                          ),
                          if (rightItem != null)
                            Expanded(
                              flex: rightFlex,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 6,
                                  bottom: 12,
                                ),
                                child: buildDragTile(
                                  rightItem,
                                  rightIdx,
                                  context,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Delete target
        if (isEditMode && draggingIndex != null)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedScale(
                scale: isDeleting ? 1.4 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: deleteTarget(context),
              ),
            ),
          ),

        // Add Metric button
        // if (isEditMode)
        //   Positioned(
        //     bottom: 25,
        //     right: 20,
        //     child: FloatingActionButton.extended(
        //       onPressed: addMetric,
        //       icon: const Icon(Icons.add),
        //       label: const Text("Add Metric"),
        //     ),
        //   ),
      ],
    );
  }

  // --------------------------------------------------
  // Calories Card
  Widget _caloriesCard() {
    return _card(
      borderColor: Color(0xff098C26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Calories",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          Row(
            children: [
              const Text(
                "1,420",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "kcal",
                style: TextStyle(
                  color: Color(0xff098C26),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              CircularPercentIndicator(
                radius: 26,
                lineWidth: 7,
                percent: 0.72,
                progressColor: Color(0xff098C26),
                backgroundColor: Color(0xffEBFFF0),

                center: const Text(
                  "72%",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          Row(
            children: [
              const Icon(Icons.restaurant_menu, color: Colors.orange, size: 16),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  "Stay fueled — Dinner planned 600 kcal.",
                  maxLines: 2,

                  style: TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // Protein Card
  Widget _proteinCard([double progress = 0.57]) {
    final cardColor = Color(0xff098C26);
    return _card(
      borderColor: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Protein",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "On track!",
                      style: TextStyle(
                        color: cardColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              CustomPaint(
                painter: GaugePainter(progress),
                child: SizedBox(
                  width: 72,
                  height: 36,
                  child: Center(
                    child: Text(
                      "${(progress * 100).round()}%",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // Sleep Card
  Widget _sleepCard() {
    return _card(
      borderColor: Color(0xff0064A7),
      child: SizedBox(
        height: 210,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sleep",
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            const Text(
              "7h 20m",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Text(
              "Last Night",
              style: TextStyle(
                color: Color(0xff0064A7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            Row(
              children: [
                const Icon(Icons.bedtime, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                const Text("Bedtime: 11:15 PM", style: TextStyle(fontSize: 10)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.wb_sunny, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                const Text("Wake-up:  6:35 AM", style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // Shared Card UI
  Widget _card({required Widget child, required Color borderColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: borderColor.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget deleteTarget(BuildContext context) {
    final radius = 30.0;
    final center = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height - radius - 10,
    );

    bool isOver = false;
    if (dragOffset != null) {
      final dx = dragOffset!.dx - center.dx;
      final dy = dragOffset!.dy - center.dy;
      if (sqrt(dx * dx + dy * dy) <= radius) {
        isOver = true;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOver ? Colors.redAccent : Colors.grey,
      ),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Widget buildDragTile(GridItem item, int index, BuildContext context) {
    if (!isEditMode) {
      // Normal view (no drag)
      return GestureDetector(
        onLongPress: enterEditMode,
        child: buildTile(item),
      );
    }

    // Edit mode: wrap with drag + delete
    return LongPressDraggable<int>(
      data: index,
      feedback: Material(
        color: Colors.transparent,
        child: buildTile(
          item,
          isFeedback: true,
          feedbackWidth: tileWidth(context),
          feedbackHeight: tileHeight(item.heightCells),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: buildTile(item)),
      onDragStarted: () => setState(() => draggingIndex = index),
      onDragUpdate: (d) => setState(() => dragOffset = d.globalPosition),
      onDragEnd: (d) async {
        if (dragOffset != null) {
          final y = dragOffset!.dy;
          final screenH = MediaQuery.of(context).size.height;

          if (y > screenH - 120) {
            setState(() => isDeleting = true);
            await Future.delayed(const Duration(milliseconds: 80));
            if (index < items.length) {
              setState(() {
                items.removeAt(index);
              });
            }
          }
        }

        setState(() {
          draggingIndex = null;
          dragOffset = null;
          isDeleting = false;
        });
      },
      child: DragTarget<int>(
        onWillAcceptWithDetails: (d) => d.data != index,
        onAcceptWithDetails: (d) => swapItems(d.data, index),
        builder: (_, __, ___) => buildTile(item),
      ),
    );
  }

  Widget buildTile(
    GridItem item, {
    bool isFeedback = false,
    double? feedbackWidth,
    double? feedbackHeight,
  }) {
    double width = feedbackWidth ?? tileWidth(context);
    double height = feedbackHeight ?? tileHeight(item.heightCells);

    // Adjust width/height for small/tall cards
    if (item.heightCells == 1) {
      width *= 1.5; // Increase width for small cards
      height *= 0.95; // Slightly reduce height for small cards
    } else if (item.heightCells == 2) {
      width *= 0.85; // Slightly reduce width for tall cards
      height *= 0.75; // Reduce height for tall cards
    }

    if (item.title == "Steps") {
      return SizedBox(
        width: width,
        height: item.heightCells == 2 ? height : 270,
        child: const StepsCard(),
      );
    }
    if (item.title == "Hydration") {
      return SizedBox(
        width: width,
        height: item.heightCells == 1 ? height : 130,
        child: HydrationWaveProvider(
          child: HydrationCard(onAddWater: () {}, remainingLiters: 3.5),
        ),
      );
    }
    if (item.title == "Heart Rate") {
      return SizedBox(
        width: width,
        height: item.heightCells == 1 ? height : 130,
        child: const HeartRateCard(),
      );
    }
    if (item.title == "Calories") {
      return SizedBox(width: width, height: height, child: _caloriesCard());
    }
    if (item.title == "Protein") {
      return SizedBox(width: width, height: height, child: _proteinCard());
    }
    if (item.title == "Sleep") {
      return SizedBox(width: width, height: height, child: _sleepCard());
    }
    final tile = Container(
      width: width,
      height: feedbackHeight,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            item.heightCells == 2 ? "Tall" : "Short",
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );

    if (isFeedback) {
      return Transform.scale(scale: 1.05, child: tile);
    }

    return tile;
  }
}

class GaugePainter extends CustomPainter {
  final double progress;

  GaugePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 14.0;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);

    final backgroundPaint = Paint()
      ..color = Color(0xffF1FEF4)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = Color(0xff098C26)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    /// Draw background arc (full half circle)
    canvas.drawArc(
      rect,
      math.pi, // start
      math.pi, // sweep (180°)
      false,
      backgroundPaint,
    );

    /// Draw progress arc
    canvas.drawArc(rect, math.pi, math.pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

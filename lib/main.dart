import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

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
  GridItem(this.title, this.color, this.heightCells);
}

class MetricsGridPage extends StatefulWidget {
  const MetricsGridPage({super.key});

  @override
  State<MetricsGridPage> createState() => _MetricsGridPageState();
}

class _MetricsGridPageState extends State<MetricsGridPage> {
  List<GridItem> items = [
    GridItem("Steps", Colors.red.shade300, 2),
    GridItem("Hydration", Colors.blue.shade300, 1),
    GridItem("Heart Rate", Colors.green.shade300, 1),
    GridItem("Calories", Colors.orange.shade300, 1),
    GridItem("Sleep", Colors.purple.shade300, 2),
    GridItem("Protein", Colors.teal.shade300, 1),
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
                  child: StaggeredGrid.count(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      return StaggeredGridTile.count(
                        crossAxisCellCount: 1,
                        mainAxisCellCount: item.heightCells,
                        child: buildDragTile(item, index, context),
                      );
                    }),
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
    if (item.title == "Steps") {
      // Use the new StepsCard widget for the Steps item
      return SizedBox(
        width: feedbackWidth,
        height: feedbackHeight ?? 270,
        child: const StepsCard(),
      );
    }
    final tile = Container(
      width: feedbackWidth,
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

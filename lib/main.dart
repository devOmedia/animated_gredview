import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drag Staggered Grid Demo',
      theme: ThemeData.light(),
      home: const Scaffold(body: SafeArea(child: DynamicDragStaggeredGrid())),
    );
  }
}

class GridItem {
  final String title;
  final Color color;
  final int heightCells; // 1 = short, 2 = tall
  GridItem(this.title, this.color, this.heightCells);
}

class DynamicDragStaggeredGrid extends StatefulWidget {
  const DynamicDragStaggeredGrid({super.key});

  @override
  State<DynamicDragStaggeredGrid> createState() =>
      _DynamicDragStaggeredGridState();
}

class _DynamicDragStaggeredGridState extends State<DynamicDragStaggeredGrid> {
  bool showAddButton = false;

  // Modified to 2 seconds
  final Duration longLongPressDuration = const Duration(seconds: 2);

  final GlobalKey gridKey = GlobalKey();

  List<GridItem> items = [
    GridItem('Steps', Colors.redAccent, 2),
    GridItem('Hydration', Colors.greenAccent, 1),
    GridItem('Heart Rate', Colors.blueAccent, 1),
    GridItem('Calories', Colors.orangeAccent, 1),
    GridItem('Sleep', Colors.tealAccent, 2),
    GridItem('Protein', Colors.purpleAccent, 1),
  ];

  int? draggingIndex;
  Offset? dragOffset;
  bool isDeleting = false;

  final int crossAxisCount = 2;
  final double spacing = 12;
  final double baseCellHeight = 100;
  final double deleteButtonSize = 60.0;

  // Function to show button + auto-hide
  void triggerAddButton() {
    setState(() => showAddButton = true);

    // Auto-hide after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && showAddButton) {
        setState(() => showAddButton = false);
      }
    });
  }

  void swapItems(int from, int to) {
    setState(() {
      if (from == to) return;
      final item = items.removeAt(from);
      items.insert(to, item);
    });
  }

  void addItem() {
    final newIndex = items.length + 1;
    final isTall = (newIndex % 5 == 0);
    items.add(
      GridItem(
        'Item $newIndex',
        Colors.primaries[newIndex % Colors.primaries.length].shade300,
        isTall ? 2 : 1,
      ),
    );
    setState(() {});
  }

  double computeTileHeight(int heightCells) =>
      (baseCellHeight * heightCells) + (spacing * (heightCells - 1));

  double computeTileWidth(BuildContext context, int heightCells) {
    final totalPadding = 12 * 2;
    final crossSpacingTotal = spacing;
    final screenWidth = MediaQuery.of(context).size.width;
    final available = screenWidth - totalPadding - crossSpacingTotal;
    return available / crossAxisCount;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        GestureDetector(
          onLongPressStart: (_) {
            Future.delayed(longLongPressDuration, () {
              if (mounted) triggerAddButton();
            });
          },
          onTap: () {
            if (showAddButton) setState(() => showAddButton = false);
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Add card'),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Long-press a card to drag and drop to swap'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: StaggeredGrid.count(
                    key: gridKey,
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      return StaggeredGridTile.count(
                        crossAxisCellCount: 1,
                        mainAxisCellCount: item.heightCells,
                        child: GestureDetector(
                          onLongPressStart: (_) {
                            Future.delayed(longLongPressDuration, () {
                              if (mounted) triggerAddButton();
                            });
                          },
                          child: DragTarget<int>(
                            onWillAcceptWithDetails: (fromIndex) =>
                                fromIndex != index,
                            onAcceptWithDetails: (fromIndex) {
                              swapItems(fromIndex.data, index);
                            },
                            builder: (context, candidateData, rejectedData) {
                              return LongPressDraggable<int>(
                                data: index,
                                feedback: Material(
                                  color: Colors.transparent,
                                  elevation: 6,
                                  child: buildTile(
                                    item,
                                    isFeedback: true,
                                    computedWidth: computeTileWidth(
                                      context,
                                      item.heightCells,
                                    ),
                                    computedHeight: computeTileHeight(
                                      item.heightCells,
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.25,
                                  child: buildTile(item, isDragging: true),
                                ),
                                onDragStarted: () {
                                  setState(() {
                                    draggingIndex = index;
                                  });
                                },
                                onDragUpdate: (details) {
                                  setState(() {
                                    dragOffset = details.globalPosition;
                                  });
                                },
                                onDragEnd: (details) async {
                                  final offset = dragOffset;
                                  if (offset != null &&
                                      offset.dy >
                                          screenHeight -
                                              deleteButtonSize -
                                              20) {
                                    setState(() => isDeleting = true);
                                    await Future.delayed(
                                      const Duration(milliseconds: 200),
                                    );
                                    setState(() {
                                      items.removeAt(draggingIndex!);
                                      isDeleting = false;
                                    });
                                  }
                                  setState(() {
                                    draggingIndex = null;
                                    dragOffset = null;
                                  });
                                },
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: AnimatedContainer(
                                    key: ValueKey(item.title),
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    child: buildTile(
                                      item,
                                      key: ValueKey(item.title),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),

        // DELETE BUTTON DURING DRAG
        if (draggingIndex != null)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isDeleting ? 1.5 : 1.0,
                curve: Curves.easeInOut,
                child: Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final deleteButtonRadius = deleteButtonSize / 2;
                    final deleteButtonCenter = Offset(
                      screenWidth / 2,
                      MediaQuery.of(context).size.height -
                          deleteButtonRadius -
                          10,
                    );

                    bool isOverDelete = false;
                    if (dragOffset != null) {
                      final dx = dragOffset!.dx - deleteButtonCenter.dx;
                      final dy = dragOffset!.dy - deleteButtonCenter.dy;
                      final distance = sqrt(dx * dx + dy * dy);
                      if (distance <= deleteButtonRadius) {
                        isOverDelete = true;
                      }
                    }

                    final buttonColor = (isOverDelete || isDeleting)
                        ? Colors.redAccent
                        : Colors.grey;

                    return Container(
                      height: deleteButtonSize,
                      width: deleteButtonSize,
                      decoration: BoxDecoration(
                        color: buttonColor,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

        // ADD NEW CARD BUTTON
        if (showAddButton)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F8CFF), Color(0xFF2355D6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    addItem();
                    setState(() => showAddButton = false);
                  },
                  icon: const Icon(Icons.add, color: Colors.white, size: 24),
                  label: const Text(
                    'Add Card',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildTile(
    GridItem item, {
    Key? key,
    bool isFeedback = false,
    bool isDragging = false,
    double? computedWidth,
    double? computedHeight,
  }) {
    final tile = Container(
      key: key,
      width: computedWidth,
      height: computedHeight,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
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
            item.heightCells == 2 ? 'Tall' : 'Short',
            style: const TextStyle(fontSize: 12),
          ),
          const Align(
            alignment: Alignment.bottomRight,
            child: Icon(Icons.drag_handle),
          ),
        ],
      ),
    );

    if (isFeedback) {
      return Transform.scale(
        scale: 1.02,
        child: Opacity(
          opacity: 0.98,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: tile,
          ),
        ),
      );
    }

    return AnimatedScale(
      duration: const Duration(milliseconds: 300),
      scale: isDragging ? 0.98 : 1.0,
      child: tile,
    );
  }
}

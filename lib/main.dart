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

class _DynamicDragStaggeredGridState extends State<DynamicDragStaggeredGrid>
    with SingleTickerProviderStateMixin {
  List<GridItem> items = [
    GridItem('Steps', Colors.red.shade300, 2),
    GridItem('Hydration', Colors.green.shade300, 1),
    GridItem('Heart Rate', Colors.blue.shade300, 1),
    GridItem('Calories', Colors.orange.shade300, 1),
    GridItem('Sleep', Colors.teal.shade300, 2),
    GridItem('Protein', Colors.purple.shade300, 1),
  ];

  int? draggingIndex;
  Offset? dragOffset; // track position for overlap detection
  bool isDeleting = false; // trigger delete button animation

  final int crossAxisCount = 2;
  final double spacing = 12;
  final double baseCellHeight = 100;
  final double deleteButtonSize = 60.0;

  void _swapItems(int from, int to) {
    setState(() {
      if (from == to) return;
      final item = items.removeAt(from);
      items.insert(to, item);
    });
  }

  void _addItem() {
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

  double _computeTileHeight(int heightCells) =>
      (baseCellHeight * heightCells) + (spacing * (heightCells - 1));

  double _computeTileWidth(BuildContext context, int heightCells) {
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
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8,
              ),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add card'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: const Text(
                      'Long-press a card to drag and drop to swap',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: StaggeredGrid.count(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    return StaggeredGridTile.count(
                      crossAxisCellCount: 1,
                      mainAxisCellCount: item.heightCells,
                      child: DragTarget<int>(
                        onWillAcceptWithDetails: (fromIndex) =>
                            fromIndex != index,
                        onAcceptWithDetails: (fromIndex) {
                          _swapItems(fromIndex.data, index);
                        },
                        builder: (context, candidateData, rejectedData) {
                          return LongPressDraggable<int>(
                            data: index,
                            feedback: Material(
                              color: Colors.transparent,
                              elevation: 6,
                              child: _buildTile(
                                item,
                                isFeedback: true,
                                computedWidth: _computeTileWidth(
                                  context,
                                  item.heightCells,
                                ),
                                computedHeight: _computeTileHeight(
                                  item.heightCells,
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.25,
                              child: _buildTile(item, isDragging: true),
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
                                      screenHeight - deleteButtonSize - 20) {
                                // Trigger delete animation
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
                                child: _buildTile(
                                  item,
                                  key: ValueKey(item.title),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
        // Bottom-center delete button with animation
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
                child: Container(
                  height: deleteButtonSize,
                  width: deleteButtonSize,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.delete, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTile(
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
          Align(
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

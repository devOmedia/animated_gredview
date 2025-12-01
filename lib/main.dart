import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// Dynamic drag & drop staggered grid example
///
/// - Long press a tile to drag it
/// - Drop onto any other tile to swap positions (Option 1: free reorder)
/// - Tiles animate visually while being dragged (scale/opacity)
///
/// Add to your pubspec.yaml:
///
/// dependencies:
///   flutter:
///     sdk: flutter
///   flutter_staggered_grid_view: ^0.6.2
///
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
  // Base items - you can add/remove at runtime
  List<GridItem> items = [
    GridItem('Steps', Colors.red.shade300, 2),
    GridItem('Hydration', Colors.green.shade300, 1),
    GridItem('Heart Rate', Colors.blue.shade300, 1),
    GridItem('Calories', Colors.orange.shade300, 1),
    GridItem('Protein', Colors.purple.shade300, 1),
    GridItem('Sleep', Colors.teal.shade300, 2),
  ];

  // Visual state while dragging
  int? draggingIndex;

  // Layout constants
  final int crossAxisCount = 2; // two columns as in your design
  final double spacing = 12;
  final double baseCellHeight = 100;

  // Swap helper
  void _swapItems(int from, int to) {
    setState(() {
      if (from == to) return;
      final item = items.removeAt(from);
      items.insert(to, item);
    });
  }

  // Add a new random item (demo of dynamic add)
  void _addItem() {
    final newIndex = items.length + 1;
    final isTall = (newIndex % 5 == 0); // every 5th item tall (example)
    items.add(
      GridItem(
        'Item $newIndex',
        Colors.primaries[newIndex % Colors.primaries.length].shade300,
        isTall ? 2 : 1,
      ),
    );
    setState(() {});
  }

  double _computeTileHeight(int heightCells) {
    // Each "cell" has baseCellHeight; multiple cells increase height
    return (baseCellHeight * heightCells) + (spacing * (heightCells - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add card'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: const Text('Long-press a card to drag and drop to swap'),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: StaggeredGrid.count(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                children: List.generate(items.length, (index) {
                  final item = items[index];

                  // Each tile is both a DragTarget (to accept drops) and a LongPressDraggable
                  return StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: item.heightCells,
                    child: DragTarget<int>(
                      onWillAcceptWithDetails: (fromIndex) =>
                          fromIndex != index,
                      onAcceptWithDetails: (details) {
                        final fromIndex = details.data;
                        _swapItems(fromIndex, index);
                      },
                      builder: (context, candidateData, rejectedData) {
                        // Show highlight if something is hovering here
                        final hovering = candidateData.isNotEmpty;

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
                          onDraggableCanceled: (_, __) {
                            setState(() {
                              draggingIndex = null;
                            });
                          },
                          onDragEnd: (_) {
                            setState(() {
                              draggingIndex = null;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: hovering
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: _buildTile(item),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _computeTileWidth(BuildContext context, int heightCells) {
    // compute width for feedback snapshot (full column width minus paddings)
    final totalPadding = 12 * 2; // parent padding left+right
    final crossSpacingTotal = spacing; // spacing between two columns
    final screenWidth = MediaQuery.of(context).size.width;
    final available = screenWidth - totalPadding - crossSpacingTotal;
    return available / crossAxisCount;
  }

  Widget _buildTile(
    GridItem item, {
    bool isFeedback = false,
    bool isDragging = false,
    double? computedWidth,
    double? computedHeight,
  }) {
    // Visual animation while dragging: scale up the feedback slightly
    final tile = Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.heightCells == 2 ? 'Tall' : 'Short',
                style: const TextStyle(fontSize: 12),
              ),
              const Icon(Icons.drag_handle),
            ],
          ),
        ],
      ),
    );

    if (isFeedback) {
      // Slight scale and shadow for drag feedback
      return Transform.scale(
        scale: 1.02,
        child: Opacity(
          opacity: 0.98,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
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

    // Normal tile with small animation when being dragged
    return AnimatedScale(
      duration: const Duration(milliseconds: 300),
      scale: isDragging ? 0.98 : 1.0,
      child: tile,
    );
  }
}

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

  // -----------------------------
  //     SMART CLEAN ADD BUTTON
  // -----------------------------
  void showAddCardButton() {
    setState(() => showAddButton = true);

    // Auto-hide after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && showAddButton) {
        setState(() => showAddButton = false);
      }
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

  void swapItems(int from, int to) {
    setState(() {
      final item = items.removeAt(from);
      items.insert(to, item);
    });
  }

  double computeTileHeight(int heightCells) =>
      (baseCellHeight * heightCells) + (spacing * (heightCells - 1));

  double computeTileWidth(BuildContext context, int heightCells) {
    final totalPadding = 12 * 2;
    final crossSpacingTotal = spacing;
    final width = MediaQuery.of(context).size.width;
    return (width - totalPadding - crossSpacingTotal) / crossAxisCount;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        GestureDetector(
          onDoubleTap: () {
            showAddCardButton();
          },
          onTap: () {
            if (showAddButton) setState(() => showAddButton = false);
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: const [
                    Icon(Icons.touch_app),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Double-tap empty area to add a new card',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),

              // -----------------------
              //     GRID VIEW
              // -----------------------
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
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
                        child: DragTarget<int>(
                          onWillAcceptWithDetails: (from) => from != index,
                          onAcceptWithDetails: (from) =>
                              swapItems(from.data, index),
                          builder: (context, _, __) {
                            return LongPressDraggable<int>(
                              data: index,
                              feedback: Material(
                                color: Colors.transparent,
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
                                opacity: 0.3,
                                child: buildTile(item),
                              ),
                              onDragStarted: () =>
                                  setState(() => draggingIndex = index),
                              onDragUpdate: (details) => setState(
                                () => dragOffset = details.globalPosition,
                              ),
                              onDragEnd: (details) async {
                                final offset = dragOffset;

                                if (offset != null &&
                                    offset.dy >
                                        screenHeight - deleteButtonSize - 20) {
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
                              child: buildTile(item),
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
        ),

        // ---------------------------------
        //        DRAG DELETE BUTTON
        // ---------------------------------
        if (draggingIndex != null)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedScale(
                scale: isDeleting ? 1.5 : 1,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  height: deleteButtonSize,
                  width: deleteButtonSize,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
              ),
            ),
          ),

        // ---------------------------------
        //         SMART ADD BUTTON
        // ---------------------------------
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          bottom: showAddButton ? 25 : -100,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: showAddButton ? 1 : 0,
            child: Center(
              child: FloatingActionButton.extended(
                backgroundColor: Colors.blueAccent,
                label: const Text("Add Card"),
                icon: const Icon(Icons.add),
                onPressed: () {
                  addItem();
                  setState(() => showAddButton = false);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTile(
    GridItem item, {
    bool isFeedback = false,
    double? computedWidth,
    double? computedHeight,
  }) {
    final tile = Container(
      width: computedWidth,
      height: computedHeight,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(12),
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
      return Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: tile,
      );
    }

    return tile;
  }
}

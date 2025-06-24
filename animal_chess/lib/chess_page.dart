// chess_page.dart
import 'package:flutter/material.dart';

import 'chess_manager.dart';

class ChessPage extends StatelessWidget {
  final ChessManager _manager = ChessManager();

  ChessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('斗兽棋')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        _buildDialog(),
        _buildInfo(),
        Expanded(
          child: _buildMapRegion(),
        ),
      ],
    );
  }

  Widget _buildDialog() {
    return ValueListenableBuilder(
      valueListenable: _manager.showPage,
      builder: (context, value, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          value(context);
          _manager.showPage.value = (BuildContext context) {};
        });
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildInfo() {
    return ValueListenableBuilder(
      valueListenable: _manager.info,
      builder: (context, value, child) {
        return Text(value);
      },
    );
  }

  Widget _buildMapRegion() => AspectRatio(
        aspectRatio: 1.0, // 宽高比为1:1（正方形）
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey, width: 8),
            ),
            child: ValueListenableBuilder(
              valueListenable: _manager.displayMap,
              builder: (context, map, _) {
                if (map.isEmpty || map[0].isEmpty) {
                  return const Center(child: Text('地图数据为空'));
                }

                final int rows = map.length; // 行数（y轴，纵向单元格数量）
                final int cols = map[0].length; // 列数（x轴，横向单元格数量）

                return LayoutBuilder(
                  builder: (context, constraints) {
                    //取像素整数
                    int containerWidth = (constraints.maxWidth ~/ cols) * cols;
                    int containerHeight =
                        (constraints.maxHeight ~/ rows) * rows;

                    int containerSize = containerWidth < containerHeight
                        ? containerWidth
                        : containerHeight;

                    return SizedBox(
                      width: containerSize.toDouble(),
                      height: containerSize.toDouble(),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols, // 列数
                          childAspectRatio: 1, // 单元格正方形
                          mainAxisSpacing: 0, // 移除网格间距
                          crossAxisSpacing: 0,
                        ),
                        itemCount: rows * cols, // 总单元格数
                        itemBuilder: (context, index) {
                          final x = index % cols; // x坐标（列）
                          final y = index ~/ cols; // y坐标（行）
                          return ValueListenableBuilder(
                            valueListenable: map[y][x],
                            builder: (context, value, child) {
                              return GestureDetector(
                                onTap: () => _manager.selectGrid(Point(x, y)),
                                child: Container(
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: _getGridColor(value),
                                      border: Border.all(
                                        color: value.isSelected
                                            ? Colors.yellow
                                            : value.isHighlighted
                                                ? Colors.green
                                                : Colors.grey,
                                        width: value.isSelected ||
                                                value.isHighlighted
                                            ? 3
                                            : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: value.isEmpty
                                        ? null
                                        : Container(
                                            margin: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: value.animal!.displayColor,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Center(
                                              child: Text(
                                                value.animal!.displayName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          )),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

  static Color _getGridColor(Grid grid) {
    switch (grid.type) {
      case GridType.land:
        return Colors.white; // 陆地
      case GridType.river:
        return Colors.blue[200]!; // 河流
      case GridType.road:
        return Colors.grey[300]!; // 道路
      case GridType.bridge:
        return Colors.yellow; // 桥
      case GridType.tree:
        return Colors.brown; // 树林
    }
  }
}

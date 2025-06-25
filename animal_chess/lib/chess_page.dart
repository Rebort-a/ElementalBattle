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
      valueListenable: _manager.currentPlayer,
      builder: (context, value, child) {
        return buildTurnIndicator(value);
      },
    );
  }

  Widget buildTurnIndicator(PlayerType playerType) {
    bool isRedTurn = playerType == PlayerType.red;
    final backgroundColor = isRedTurn ? Colors.red : Colors.blue;
    final text = isRedTurn ? "红方回合" : "蓝方回合";

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMapRegion() => AspectRatio(
        aspectRatio: 1.0, // 宽高比为1:1（正方形）
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.brown, width: 8),
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
                                  margin: const EdgeInsets.all(4),
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
                                          margin: const EdgeInsets.all(8),
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
                                                fontSize: 32,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
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
      case GridType.land: // 陆地
      case GridType.road: // 道路
      case GridType.bridge: // 桥
        return Colors.white;
      case GridType.river: // 河流
        return Colors.blue[200]!;
      case GridType.tree: // 树
        return Colors.brown;
    }
  }
}

// chess_page.dart
import 'package:flutter/material.dart';

import 'chess_manager.dart';

class ChessPage extends StatelessWidget {
  final ChessManager _manager = ChessManager();

  ChessPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('斗兽棋')),
        body: Column(
          children: [
            _buildDialog(),
            _buildTurnIndicator(),
            Expanded(child: _buildGameBoard()),
          ],
        ),
      );

  Widget _buildDialog() {
    return ValueListenableBuilder(
      valueListenable: _manager.showPage,
      builder: (context, show, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          show(context);
          _manager.showPage.value = (BuildContext context) {};
        });
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTurnIndicator() => ValueListenableBuilder(
        valueListenable: _manager.currentPlayer,
        builder: (_, player, __) => Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: player == PlayerType.red ? Colors.red : Colors.blue,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${player == PlayerType.red ? "红" : "蓝"}方回合',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );

  Widget _buildGameBoard() => AspectRatio(
        aspectRatio: 1,
        child: Center(
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.brown, width: 8)),
            child: ValueListenableBuilder(
              valueListenable: _manager.displayMap,
              builder: (_, map, __) => LayoutBuilder(
                builder: (context, constraints) {
                  final size =
                      _calculateBoardSize(constraints, ChessManager.boardSize);
                  return SizedBox(
                    width: size,
                    height: size,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: ChessManager.boardSize,
                        childAspectRatio: 1,
                      ),
                      itemCount:
                          (ChessManager.boardSize * ChessManager.boardSize),
                      itemBuilder: (_, i) {
                        return _buildGridCell(map[i]);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

  double _calculateBoardSize(BoxConstraints constraints, int cellCount) {
    final maxSize = constraints.maxWidth;
    return (maxSize ~/ cellCount) * cellCount.toDouble();
  }

  Widget _buildGridCell(ValueNotifier<Grid> gridNotifier) =>
      ValueListenableBuilder(
        valueListenable: gridNotifier,
        builder: (_, grid, __) => GestureDetector(
          onTap: () => _manager.selectGrid(grid.coordinate),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: _backgroundColor(grid),
                border: _gridBorder(grid),
                borderRadius: BorderRadius.circular(5)),
            child: grid.haveAnimal ? _buildAnimal(grid) : null,
          ),
        ),
      );

  Border _gridBorder(Grid grid) => Border.all(
        color: _getBorderColor(grid),
        width: _borderWidth(grid),
      );

  Widget _buildAnimal(Grid grid) => Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: _childColor(grid.animal!),
            borderRadius: BorderRadius.circular(5)),
        child: Center(
          child: Text(_childContent(grid.animal!),
              style: const TextStyle(fontSize: 32)),
        ),
      );

  // 获取格子背景色
  Color _backgroundColor(Grid grid) {
    return switch (grid.type) {
      GridType.river => Colors.blue[200]!,
      GridType.tree => Colors.brown,
      _ => Colors.white,
    };
  }

  // 获取边框颜色
  Color _getBorderColor(Grid grid) {
    if (grid.haveAnimal && grid.animal!.isSelected) return Colors.yellow;
    if (grid.isHighlighted) return Colors.green;
    return Colors.grey;
  }

  // 获取边框宽度
  double _borderWidth(Grid grid) {
    if ((grid.haveAnimal && grid.animal!.isSelected) || grid.isHighlighted) {
      return 3.0;
    }
    return 1.0;
  }

  // 获取边框颜色
  Color _childColor(Animal animal) {
    return animal.isHidden ? Colors.blueGrey : animal.color;
  }

  String _childContent(Animal animal) {
    return animal.isHidden ? "" : animal.emoji;
  }
}

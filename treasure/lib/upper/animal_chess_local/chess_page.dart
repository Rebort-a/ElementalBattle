import 'package:flutter/material.dart';

import '../../middleware/front_end.dart';

import 'chess_manager.dart';

class ChessPage extends StatelessWidget {
  final ChessManager _manager = ChessManager();

  ChessPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _manager.leaveChess,
          ),
          title: const Text('斗兽棋'),
          centerTitle: true,
        ),
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
      builder: (context, showDialogFunc, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialogFunc(context);
          _manager.showPage.value = (_) {}; // Reset after showing
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
            style: globalTheme.textTheme.titleMedium
                ?.copyWith(color: Colors.white),
          ),
        ),
      );

  Widget _buildGameBoard() => AspectRatio(
        aspectRatio: 1,
        child: Center(
          child: Container(
            decoration: _boardDecoration(),
            child: ValueListenableBuilder(
              valueListenable: _manager.displayMap,
              builder: (_, gridNotifiers, __) => LayoutBuilder(
                builder: (context, constraints) {
                  final size =
                      _calculateBoardSize(constraints, ChessManager.boardSize);
                  return SizedBox(
                    width: size,
                    height: size,
                    child: _buildBoardGrid(gridNotifiers),
                  );
                },
              ),
            ),
          ),
        ),
      );

  BoxDecoration _boardDecoration() => BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.brown, width: 8),
      );

  Widget _buildBoardGrid(List<GridNotifier> gridNotifiers) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ChessManager.boardSize,
      ),
      itemCount: gridNotifiers.length,
      itemBuilder: (_, index) => _buildGridCell(gridNotifiers[index]),
    );
  }

  Widget _buildGridCell(GridNotifier notifier) => ValueListenableBuilder(
        valueListenable: notifier,
        builder: (_, grid, __) => GestureDetector(
          onTap: () => _manager.selectGrid(grid.coordinate),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: _gridDecoration(grid),
            child: grid.hasAnimal ? _buildAnimal(grid.animal!) : null,
          ),
        ),
      );

  BoxDecoration _gridDecoration(GridState grid) => BoxDecoration(
        color: _gridColor(grid),
        border: _gridBorder(grid),
        borderRadius: BorderRadius.circular(4),
      );

  Color _gridColor(GridState grid) {
    return switch (grid.type) {
      GridType.river => Colors.blue[200]!,
      GridType.tree => Colors.brown[400]!,
      _ => Colors.grey[100]!,
    };
  }

  Border _gridBorder(GridState grid) => Border.all(
        color: _borderColor(grid),
        width: _borderWidth(grid),
      );

  Color _borderColor(GridState grid) {
    if (grid.hasAnimal && grid.animal!.isSelected) return Colors.yellow;
    if (grid.isHighlighted) return Colors.green;
    return Colors.grey;
  }

  double _borderWidth(GridState grid) {
    if (grid.isHighlighted) return 4.0;
    if (grid.hasAnimal && grid.animal!.isSelected) return 3.0;
    return 1.0;
  }

  Widget _buildAnimal(Animal animal) => Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: animal.isHidden ? Colors.blueGrey : animal.color,
            borderRadius: BorderRadius.circular(5)),
        child: Center(
          child: Text(animal.isHidden ? "" : animal.emoji,
              style: const TextStyle(fontSize: 32)),
          // child: Text(_childContent(grid.animal!),
          //     style: globalTheme.textTheme.displayLarge),
        ),
      );

  double _calculateBoardSize(BoxConstraints constraints, int cellCount) {
    final double maxSize = constraints.maxWidth;
    return (maxSize ~/ cellCount) * cellCount.toDouble();
  }
}

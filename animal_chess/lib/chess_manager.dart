import 'dart:math';

import 'package:flutter/material.dart';

import 'models.dart';

enum AnimalType { elephant, tiger, lion, leopard, wolf, dog, cat, mouse }

const List<String> emojis = ["🐘", "🐅", "🦁", "🐆", "🐺", "🐕", "🐈️", "🐭"];

enum PlayerType { red, blue }

enum GridType { land, river, road, bridge, tree }

class Animal {
  final AnimalType type;
  final PlayerType owner;
  bool isSelected;
  bool isHidden;

  Animal({
    required this.type,
    required this.owner,
    required this.isSelected,
    required this.isHidden,
  });

  bool canEat(Animal? other) {
    if (other == null) return true;
    if (type == other.type) return true;

    return switch (type) {
      AnimalType.mouse when other.type == AnimalType.elephant => true,
      AnimalType.elephant when other.type == AnimalType.mouse => false,
      _ => type.index < other.type.index,
    };
  }

  bool canMoveTo(GridType from, GridType target) => switch (target) {
        GridType.river => [
            AnimalType.elephant,
            AnimalType.dog,
            AnimalType.mouse
          ].contains(type),
        GridType.bridge =>
          (from != GridType.river || type == AnimalType.mouse) &&
              type != AnimalType.elephant,
        GridType.tree =>
          [AnimalType.leopard, AnimalType.cat, AnimalType.mouse].contains(type),
        _ => true,
      };

  String get emoji => emojis[type.index];
  Color get color => owner == PlayerType.red ? Colors.red : Colors.blue;
}

class Grid {
  final int coordinate;
  final GridType type;
  bool isHighlighted;
  Animal? animal;

  Grid({
    required this.coordinate,
    required this.type,
    this.isHighlighted = false,
    this.animal,
  });

  bool get haveAnimal => animal != null;
}

class GridNotifier extends ValueNotifier<Grid> {
  GridNotifier(super.value);

  // 清除棋子
  void clearAnimal() {
    value.animal = null;
    notifyListeners();
  }

  // 翻开棋子
  void reveal() {
    if (value.haveAnimal) {
      value.animal!.isHidden = false;
    }
    notifyListeners();
  }

  // 选中棋子
  void setSelection() {
    if (value.haveAnimal) {
      value.animal!.isSelected = true;
    }
    notifyListeners();
  }

  // 取消选中
  void clearSelection() {
    if (value.haveAnimal) {
      value.animal!.isSelected = false;
    }
    notifyListeners();
  }

  // 高亮格子
  void setHighlights() {
    value.isHighlighted = true;
    notifyListeners();
  }

  // 取消高亮
  void clearHighlights() {
    value.isHighlighted = false;
    notifyListeners();
  }

  // 设置棋子
  void setAnimal(Animal animal) {
    value.animal = animal;
    notifyListeners();
  }
}

class ChessManager {
  static const int _boardLevel = 2;
  static const int boardSize = _boardLevel * 2 + 1;
  static const _directions = [
    (-1, 0), // 上
    (1, 0), // 下
    (0, -1), // 左
    (0, 1), // 右
  ];

  final Random _random = Random();

  final AlwaysNotifier<void Function(BuildContext)> showPage =
      AlwaysNotifier((_) {});
  final ValueNotifier<PlayerType> currentPlayer = ValueNotifier(PlayerType.red);
  final ListNotifier<GridNotifier> displayMap = ListNotifier([]);

  // 选中和高亮状态管理列表
  // 第一个元素是选中的格子索引，后续元素是高亮的格子索引
  final List<int> _signGrids = [];

  ChessManager() {
    _initializeGame();
  }

  // 初始化游戏
  void _initializeGame() {
    _setupBoard();
    _distributePieces();
    _signGrids.clear();
  }

  // 设置棋盘
  void _setupBoard() {
    displayMap.value = List.generate(boardSize * boardSize, (index) {
      return GridNotifier(Grid(
        coordinate: index,
        type: _getTerrainType(index),
      ));
    });
  }

  // 确定地形类型
  GridType _getTerrainType(int index) {
    final row = index ~/ boardSize;
    final col = index % boardSize;

    if (col == _boardLevel) {
      if (row == _boardLevel) return GridType.bridge;
      if (index == _boardLevel || index == _boardLevel * (2 * boardSize + 1)) {
        return GridType.tree;
      }
      return GridType.road;
    }
    return row == _boardLevel ? GridType.river : GridType.land;
  }

  // 随机分配棋子
  void _distributePieces() {
    const pieces = AnimalType.values;
    final positions = _getLandPositions()..shuffle(_random);

    _placePieces(PlayerType.red, pieces, positions.take(pieces.length));
    _placePieces(PlayerType.blue, pieces,
        positions.skip(pieces.length).take(pieces.length));
  }

  // 获取所有陆地位置
  List<int> _getLandPositions() {
    final positions = <int>[];
    for (int i = 0; i < displayMap.length; i++) {
      if (_getGrid(i).type == GridType.land) {
        positions.add(i);
      }
    }

    return positions;
  }

  // 放置棋子
  void _placePieces(
      PlayerType owner, List<AnimalType> pieces, Iterable<int> positions) {
    for (int i = 0; i < pieces.length; i++) {
      displayMap.value[positions.toList()[i]].setAnimal(Animal(
          type: pieces[i], owner: owner, isSelected: false, isHidden: true));
    }
  }

  // 处理格子点击
  void selectGrid(int index) {
    final grid = _getGrid(index);

    if (grid.haveAnimal && grid.animal!.isHidden) {
      _revealPiece(index);
      return;
    }

    if (_isSelected(index)) {
      _clearSelection();
      return;
    }

    if (_isValidMoveTarget(index)) {
      _movePiece(_signGrids.first, index);
      return;
    }

    if (_canSelect(grid)) {
      _setSelection(index);
    }
  }

  // 翻开棋子
  void _revealPiece(int index) {
    displayMap.value[index].reveal();
    _endTurn();
  }

  // 清除选择状态
  void _clearSelection() {
    if (_signGrids.isNotEmpty) {
      // 清除选中状态
      displayMap.value[_signGrids.first].clearSelection();

      // 清除高亮状态
      for (int i = 1; i < _signGrids.length; i++) {
        displayMap.value[_signGrids[i]].clearHighlights();
      }

      _signGrids.clear();
    }
  }

  // 检查是否可以移动到目标位置
  bool _isValidMoveTarget(int index) {
    return _signGrids.isNotEmpty && _signGrids.skip(1).contains(index);
  }

  // 移动棋子
  void _movePiece(int from, int to) {
    if (_getGrid(from).haveAnimal) {
      if (_getGrid(to).haveAnimal) {
        _resolveCombat(_getGrid(from).animal!, _getGrid(to).animal!, to);
      } else {
        displayMap.value[to].setAnimal(_getGrid(from).animal!);

        // 更新选中位置
        if (_signGrids.isNotEmpty) {
          _signGrids[0] = to;
        }
      }

      displayMap.value[from].clearAnimal();
      _endTurn();
    }
  }

  // 解决战斗
  void _resolveCombat(Animal attacker, Animal defender, int toPos) {
    final attackerWins = attacker.canEat(defender);
    final defenderWins = defender.canEat(attacker);

    if (attackerWins && defenderWins) {
      // 同归于尽
      displayMap.value[toPos].clearAnimal();
    } else if (attackerWins) {
      // 攻击者胜利
      displayMap.value[toPos].setAnimal(attacker);

      // 更新选中位置
      if (_signGrids.isNotEmpty) {
        _signGrids[0] = toPos;
      }
    }
    // 防御者胜利不需要操作
  }

  // 检查是否可以选中该格子
  bool _canSelect(Grid grid) {
    return grid.haveAnimal && grid.animal!.owner == currentPlayer.value;
  }

  // 设置选中状态
  void _setSelection(int index) {
    _clearSelection();
    _signGrids.add(index);
    displayMap.value[index].setSelection();
    _calculatePossibleMoves(index);
  }

  void _calculatePossibleMoves(int index) {
    final row = index ~/ boardSize;
    final col = index % boardSize;

    for (final (dr, dc) in _directions) {
      final newRow = row + dr;
      final newCol = col + dc;

      if (newRow >= 0 &&
          newRow < boardSize &&
          newCol >= 0 &&
          newCol < boardSize) {
        _evaluateMove(index, newRow * boardSize + newCol);
      }
    }
  }

  // 评估移动可能性
  void _evaluateMove(int index, int toPos) {
    final Grid fromGrid = _getGrid(index);
    final Grid toGrid = _getGrid(toPos);

    if (toGrid.haveAnimal && toGrid.animal!.isHidden) {
      return;
    }

    if (toGrid.haveAnimal && toGrid.animal!.owner == fromGrid.animal!.owner) {
      return;
    }

    if (!fromGrid.animal!.canMoveTo(fromGrid.type, toGrid.type)) return;

    displayMap.value[toPos].setHighlights();
    _signGrids.add(toPos);
  }

  // 结束当前回合
  void _endTurn() {
    _clearSelection();
    _switchPlayer();
    _checkGameEnd();
  }

  void _switchPlayer() {
    currentPlayer.value = (currentPlayer.value == PlayerType.red
        ? PlayerType.blue
        : PlayerType.red);
  }

  // 检查游戏是否结束
  void _checkGameEnd() {
    int redCount = 0, blueCount = 0;

    for (int i = 0; i < displayMap.length; i++) {
      final piece = _getGrid(i).animal;
      if (piece != null) {
        piece.owner == PlayerType.red ? redCount++ : blueCount++;
      }
    }

    if (redCount == 0) {
      _showResult(false);
    } else if (blueCount == 0) {
      _showResult(true);
    }
  }

  bool _isSelected(int index) =>
      _signGrids.isNotEmpty && _signGrids.first == index;

  Grid _getGrid(int index) => displayMap.value[index].value;

  void leaveChess() {
    _showResult(currentPlayer.value == PlayerType.blue);
  }

  void _showResult(bool isRedWin) {
    showPage.value = (context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("游戏结束"),
            content: Text("${isRedWin ? "红" : "蓝"}方获胜！"),
            actions: <Widget>[
              TextButton(
                child: const Text('重开'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _restart();
                },
              ),
              TextButton(
                child: const Text('退出'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    };
  }

  // 重新开始游戏
  void _restart() {
    _signGrids.clear();
    currentPlayer.value = PlayerType.red;
    _initializeGame();
  }
}

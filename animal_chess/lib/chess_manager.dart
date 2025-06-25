// chess_manager.dart

import 'dart:math';

import 'package:flutter/material.dart';

import 'models.dart';

enum AnimalType { elephant, tiger, lion, leopard, wolf, dog, cat, mouse }

enum PlayerType { red, blue }

enum GridType { land, river, road, bridge, tree }

class Animal {
  final AnimalType type;
  final PlayerType owner;
  bool isSelected;
  bool isHidden;

  Animal(
      {required this.type,
      required this.owner,
      required this.isSelected,
      required this.isHidden});

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

  String get emoji => _emojis[type.index];
  Color get color => owner == PlayerType.red ? Colors.red : Colors.blue;

  static const _emojis = ["🐘", "🐯", "🦁", "🐆", "🐺", "🐕", "🐈", "🐭"];
}

class Grid {
  final int coordinate;
  final GridType type;
  final bool isHighlighted;
  Animal? animal;

  Grid({
    required this.coordinate,
    required this.type,
    this.isHighlighted = false,
    this.animal,
  });

  bool get haveAnimal => animal != null;

  // 清除棋子
  Grid clearAnimal() {
    animal = null;
    return this;
  }

  // 翻开棋子
  Grid reveal() {
    if (haveAnimal) {
      animal?.isHidden = false;
    }
    return this;
  }

  // 选中棋子
  Grid selectedGrid() {
    if (haveAnimal) {
      animal?.isSelected = true;
    }
    return this;
  }

  // 取消选中
  Grid clearSelection() {
    if (haveAnimal) {
      animal?.isSelected = false;
    }
    return this;
  }

  // 高亮格子
  Grid setHighlights() {
    return copyWith(isHighlighted: true);
  }

  // 取消高亮
  Grid clearHighlights() {
    return copyWith(isHighlighted: false);
  }

  Grid copyWith({
    int? coordinate,
    GridType? type,
    bool? isHighlighted,
    Animal? animal,
  }) {
    return Grid(
      coordinate: coordinate ?? this.coordinate,
      type: type ?? this.type,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      animal: animal ?? this.animal,
    );
  }
}

class ChessManager {
  static const int _boardLevel = 2;
  static const int boardSize = _boardLevel * 2 + 1;

  final Random _random = Random();

  final AlwaysNotifier<void Function(BuildContext)> showPage =
      AlwaysNotifier((_) {});
  final ValueNotifier<PlayerType> currentPlayer = ValueNotifier(PlayerType.red);
  final ListNotifier<ValueNotifier<Grid>> displayMap = ListNotifier([]);

  int? _selectedPos;

  ChessManager() {
    _initializeGame();
  }

  // 初始化游戏
  void _initializeGame() {
    _setupBoard();
    _distributePieces();
  }

  // 设置棋盘
  void _setupBoard() {
    displayMap.value = List.generate(boardSize * boardSize, (index) {
      return ValueNotifier(Grid(
        coordinate: index,
        type: _getTerrainType(index),
      ));
    });
  }

  // 确定地形类型
  GridType _getTerrainType(int index) {
    final isCentralColumn = index % boardSize == _boardLevel;
    final isCentralRow = index ~/ boardSize == _boardLevel;

    if (isCentralColumn) {
      if (isCentralRow) return GridType.bridge;
      if ((index == _boardLevel) ||
          (index == _boardLevel * (2 * boardSize + 1))) {
        return GridType.tree;
      }
      return GridType.road;
    }
    return isCentralRow ? GridType.river : GridType.land;
  }

  // 随机分配棋子
  void _distributePieces() {
    List<AnimalType> redPieces = AnimalType.values.map((type) => type).toList();
    List<AnimalType> bluePieces =
        AnimalType.values.map((type) => type).toList();

    List<int> availableSpots = _getLandPositions();

    redPieces.shuffle(_random);
    bluePieces.shuffle(_random);
    availableSpots.shuffle(_random);

    _placePieces(
        PlayerType.red, redPieces, availableSpots.sublist(0, redPieces.length));
    _placePieces(
        PlayerType.blue,
        bluePieces,
        availableSpots.sublist(
            redPieces.length, redPieces.length + bluePieces.length));
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
      PlayerType owner, List<AnimalType> pieces, List<int> positions) {
    for (int i = 0; i < pieces.length; i++) {
      _setGrid(positions[i], (grid) {
        return grid.copyWith(
            animal: Animal(
                type: pieces[i],
                owner: owner,
                isSelected: false,
                isHidden: true));
      });
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
      _movePiece(_selectedPos!, index);
      return;
    }

    if (_canSelect(grid)) {
      _setSelection(index);
    }
  }

  // 翻开棋子
  void _revealPiece(int index) {
    _setGrid(index, (grid) {
      return grid.reveal();
    });

    _endTurn();
  }

  // 清除选择状态
  void _clearSelection() {
    if (_selectedPos != null) {
      _setGrid(_selectedPos!, (grid) {
        return grid.clearSelection();
      });

      _selectedPos = null;
    }
    _clearHighlights();
  }

  // 清除所有高亮
  void _clearHighlights() {
    for (int i = 0; i < displayMap.length; i++) {
      _setGrid(i, (grid) {
        return grid.clearHighlights();
      });
    }
  }

  // 检查是否可以移动到目标位置
  bool _isValidMoveTarget(int index) {
    return _selectedPos != null && _getGrid(index).isHighlighted;
  }

  // 移动棋子
  void _movePiece(int from, int to) {
    if (_getGrid(from).haveAnimal) {
      if (_getGrid(to).haveAnimal) {
        _resolveCombat(_getGrid(from).animal!, _getGrid(to).animal!, to);
      } else {
        _setGrid(to, (grid) {
          return grid.copyWith(animal: _getGrid(from).animal!);
        });
        _selectedPos = to;
      }

      _setGrid(from, (grid) {
        return grid.clearAnimal();
      });

      _endTurn();
    }
  }

  // 解决战斗
  void _resolveCombat(Animal attacker, Animal defender, int toPos) {
    final attackerWins = attacker.canEat(defender);
    final defenderWins = defender.canEat(attacker);

    if (attackerWins && defenderWins) {
      // 同归于尽
      _setGrid(toPos, (grid) {
        return grid.clearAnimal();
      });
    } else if (attackerWins) {
      // 攻击者胜利
      _setGrid(toPos, (grid) {
        return grid.copyWith(animal: attacker);
      });
      _selectedPos = toPos;
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
    _selectedPos = index;
    _setGrid(index, (grid) {
      return grid.selectedGrid();
    });
    _calculatePossibleMoves(index);
  }

  // 计算可能的移动
  void _calculatePossibleMoves(int index) {
    // 把一维索引转换为二维坐标
    int row = index ~/ boardSize;
    int col = index % boardSize;

    // 定义上下左右四个方向的偏移量
    List<int> dr = [-1, 1, 0, 0]; // 行偏移：上、下、左、右
    List<int> dc = [0, 0, -1, 1]; // 列偏移：上、下、左、右

    // 遍历四个方向
    for (int i = 0; i < 4; i++) {
      // 计算周围格子的坐标
      int newRow = row + dr[i];
      int newCol = col + dc[i];

      // 检查坐标是否超出边界
      if (newRow >= 0 &&
          newRow < boardSize &&
          newCol >= 0 &&
          newCol < boardSize) {
        int toPos = newRow * boardSize + newCol;
        _evaluateMove(index, toPos);
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

    _setGrid(toPos, (grid) {
      return grid.setHighlights();
    });
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

  bool _isSelected(int index) => _selectedPos == index;
  Grid _getGrid(int index) => displayMap.value[index].value;
  void _setGrid(int index, Grid Function(Grid grid) update) {
    displayMap.value[index].value = update(_getGrid(index));
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
    _selectedPos = null;
    currentPlayer.value = PlayerType.red;
    _initializeGame();
  }
}

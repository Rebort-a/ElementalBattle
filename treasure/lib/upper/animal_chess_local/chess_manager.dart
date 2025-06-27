import 'package:flutter/material.dart';

import '../../foundation/model.dart';

enum AnimalType { elephant, tiger, lion, leopard, wolf, dog, cat, mouse }

enum PlayerType { red, blue }

enum GridType { land, river, road, bridge, tree }

const List<String> animalEmojis = [
  "🐘",
  "🐅",
  "🦁",
  "🐆",
  "🐺",
  "🐕",
  "🐈️",
  "🐭"
];

extension PlayerTypeExtension on PlayerType {
  PlayerType get opponent =>
      this == PlayerType.red ? PlayerType.blue : PlayerType.red;
}

class Animal {
  final AnimalType type;
  final PlayerType owner;
  bool isSelected;
  bool isHidden;

  Animal({
    required this.type,
    required this.owner,
    this.isSelected = false,
    this.isHidden = true,
  });

  bool canEat(Animal? other) {
    if (other == null) return true;
    if (type == other.type) return true;

    // 特殊规则：老鼠吃大象
    if (type == AnimalType.mouse && other.type == AnimalType.elephant) {
      return true;
    } else if (type == AnimalType.elephant && other.type == AnimalType.mouse) {
      return false;
    }

    return type.index < other.type.index;
  }

  bool _canEnterRiver() =>
      [AnimalType.elephant, AnimalType.dog, AnimalType.mouse].contains(type);
  bool _canUseBridge(GridType from) =>
      (from != GridType.river || type == AnimalType.mouse) &&
      type != AnimalType.elephant;
  bool _canClimbTree() =>
      [AnimalType.leopard, AnimalType.cat, AnimalType.mouse].contains(type);

  bool canMoveTo(GridType from, GridType target) {
    return switch (target) {
      GridType.river => _canEnterRiver(),
      GridType.bridge => _canUseBridge(from),
      GridType.tree => _canClimbTree(),
      _ => true,
    };
  }

  String get emoji => animalEmojis[type.index];
  Color get color => owner == PlayerType.red ? Colors.red : Colors.blue;
}

class GridState {
  final int coordinate;
  final GridType type;
  bool isHighlighted;
  Animal? animal;

  GridState({
    required this.coordinate,
    required this.type,
    this.isHighlighted = false,
    this.animal,
  });

  bool get hasAnimal => animal != null;
}

class GridNotifier extends ValueNotifier<GridState> {
  GridNotifier(super.value);

  void clearAnimal() {
    value.animal = null;
    notifyListeners();
  }

  void revealAnimal() {
    value.animal?.isHidden = false;
    notifyListeners();
  }

  void toggleSelection(bool selected) {
    value.animal?.isSelected = selected;
    notifyListeners();
  }

  void toggleHighlight(bool highlighted) {
    value.isHighlighted = highlighted;
    notifyListeners();
  }

  void placeAnimal(Animal animal) {
    value.animal = animal;
    notifyListeners();
  }
}

class ChessManager {
  static const int _boardLevel = 2;
  static const int boardSize = _boardLevel * 2 + 1;
  static const _directions = [
    (-1, 0), // up
    (1, 0), // down
    (0, -1), // left
    (0, 1), // right
  ];

  final AlwaysNotifier<void Function(BuildContext)> showPage =
      AlwaysNotifier((_) {});
  final ValueNotifier<PlayerType> currentPlayer = ValueNotifier(PlayerType.red);
  final ListNotifier<GridNotifier> displayMap = ListNotifier([]);
  final List<int> _markedGrid = []; // 第一个元素是当前选中的格子，其余元素是可选的移动目标

  ChessManager() {
    _initializeGame();
  }

  void _initializeGame() {
    _setupBoard();
    _placePieces();
    _resetGameState();
  }

  void _setupBoard() {
    displayMap.value = List.generate(boardSize * boardSize, (index) {
      return GridNotifier(GridState(
        coordinate: index,
        type: _getGridType(index),
      ));
    });
  }

  GridType _getGridType(int index) {
    final row = index ~/ boardSize;
    final col = index % boardSize;

    // 中央列特殊处理
    if (col == _boardLevel) {
      if (row == _boardLevel) return GridType.bridge;
      if (row == 0 || row == boardSize - 1) return GridType.tree;
      return GridType.road;
    }

    // 中央行是河流
    return row == _boardLevel ? GridType.river : GridType.land;
  }

  void _placePieces() {
    final landPositions = _getLandPositions()..shuffle();
    const pieces = AnimalType.values;

    void placePlayerPieces(PlayerType player) {
      for (int i = 0; i < pieces.length; i++) {
        final index = landPositions.removeLast();
        displayMap.value[index].placeAnimal(Animal(
          type: pieces[i],
          owner: player,
        ));
      }
    }

    placePlayerPieces(PlayerType.red);
    placePlayerPieces(PlayerType.blue);
  }

  List<int> _getLandPositions() {
    return displayMap.value
        .asMap()
        .entries
        .where((entry) => entry.value.value.type == GridType.land)
        .map((entry) => entry.key)
        .toList();
  }

  void _resetGameState() {
    _markedGrid.clear();
    currentPlayer.value = PlayerType.red;
  }

  void selectGrid(int index) {
    final grid = displayMap.value[index].value;

    // 如果没有翻面，那么翻面
    if (grid.hasAnimal && grid.animal!.isHidden) {
      _revealPiece(index);
      return;
    }

    // 如果是选中棋子，那么取消棋子和周边的标记
    if (_isSelected(index)) {
      _clearSelectionAndHighlight();
      return;
    }

    // 如果是可选的移动目标，那么移动棋子
    if (_isValidMoveTarget(index)) {
      _movePiece(_markedGrid.first, index);
      return;
    }

    // 如果上面都不是，那么判断是否可以选中棋子
    if (_canSelect(grid)) {
      _setSelection(index);
    }
  }

  void _revealPiece(int index) {
    displayMap.value[index].revealAnimal();
    _endTurn();
  }

  void _clearSelectionAndHighlight() {
    if (_markedGrid.isEmpty) return;

    displayMap.value[_markedGrid.first].toggleSelection(false);

    for (final index in _markedGrid.skip(1)) {
      displayMap.value[index].toggleHighlight(false);
    }

    _markedGrid.clear();
  }

  bool _isValidMoveTarget(int index) {
    return _markedGrid.length > 1 && _markedGrid.skip(1).contains(index);
  }

  void _movePiece(int from, int to) {
    final fromGrid = displayMap.value[from].value;
    if (!fromGrid.hasAnimal) return;

    final movingAnimal = fromGrid.animal!;

    if (displayMap.value[to].value.hasAnimal) {
      _resolveCombat(movingAnimal, displayMap.value[to].value.animal!, to);
    } else {
      displayMap.value[to].placeAnimal(movingAnimal);
      _markedGrid.first = to;
    }

    displayMap.value[from].clearAnimal();
    _endTurn();
  }

  void _resolveCombat(Animal attacker, Animal defender, int targetPos) {
    final attackerWins = attacker.canEat(defender);
    final defenderWins = defender.canEat(attacker);

    if (attackerWins && defenderWins) {
      displayMap.value[targetPos].clearAnimal();
    } else if (attackerWins) {
      displayMap.value[targetPos].placeAnimal(attacker);
      _markedGrid.first = targetPos;
    }
  }

  bool _canSelect(GridState grid) {
    return grid.hasAnimal && grid.animal!.owner == currentPlayer.value;
  }

  void _setSelection(int index) {
    _clearSelectionAndHighlight();
    _markedGrid.add(index);
    displayMap.value[index].toggleSelection(true);
    _calculatePossibleMoves(index);
  }

  void _calculatePossibleMoves(int index) {
    final row = index ~/ boardSize;
    final col = index % boardSize;

    for (final (dr, dc) in _directions) {
      final newRow = row + dr;
      final newCol = col + dc;
      final newIndex = newRow * boardSize + newCol;

      if (newRow >= 0 &&
          newRow < boardSize &&
          newCol >= 0 &&
          newCol < boardSize) {
        if (_isValidMove(index, newIndex)) {
          displayMap.value[newIndex].toggleHighlight(true);
          _markedGrid.add(newIndex);
        }
      }
    }
  }

  bool _isValidMove(int fromIndex, int toIndex) {
    final fromGrid = displayMap.value[fromIndex].value;
    final toGrid = displayMap.value[toIndex].value;

    if (!fromGrid.hasAnimal) return false;
    // 不能移动到隐藏的棋子
    if (toGrid.animal?.isHidden == true) return false;
    // 不能吃己方棋子
    if (toGrid.hasAnimal && toGrid.animal!.owner == fromGrid.animal!.owner) {
      return false;
    }

    // 检查移动规则
    return fromGrid.animal!.canMoveTo(fromGrid.type, toGrid.type);
  }

  void _endTurn() {
    _clearSelectionAndHighlight();
    currentPlayer.value = currentPlayer.value.opponent;
    _checkGameEnd();
  }

  void _checkGameEnd() {
    int redCount = 0, blueCount = 0;

    for (final gridNotifier in displayMap.value) {
      final animal = gridNotifier.value.animal;
      if (animal != null) {
        animal.owner == PlayerType.red ? redCount++ : blueCount++;
      }
    }

    if (redCount == 0) {
      _showResult(false); // blue wins
    } else if (blueCount == 0) {
      _showResult(true); // red wins
    }
  }

  bool _isSelected(int index) =>
      _markedGrid.isNotEmpty && _markedGrid.first == index;

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
                child: const Text('关闭'),
                onPressed: () {
                  Navigator.of(context).pop();
                  navigateToBack();
                },
              ),
            ],
          );
        },
      );
    };
  }

  void _restart() {
    _initializeGame();
  }

  void navigateToBack() {
    showPage.value = (context) {
      Navigator.of(context).pop();
    };
  }
}

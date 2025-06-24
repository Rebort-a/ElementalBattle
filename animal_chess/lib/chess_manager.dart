// chess_manager.dart

import 'dart:math';

import 'package:flutter/material.dart';

import 'models.dart';

enum AnimalType { elephant, tiger, lion, leopard, wolf, dog, cat, mouse }

const List<String> animalNames = ["象", "虎", "狮", "豹", "狼", "狗", "猫", "鼠"];

enum Player { red, blue }

const List<String> ownerNames = ["红", "蓝"];

enum GridType { land, river, road, bridge, tree }

class Animal {
  final AnimalType type;
  final Player owner;
  bool isRevealed = false;

  Animal(this.type, this.owner);

  bool canEat(Animal? other) {
    if (other == null) return true;

    if (type == other.type) return true;

    // 1.老鼠可以吃象
    if (type == AnimalType.mouse && other.type == AnimalType.elephant) {
      return true;
    } else if (type == AnimalType.elephant && other.type == AnimalType.mouse) {
      return false;
    }

    // 2.前面的动物可以吃后面的
    return type.index < other.type.index;
  }

  bool canMoveTo(GridType fromGridType, GridType targetGridType) {
    if (targetGridType == GridType.river) {
      // 1. 大象、狗、老鼠可以过河
      return type == AnimalType.elephant ||
          type == AnimalType.dog ||
          type == AnimalType.mouse;
    } else if (targetGridType == GridType.bridge) {
      // 2.只有老鼠能从河里上桥，且大象不能上桥
      return (fromGridType != GridType.river || type == AnimalType.mouse) &&
          type != AnimalType.elephant;
    } else if (targetGridType == GridType.tree) {
      //3. 豹子、猫、老鼠可以上树
      return type == AnimalType.leopard ||
          type == AnimalType.cat ||
          type == AnimalType.mouse;
    }

    return true;
  }

  String get displayName =>
      isRevealed ? "${ownerNames[owner.index]}${animalNames[type.index]}" : "";

  Color get displayColor => isRevealed
      ? owner == Player.red
          ? Colors.red
          : Colors.blue
      : Colors.grey;
}

class Point {
  int x;
  int y;

  Point(this.x, this.y);
}

class Grid {
  final Point point;
  final GridType type;
  Animal? animal;
  bool isSelected = false;
  bool isHighlighted = false;

  Grid({required this.point, required this.type});

  Grid copyWith({
    Animal? animal,
    bool? isSelected,
    bool? isHighlighted,
    bool? isEmpty,
  }) {
    return Grid(point: point, type: type)
      ..animal = animal ?? this.animal
      ..isSelected = isSelected ?? this.isSelected
      ..isHighlighted = isHighlighted ?? this.isHighlighted
      ..isEmpty = isEmpty ?? this.isEmpty;
  }

  bool get isEmpty => animal == null;
  set isEmpty(bool value) {
    if (value) {
      animal = null;
    }
  }

  bool get isHidden => animal != null && !animal!.isRevealed;
}

class ChessManager {
  static const int boardLevel = 2;
  static int boardLength = boardLevel * 2 + 1;

  final AlwaysNotifier<void Function(BuildContext)> showPage =
      AlwaysNotifier((_) {});
  final ValueNotifier<String> info = ValueNotifier("游戏开始 - 红方回合");
  final ValueNotifier<List<List<ValueNotifier<Grid>>>> displayMap =
      ValueNotifier([]);

  Player _currentPlayer = Player.red;
  Point? _selectedPos;

  ChessManager() {
    _initBoard();
    _placeAnimalsRandomly();
  }

  Player get currentPlayer => _currentPlayer;

  void _initBoard() {
    List<List<Grid>> newMap = [];

    for (int y = 0; y < boardLength; y++) {
      List<Grid> row = <Grid>[];
      for (int x = 0; x < boardLength; x++) {
        GridType type;
        if (x == boardLevel) {
          if (y == boardLevel) {
            type = GridType.bridge;
          } else if (y == 0 || y == boardLength - 1) {
            type = GridType.tree;
          } else {
            type = GridType.road;
          }
        } else if (y == boardLevel) {
          type = GridType.river;
        } else {
          type = GridType.land;
        }
        row.add(Grid(point: Point(x, y), type: type));
      }
      newMap.add(row);
    }
    displayMap.value = newMap
        .map((innerList) =>
            innerList.map((grid) => ValueNotifier(grid)).toList())
        .toList();
  }

  void _placeAnimalsRandomly() {
    final redAnimals =
        AnimalType.values.map((type) => Animal(type, Player.red)).toList();
    final blueAnimals =
        AnimalType.values.map((type) => Animal(type, Player.blue)).toList();

    final availableGrids = <Point>[];
    for (int y = 0; y < boardLength; y++) {
      for (int x = 0; x < boardLength; x++) {
        if (displayMap.value[y][x].value.type == GridType.land) {
          availableGrids.add(Point(x, y));
        }
      }
    }

    final random = Random();
    redAnimals.shuffle(random);
    blueAnimals.shuffle(random);
    availableGrids.shuffle(random);

    for (int i = 0; i < 8; i++) {
      final pos = availableGrids[i];
      final grid = displayMap.value[pos.y][pos.x].value;
      displayMap.value[pos.y][pos.x].value =
          grid.copyWith(animal: redAnimals[i], isEmpty: false);
    }

    for (int i = 8; i < 16; i++) {
      final pos = availableGrids[i];
      final grid = displayMap.value[pos.y][pos.x].value;
      displayMap.value[pos.y][pos.x].value =
          grid.copyWith(animal: blueAnimals[i - 8], isEmpty: false);
    }
  }

  void selectGrid(Point point) {
    final gridNotifier = displayMap.value[point.y][point.x];
    final grid = gridNotifier.value;

    // 尝试翻开隐藏的卡片
    if (grid.isHidden) {
      _revealCard(point);
      return;
    }

    // 取消选择当前格子
    if (_selectedPos != null && _selectedPos! == point) {
      _clearSelection();
      return;
    }

    // 移动到有效位置
    if (_isValidMove(point)) {
      _executeMove(_selectedPos!.x, _selectedPos!.y, point.x, point.y);
      return;
    }

    // 选择当前玩家的动物
    if (grid.animal != null && grid.animal!.owner == _currentPlayer) {
      _selectGrid(point);
      _calculateValidMoves();
    }
  }

  void _selectGrid(Point point) {
    // 清除之前的选择
    if (_selectedPos != null) {
      final prev = displayMap.value[_selectedPos!.y][_selectedPos!.x].value;
      displayMap.value[_selectedPos!.y][_selectedPos!.x].value =
          prev.copyWith(isSelected: false);
    }

    // 设置新选择
    final grid = displayMap.value[point.y][point.x].value;
    displayMap.value[point.y][point.x].value = grid.copyWith(isSelected: true);
    _selectedPos = point;
  }

  void _clearSelection() {
    if (_selectedPos != null) {
      final prev = displayMap.value[_selectedPos!.y][_selectedPos!.x].value;
      displayMap.value[_selectedPos!.y][_selectedPos!.x].value =
          prev.copyWith(isSelected: false);
      _selectedPos = null;
    }

    // 清除所有高亮
    for (final row in displayMap.value) {
      for (final cell in row) {
        if (cell.value.isHighlighted) {
          cell.value = cell.value.copyWith(isHighlighted: false);
        }
      }
    }
  }

  void _revealCard(Point point) {
    final gridNotifier = displayMap.value[point.y][point.x];
    final grid = gridNotifier.value;
    if (grid.animal == null || grid.animal!.isRevealed) return;

    final revealedAnimal = grid.animal!..isRevealed = true;
    gridNotifier.value = grid.copyWith(animal: revealedAnimal, isEmpty: false);

    _clearSelection();
    _checkGameOver();
    _switchPlayer();
  }

  void _executeMove(int fromX, int fromY, int toX, int toY) {
    final fromNotifier = displayMap.value[fromY][fromX];
    final toNotifier = displayMap.value[toY][toX];
    final movingAnimal = fromNotifier.value.animal!;

    // 处理战斗
    if (toNotifier.value.animal != null) {
      final targetAnimal = toNotifier.value.animal!;

      if (movingAnimal.owner == targetAnimal.owner) return;

      final attackerWins = movingAnimal.canEat(targetAnimal);
      final defenderWins = targetAnimal.canEat(movingAnimal);

      if (attackerWins && defenderWins) {
        toNotifier.value = toNotifier.value.copyWith(isEmpty: true);
      } else if (attackerWins) {
        toNotifier.value =
            toNotifier.value.copyWith(animal: movingAnimal, isEmpty: false);
      } else if (defenderWins) {
        // 攻击者被吃掉，不做操作
      } else {
        return;
      }
    } else {
      toNotifier.value =
          toNotifier.value.copyWith(animal: movingAnimal, isEmpty: false);
    }

    fromNotifier.value = fromNotifier.value.copyWith(isEmpty: true);
    _clearSelection();

    _checkGameOver();
    _switchPlayer();
  }

  void _calculateValidMoves() {
    // 清除之前的高亮
    for (final row in displayMap.value) {
      for (final cell in row) {
        if (cell.value.isHighlighted) {
          cell.value = cell.value.copyWith(isHighlighted: false);
        }
      }
    }

    if (_selectedPos == null) return;

    final fromGrid = displayMap.value[_selectedPos!.y][_selectedPos!.x].value;
    if (fromGrid.animal == null) return;

    final directions = [
      Point(0, -1), // 上
      Point(-1, 0), // 左
      Point(0, 1), // 下
      Point(1, 0) // 右
    ];

    for (final dir in directions) {
      final newX = _selectedPos!.x + dir.x;
      final newY = _selectedPos!.y + dir.y;

      if (newX >= 0 && newX < boardLength && newY >= 0 && newY < boardLength) {
        _checkMove(newX, newY);
      }
    }
  }

  void _checkMove(int x, int y) {
    final targetGrid = displayMap.value[y][x].value;
    final fromGrid = displayMap.value[_selectedPos!.y][_selectedPos!.x].value;
    final animal = fromGrid.animal!;

    if (!animal.canMoveTo(fromGrid.type, targetGrid.type)) return;
    if (targetGrid.animal != null &&
        targetGrid.animal!.owner == _currentPlayer) {
      return;
    }

    // 高亮显示有效移动
    displayMap.value[y][x].value = targetGrid.copyWith(isHighlighted: true);
  }

  bool _isValidMove(Point point) {
    if (_selectedPos == null) return false;

    final targetGrid = displayMap.value[point.y][point.x].value;
    return targetGrid.isHighlighted;
  }

  void _switchPlayer() {
    _currentPlayer = _currentPlayer == Player.red ? Player.blue : Player.red;
    info.value = "${_currentPlayer == Player.red ? "红" : "蓝"}方回合";
  }

  void _checkGameOver() {
    int redCount = 0;
    int blueCount = 0;

    for (final row in displayMap.value) {
      for (final cell in row) {
        final grid = cell.value;
        if (grid.animal != null) {
          if (grid.animal!.owner == Player.red) {
            redCount++;
          } else {
            blueCount++;
          }
        }
      }
    }

    if (redCount == 0) {
      _showResult(false);
    } else if (blueCount == 0) {
      _showResult(true);
    }
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

  void _restart() {
    _currentPlayer = Player.red;
    _selectedPos = null;
    info.value = "游戏重新开始 - 红方回合";

    // 清除所有选择和状态
    _initBoard();
    _placeAnimalsRandomly();
  }
}

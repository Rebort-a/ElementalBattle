import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/energy.dart';
import '../foundation/entity.dart';
import '../foundation/map.dart';
import '../upper/practice_page.dart';
import 'elemental.dart';
import 'common.dart';
import 'player.dart';
import '../upper/combat_page.dart';
import '../upper/package_page.dart';
import '../upper/skill_page.dart';
import '../upper/status_page.dart';
import '../upper/store_page.dart';

class HomeLogic {
  bool _routed = true; // 是可跳转到其他页面或进行弹窗

  final _random = Random(); // 初始化随机生成器

  final int _height = 2 * mapLevel + 1, _width = 2 * mapLevel + 1; // 确定地图的宽和高

  MapDataStack _mapData = MapDataStack(y: 0, x: 0, parent: null); // 初始化主城的地图数据栈

  final player =
      NormalPlayer(id: EntityID.player, y: mapLevel, x: mapLevel); // 创建并初始化玩家

  late Timer _activeTimer; // 活动定时器

  final ValueNotifier<int> floorNum = ValueNotifier(0); // 供标题监听

  final AlwaysValueNotifier<void Function(BuildContext)> showPage =
      AlwaysValueNotifier((BuildContext context) {}); // 供弹出界面区域监听

  final ValueNotifier<List<List<ValueNotifier<CellData>>>> displayMap =
      ValueNotifier([]); // 供地图区域监听

  HomeLogic() {
    _generateMap(); // 生成地图
    _startActive(); // 添加键盘响应，启动定时器
    _fillHandler(); // 填充玩家的道具作用
  }

  void _generateMap() {
    if (_mapData.parent == null) {
      _generateMainMap();
    } else {
      _generateRelicMap();
    }
  }

  void _generateMainMap() {
    // 全部生成道路
    displayMap.value = List.generate(
      _height,
      (y) => List.generate(
        _width,
        (x) => ValueNotifier(CellData(
          id: EntityID.road,
          iconIndex: 0,
          colorIndex: 0,
          fogFlag: false,
        )),
      ),
    );

    // 添加玩家、NPC和入口
    _setCellToEntity(0, 0, EntityID.enter);
    _setCellToPlayer(0, mapLevel, EntityID.train);
    _setCellToEntity(0, _width - 1, EntityID.enter);

    _setCellToEntity(mapLevel, 0, EntityID.store);
    _setCellToPlayer(mapLevel, mapLevel, player.id);
    _setCellToEntity(mapLevel, _width - 1, EntityID.gym);

    _setCellToEntity(_height - 1, 0, EntityID.enter);
    _setCellToEntity(_height - 1, mapLevel, EntityID.home);
    _setCellToEntity(_height - 1, _width - 1, EntityID.enter);
  }

  void _generateRelicMap() {
    // 全部生成墙壁
    displayMap.value = List.generate(
      _height,
      (y) => List.generate(
        _width,
        (x) => ValueNotifier(CellData(
          id: EntityID.wall,
          iconIndex: 0,
          colorIndex: 0,
          fogFlag: true,
        )),
      ),
    );

    // 使用深度优先搜索生成迷宫
    _generateMaze(mapLevel, mapLevel);
    _setCellToPlayer(mapLevel, mapLevel, EntityID.exit);
  }

  void _generateMaze(int startY, int startX) {
    // 当前位置设置为道路
    _setCellToEntity(startY, startX, EntityID.road);

    List<List<int>> directions = [
      [0, -1], // 向左
      [-1, 0], // 向上
      [1, 0], // 向下
      [0, 1], // 向右
    ];

    // 随机打乱方向
    directions.shuffle();

    int branchCount = 0;

    for (List<int> direction in directions) {
      int newY = startY + direction[0] * 2;
      int newX = startX + direction[1] * 2;

      if (_checkInMap(newY, newX)) {
        if (displayMap.value[newY][newX].value.id == EntityID.wall) {
          _setCellToEntity(startY + direction[0], startX + direction[1],
              EntityID.road); // 打通中间的墙
          _generateMaze(newY, newX);
          branchCount++; // 增加分支
        }
      }
    }
    if (branchCount == 0) {
      // 如果所在地，没有任何可探索的分支，代表其是道路尽头
      // 生成随机物品或入口
      _setCellToEntity(startY, startX, _getRadomItem());
    } else if (branchCount == 1) {
      // 不生成
    } else if (branchCount == 2) {
      // 生成随机敌人
      _setCellToEntity(startY, startX, _getRandomEnemy(startY, startX));
    } else if (branchCount == 4) {
      // 不生成
    }
  }

  EntityID _getRadomItem() {
    int randVal = _random.nextInt(100);
    if (randVal < 15) {
      return EntityID.purse;
    } else if (randVal < 30) {
      return EntityID.hospital;
    } else if (randVal < 45) {
      return EntityID.sword;
    } else if (randVal < 60) {
      return EntityID.shield;
    } else {
      return EntityID.enter;
    }
  }

  EntityID _getRandomEnemy(int y, int x) {
    // 随机敌人类型
    EntityID entityID;
    int randVal = _random.nextInt(100);
    if (randVal < 72) {
      entityID = EntityID.weak;
    } else if (randVal < 88) {
      entityID = EntityID.opponent;
    } else if (randVal < 96) {
      entityID = EntityID.strong;
    } else {
      entityID = EntityID.boss;
    }

    // 根据层数和敌人类型确定等级
    // 添加到地图数据的实体列表中
    _mapData.entities.add(RandomEnemy.generate(
      id: entityID,
      y: y,
      x: x,
      grade: floorNum.value,
    ));

    return entityID;
  }

  void _startKeyboard() {
    // 添加键盘事件处理器
    HardwareKeyboard.instance.addHandler(_handleHardwareKeyboardEvent);
  }

  void _stopKeyboard() {
    // 移除键盘事件处理器
    HardwareKeyboard.instance.removeHandler(_handleHardwareKeyboardEvent);
  }

  bool _handleHardwareKeyboardEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          movePlayerUp();
          break;
        case LogicalKeyboardKey.arrowDown:
          movePlayerDown();
          break;
        case LogicalKeyboardKey.arrowLeft:
          movePlayerLeft();
          break;
        case LogicalKeyboardKey.arrowRight:
          movePlayerRight();
          break;
        default:
          return false;
      }
      return true;
    }
    return false;
  }

  void _startTimer() {
    // 启动定时器

    _activeTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _moveEntities();
    });
  }

  void _stopTimer() {
    if (_activeTimer.isActive) {
      _activeTimer.cancel();
    }
  }

  void _startActive() {
    _routed = true;
    _startKeyboard();
    _startTimer();
  }

  bool _stopActive() {
    if (!_routed) {
      return false;
    } else {
      _routed = false;
      _stopKeyboard();
      _stopTimer();
      return true;
    }
  }

  void _fillHandler() {
    player.props[EntityID.scroll]?.handler = (context, elemental, after) {
      after();
      _backToMain();
      Navigator.of(context).pop();
    };
  }

  void switchPlayerNext() {
    player.switchNext();
  }

  void movePlayerUp() {
    _movePlayer(Direction.up);
  }

  void movePlayerDown() {
    _movePlayer(Direction.down);
  }

  void movePlayerLeft() {
    _movePlayer(Direction.left);
  }

  void movePlayerRight() {
    _movePlayer(Direction.right);
  }

  void navigateToPackagePage(BuildContext context) {
    _navigateAndSetActive(context, PackagePage(player: player));
  }

  void navigateToStorePage(BuildContext context) {
    _navigateAndSetActive(context, StorePage(player: player));
  }

  void navigateToSkillsPage(BuildContext context) {
    _navigateAndSetActive(context, SkillsPage(player: player));
  }

  void navigateToStatusPage(BuildContext context) {
    _navigateAndSetActive(context, StatusPage(player: player));
  }

  void navigateToPracticePage(BuildContext context) {
    _navigateAndSetActive(context, PracticePage(player: player));
  }

  void _navigateAndSetActive(BuildContext context, Widget page) {
    if (_stopActive()) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => page))
          .then((_) {
        // 当页面弹出（即返回）时，这个回调会被执行
        _startActive(); // 重新启动定时器
      });
    }
  }

  void navigateToCombatPage(
      BuildContext context, RandomEnemy enemy, bool offensive) {
    if (_stopActive()) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CombatPage(
                  player: player,
                  enemy: enemy,
                  offensive: offensive,
                )),
      ).then((value) {
        // 当页面弹出（即返回）时，这个回调会被执行
        _startActive(); // 重新启动定时器
        if (value is ResultType) {
          if (value == ResultType.victory) {
            player.experience += 10 + 2 * enemy.grade;
            _mapData.entities.remove(enemy);
            _setCellToEntity(enemy.y, enemy.x, EntityID.road); // 从地图上清除敌人
            _restorePlayer(); // 恢复玩家状态
          } else if (value == ResultType.defeat) {
            player.experience -= 5;
            _backToMain();
          } else if (value == ResultType.escape) {
            player.experience -= 2;
          }
        }
      });
    }
  }

  void _backToMain() {
    while (_mapData.parent != null) {
      _backToPrevious();
    }
    _updatePlayerCell(Direction.down); // 更新方向
    _setCellToPlayer(mapLevel, mapLevel, player.id);
    showPage.value = (BuildContext context) {
      SnackBarMessage(context, '你回到了主城');
    };
  }

  void _moveEntities() {
    for (MovableEntity entity in _mapData.entities) {
      if (entity is RandomEnemy) {
        List<List<int>> directions = [
          [0, -1], // 向左
          [-1, 0], // 向上
          [1, 0], // 向下
          [0, 1], // 向右
        ];

        // 随机打乱方向
        directions.shuffle();

        int newY = entity.y + directions[0][0];
        int newX = entity.x + directions[0][1];

        if (_checkInMap(newY, newX)) {
          CellData cell = displayMap.value[newY][newX].value;
          switch (cell.id) {
            case EntityID.road:
              _setCellToEntity(newY, newX, entity.id); // 设置新位置
              _setCellToEntity(entity.y, entity.x, EntityID.road); // 清除旧位置
              entity.updatePosition(newY, newX); // 更新位置
              break;
            case EntityID.player:
              showPage.value = (BuildContext context) {
                navigateToCombatPage(context, entity, false);
              };
              break;
            default:
              break;
          }
        }
      }
    }
  }

  void _movePlayer(Direction direction) {
    _updatePlayerCell(direction);

    int newY = player.y;
    int newX = player.x;

    switch (direction) {
      case Direction.up:
        newY -= 1;
        break;
      case Direction.down:
        newY += 1;
        break;
      case Direction.left:
        newX -= 1;
        break;
      case Direction.right:
        newX += 1;
        break;
    }

    if (_checkInMap(newY, newX)) {
      CellData cell = displayMap.value[newY][newX].value;
      switch (cell.id) {
        case EntityID.road:
          _setCellToPlayer(newY, newX, player.id);
          break;
        case EntityID.wall:
          break;
        case EntityID.enter:
          _enterNext(newY, newX);
          break;
        case EntityID.exit:
          _backToPrevious();
          break;
        case EntityID.train:
          showPage.value = navigateToPracticePage;
          break;
        case EntityID.gym:
          showPage.value = (BuildContext context) {
            UpgradeDialog(context, _stopActive, _startActive, _upgradePlayer);
          };
          break;
        case EntityID.store:
          showPage.value = navigateToStorePage;
          break;
        case EntityID.home:
          _restorePlayer();
          showPage.value = (BuildContext context) {
            DialogMessage(context, "提示", "你睡了一觉，恢复了状态", _stopActive, () => {},
                _startActive);
          };
          break;
        case EntityID.hospital:
          player.props[EntityID.hospital]?.count += 1;
          showPage.value = (BuildContext context) {
            SnackBarMessage(context, '你得到了一个药');
          };
          _setCellToEntity(newY, newX, EntityID.road);
          break;
        case EntityID.sword:
          player.props[EntityID.sword]?.count += 1;
          showPage.value = (BuildContext context) {
            SnackBarMessage(context, '你得到了一个武器');
          };
          _setCellToEntity(newY, newX, EntityID.road);
          break;
        case EntityID.shield:
          player.props[EntityID.shield]?.count += 1;
          showPage.value = (BuildContext context) {
            SnackBarMessage(context, '你得到了一个防具');
          };
          _setCellToEntity(newY, newX, EntityID.road);
          break;
        case EntityID.purse:
          int money = 5 + _random.nextInt(25);
          player.money += money;
          showPage.value = (BuildContext context) {
            SnackBarMessage(context, '你得到了一个钱袋，获得了$money枚金币');
          };
          _setCellToEntity(newY, newX, EntityID.road);
          break;
        case EntityID.weak:
        case EntityID.opponent:
        case EntityID.strong:
        case EntityID.boss:
          for (MovableEntity entity in _mapData.entities) {
            if ((entity.y == newY) && (entity.x == newX)) {
              if (entity is RandomEnemy) {
                showPage.value = (BuildContext context) {
                  navigateToCombatPage(context, entity, true);
                };
              }
            }
          }
          break;
        default:
          break;
      }
    }
  }

  void _backToPrevious() {
    final parent = _mapData.parent;
    if (parent != null) {
      floorNum.value--;

      _clearPlayerCurrentCell();

      _mapData.leaveMap = displayMap.value
          .map(
              (row) => row.map((valueNotifier) => valueNotifier.value).toList())
          .toList(); // 获取当前地图数据

      int playerY = _mapData.y;
      int playerX = _mapData.x;

      _mapData = parent; // 回退到上一层

      displayMap.value = _mapData.leaveMap
          .map((row) => row.map((value) => ValueNotifier(value)).toList())
          .toList(); // 从当前地图数据中恢复

      _setCellToPlayer(playerY, playerX, EntityID.enter); // 更新位置
    }
  }

  void _enterNext(int newY, int newX) {
    if (player.preview.health.value <= 0) {
      showPage.value = (BuildContext context) {
        SnackBarMessage(context, '无法继续冒险');
      };
      return;
    }

    floorNum.value++;

    _clearPlayerCurrentCell();

    _mapData.leaveMap = displayMap.value
        .map((row) => row.map((valueNotifier) => valueNotifier.value).toList())
        .toList(); // 获取当前地图数据
    for (MapDataStack child in _mapData.children) {
      if (child.y == newY && child.x == newX) {
        _mapData = child;
        displayMap.value = _mapData.leaveMap
            .map((row) => row.map((value) => ValueNotifier(value)).toList())
            .toList(); // 从当前地图数据中恢复
        _setCellToPlayer(mapLevel, mapLevel, EntityID.exit);
        return;
      }
    }
    MapDataStack newMap = MapDataStack(y: newY, x: newX, parent: _mapData);
    _mapData.children.add(newMap);
    _mapData = newMap;
    _generateMap();
  }

  void _updatePlayerCell(Direction direction) {
    player.updateDirection(direction); // 更新方向
    displayMap.value[player.y][player.x].value = CellData(
      id: displayMap.value[player.y][player.x].value.id,
      iconIndex: player.col + player.row,
      colorIndex: 1,
      fogFlag: false,
    ); // 设置新位置
  }

  void _restorePlayer() {
    player.restoreEnergies();
  }

  void _upgradePlayer(int index, AttributeType attribute) {
    if (player.experience >= 30) {
      player.experience -= 30;
      player.upgradeEnergy(index, attribute);
      showPage.value = (BuildContext context) {
        SnackBarMessage(context, '升级成功！');
      };
    } else {
      showPage.value = (BuildContext context) {
        SnackBarMessage(context, '经验不足！');
      };
    }
  }

  void _setCellToEntity(int y, int x, EntityID id) {
    displayMap.value[y][x].value = displayMap.value[y][x].value
        .copyWith(id: id, iconIndex: 0, colorIndex: 0);
  }

  void _setCellToPlayer(int newY, int newX, EntityID id) {
    _clearPlayerCurrentCell();
    player.updatePosition(newY, newX); // 更新位置
    // player.updateDirection(player.lastDirection); // 更新方向
    displayMap.value[newY][newX].value = CellData(
      id: id,
      iconIndex: player.col + player.row,
      colorIndex: 1,
    ); // 设置新位置
    _setAroundVisibility(player.y, player.x);
  }

  void _clearPlayerCurrentCell() {
    CellData cell = displayMap.value[player.y][player.x].value;
    if (cell.id == player.id) {
      _setCellToEntity(player.y, player.x, EntityID.road); // 设置为道路
    } else {
      _setCellToEntity(player.y, player.x, cell.id); // 设置为原样
    }
  }

  void _setAroundVisibility(int y, int x) {
    List<List<int>> around = [
      [0, 0], //所在地
      [-1, 0], // 上
      [1, 0], // 下
      [0, -1], // 左
      [0, 1], // 右
    ];
    for (int i = 0; i < around.length; i++) {
      int newY = y + around[i][0];
      int newX = x + around[i][1];
      if (_checkInMap(newY, newX)) {
        displayMap.value[newY][newX].value =
            displayMap.value[newY][newX].value.copyWith(fogFlag: false);
      }
    }
  }

  bool _checkInMap(y, x) {
    return y >= 0 &&
        y < displayMap.value.length &&
        x >= 0 &&
        x < displayMap.value[y].length;
  }
}

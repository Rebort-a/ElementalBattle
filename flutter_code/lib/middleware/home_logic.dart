import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';

import '../foundation/energy.dart';
import '../foundation/entity.dart';
import '../foundation/map.dart';
import 'elemental.dart';
import 'common.dart';
import 'player.dart';
import '../upper/combat_page.dart';
import '../upper/package_page.dart';
import '../upper/skill_page.dart';
import '../upper/status_page.dart';
import '../upper/store_page.dart';

class HomeLogic {
  final _random = Random(); // 初始化随机生成器

  final int _height = 2 * mapLevel + 1, _width = 2 * mapLevel + 1; // 确定地图的宽和高

  MapDataStack _mapData = MapDataStack(y: 0, x: 0, parent: null); // 初始化主城的地图数据栈

  final player = PlayerElemental(
      id: EntityID.player, y: mapLevel, x: mapLevel); // 创建并初始化玩家

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
          index: 0,
          proportion: 1,
          fog: false,
        )),
      ),
    );

    // 添加玩家、NPC和入口
    _setCellToPlayer(mapLevel, mapLevel, player.id);
    _setCellToEntity(mapLevel, _width - 1, EntityID.experience);
    _setCellToEntity(mapLevel, 0, EntityID.businessman);
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
          index: 0,
          proportion: 1,
          fog: true,
        )),
      ),
    );

    // 使用深度优先搜索生成迷宫
    _generateMaze(mapLevel, mapLevel);
    _setCellToPlayer(0, 0, EntityID.exit);
    _setCellToEntity(mapLevel, mapLevel, EntityID.enter);
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
    if (randVal < 20) {
      return EntityID.enter;
    } else if (randVal < 40) {
      return EntityID.hospital;
    } else if (randVal < 60) {
      return EntityID.sword;
    } else if (randVal < 80) {
      return EntityID.shield;
    } else {
      return EntityID.purse;
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

    // 随机敌人元素数量
    int elementCount = _random.nextInt(EnergyType.values.length) + 1;

    // 根据层数和敌人类型确定等级
    // 添加到地图数据的实体列表中
    _mapData.entities.add(EnemyElemental(
        name: enemyNames[entityID.index - EntityID.weak.index],
        count: elementCount,
        level: floorNum.value + entityID.index - EntityID.weak.index,
        id: entityID,
        y: y,
        x: x));

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
    _startKeyboard();
    _startTimer();
  }

  void _stopActive() {
    _stopKeyboard();
    _stopTimer();
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
    _updatePlayerCell();
  }

  void movePlayerUp() {
    _movePlayer(player.y - 1, player.x + 0);
  }

  void movePlayerDown() {
    _movePlayer(player.y + 1, player.x + 0);
  }

  void movePlayerLeft() {
    _movePlayer(player.y + 0, player.x - 1);
  }

  void movePlayerRight() {
    _movePlayer(player.y + 0, player.x + 1);
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

  void _navigateAndSetActive(BuildContext context, Widget page) {
    _stopActive(); // 暂停定时器
    Navigator.push(context, MaterialPageRoute(builder: (context) => page))
        .then((_) {
      // 当页面弹出（即返回）时，这个回调会被执行
      _startActive(); // 重新启动定时器
    });
  }

  void navigateToCombatPage(
      BuildContext context, EnemyElemental enemy, bool offensive) {
    _stopActive(); // 暂停定时器
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CombatPage(
                player: player,
                enemy: enemy,
                offensive: offensive,
              )),
    ).then((value) {
      _updatePlayerCell();
      _startActive(); // 重新启动定时器
      if (value is ResultType) {
        if (value == ResultType.victory) {
          _mapData.entities.remove(enemy);
          _setCellToEntity(enemy.y, enemy.x, EntityID.road); // 从地图上清除敌人
        } else if (value == ResultType.defeat) {
          _backToMain();
        }
      }
    });
  }

  void _backToMain() {
    while (_mapData.parent != null) {
      _backToPrevious();
    }
    _setCellToPlayer(mapLevel, mapLevel, player.id);
    showPage.value = (BuildContext context) {
      SnackBarMessage(context, '你回到了主城');
    };
  }

  void _moveEntities() {
    for (var entity in _mapData.entities) {
      if (entity is EnemyElemental) {
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

  void _movePlayer(int newY, int newX) {
    if (_checkInMap(newY, newX)) {
      CellData cell = displayMap.value[newY][newX].value;
      switch (cell.id) {
        case EntityID.road:
          _setCellToPlayer(newY, newX, player.id);
          break;
        case EntityID.enter:
          _enterNext(newY, newX);
          break;
        case EntityID.exit:
          _setCellToPlayer(newY, newX, EntityID.exit);
          break;
        case EntityID.experience:
          showPage.value = (BuildContext context) {
            UpgradeDialog(context, _stopActive, _startActive, _upgradePlayer);
          };
          break;
        case EntityID.businessman:
          showPage.value = navigateToStorePage;
          break;
        case EntityID.home:
          _restorePlayer();
          showPage.value = (BuildContext context) {
            DialogMessage(
                context, "提示", "你睡了一觉，恢复了状态", _stopActive, _startActive);
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
          for (var entity in _mapData.entities) {
            if ((entity.y == newY) && (entity.x == newX)) {
              if (entity is EnemyElemental) {
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
    } else {
      if (displayMap.value[player.y][player.x].value.id == EntityID.exit) {
        if (_mapData.parent != null) {
          _backToPrevious();
        }
      }
    }
  }

  void _backToPrevious() {
    floorNum.value--;

    _clearPlayerCurrentCell();

    _mapData.leaveMap = displayMap.value
        .map((row) => row.map((valueNotifier) => valueNotifier.value).toList())
        .toList(); // 获取当前地图数据

    if (_mapData.parent != null) {
      _mapData = _mapData.parent!; // 更新当前地图
    }

    displayMap.value = _mapData.leaveMap
        .map((row) => row.map((value) => ValueNotifier(value)).toList())
        .toList(); // 从当前地图数据中恢复

    _setCellToPlayer(_mapData.leaveY, _mapData.leaveX, player.id); // 更新位置
  }

  void _enterNext(int newY, int newX) {
    if (player.energies[player.current].health <= 0) {
      showPage.value = (BuildContext context) {
        SnackBarMessage(context, '无法继续冒险');
      };
      return;
    }

    floorNum.value++;
    _mapData.leaveY = player.y; // 保存玩家坐标
    _mapData.leaveX = player.x;
    _mapData.leaveMap = displayMap.value
        .map((row) => row.map((valueNotifier) => valueNotifier.value).toList())
        .toList(); // 获取当前地图数据
    for (var child in _mapData.children) {
      if (child.y == newY && child.x == newX) {
        _mapData = child;
        displayMap.value = _mapData.leaveMap
            .map((row) => row.map((value) => ValueNotifier(value)).toList())
            .toList(); // 从当前地图数据中恢复
        _setCellToPlayer(0, 0, EntityID.exit);
        return;
      }
    }
    MapDataStack newMap = MapDataStack(y: newY, x: newX, parent: _mapData);
    _mapData.children.add(newMap);
    _mapData = newMap;
    _generateMap();
  }

  void _updatePlayerCell() {
    _setCellToPlayer(player.y, player.x,
        displayMap.value[player.y][player.x].value.id); //更新地图上玩家所在位置
  }

  void _restorePlayer() {
    player.restoreEnergies();
    _updatePlayerCell();
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
    displayMap.value[y][x].value =
        displayMap.value[y][x].value.copyWith(id: id, index: 0, proportion: 1);
  }

  void _setCellToPlayer(int newY, int newX, EntityID id) {
    _clearPlayerCurrentCell();
    displayMap.value[newY][newX].value = CellData(
        id: id,
        index: player.current + 1,
        proportion: (player.preview.survival / player.count) *
            (player.energies[player.current].health /
                (player.energies[player.current].capacityBase))); // 设置新位置
    player.updatePosition(newY, newX); // 更新位置
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
            displayMap.value[newY][newX].value.copyWith(fog: false);
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

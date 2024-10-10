import 'package:flutter/material.dart';

import '../foundation/energy.dart';
import '../foundation/entity.dart';
import '../middleware/common.dart';
import '../middleware/map.dart';
import '../middleware/elemental.dart';
import 'home_logic.dart';

class HomePage extends StatelessWidget {
  final HomeLogic homeLogic = HomeLogic();

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 弹出页面
          _buildDialog(),
          // 地图区域
          _buildMapRegion(),
          // 信息区域
          _buildInfoRegion(),
          // 按键区域
          _buildButtonRegion(),
          // 方向键区域
          _buildirectionRegion(),

          _buildBlankRegion(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return ValueListenableBuilder(
      valueListenable: homeLogic.floorNum,
      builder: (context, value, child) {
        return value > 0 ? Text('地下$value层') : const Text('主城');
      },
    );
  }

  Widget _buildDialog() {
    return ValueListenableBuilder<void Function(BuildContext)>(
      valueListenable: homeLogic.showPage,
      builder: (context, value, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          value(context);
        });
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMapRegion() {
    return Expanded(
      child: ValueListenableBuilder(
        valueListenable: homeLogic.displayMap,
        builder: (context, value, child) {
          return HomeMapRegion(map: value);
        },
      ),
    );
  }

  Widget _buildInfoRegion() {
    return HomeInfoRegion(info: homeLogic.player.preview);
  }

  Widget _buildButtonRegion() {
    return HomeButtonRegion(homeLogic: homeLogic);
  }

  Widget _buildirectionRegion() {
    return HomeDirectionRegion(homeLogic: homeLogic);
  }

  Widget _buildBlankRegion() {
    return const SizedBox(height: 64);
  }
}

class HomeInfoRegion extends StatelessWidget {
  final ElementalPreview info;

  const HomeInfoRegion({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    // 显示四个图标和四个数值
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfo("🌈", info.element),
          _buildInfo(attributeNames[AttributeType.hp.index], info.health),
          _buildInfo(attributeNames[AttributeType.atk.index], info.attack),
          _buildInfo(attributeNames[AttributeType.def.index], info.defence),
        ],
      ),
    );
  }

  Widget _buildInfo(String label, ValueNotifier notifier) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (context, value, child) {
        return Text("$label: $value");
      },
    );
  }
}

class HomeButtonRegion extends StatelessWidget {
  final HomeLogic homeLogic;

  const HomeButtonRegion({super.key, required this.homeLogic});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () => homeLogic.navigateToPackagePage(context),
          child: const Text("背包"),
        ),
        ElevatedButton(
          onPressed: () => homeLogic.navigateToSkillsPage(context),
          child: const Text("技能"),
        ),
        ElevatedButton(
          onPressed: () => homeLogic.navigateToStatusPage(context),
          child: const Text("状态"),
        ),
        ElevatedButton(
          onPressed: homeLogic.switchPlayerNext,
          child: const Text("切换"),
        ),
      ],
    );
  }
}

class HomeDirectionRegion extends StatelessWidget {
  final HomeLogic homeLogic;

  const HomeDirectionRegion({super.key, required this.homeLogic});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        CustomDirectionButton(
          size: const Size(48, 48),
          onTap: homeLogic.movePlayerUp,
        ),
        const SizedBox(height: 16), // 在上键和左键之间添加空间
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomDirectionButton(
              size: const Size(48, 48),
              onTap: homeLogic.movePlayerLeft,
            ),
            const SizedBox(width: 64), // 在左键和右键之间添加空间
            CustomDirectionButton(
              size: const Size(48, 48),
              onTap: homeLogic.movePlayerRight,
            ),
          ],
        ),
        const SizedBox(height: 16), // 在左键和下键之间添加空间
        CustomDirectionButton(
          size: const Size(48, 48),
          onTap: homeLogic.movePlayerDown,
        ),
      ],
    );
  }
}

class HomeMapRegion extends StatelessWidget {
  final List<List<ValueNotifier<CellData>>> map;

  const HomeMapRegion({super.key, required this.map});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0, // 强制宽高比为1:1，即正方形
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 10),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: map.length,
          ),
          itemCount: map.length * map[0].length,
          itemBuilder: (context, index) {
            final x = index % map.length;
            final y = index ~/ map.length;
            return ValueListenableBuilder(
              valueListenable: map[y][x],
              builder: (context, value, child) {
                return _getImage(value);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _getImage(CellData data) {
    if (data.fog) {
      return Container(color: Colors.black);
    } else {
      return Container(
        color: _getColor(data.id, data.index),
        child: Center(
          child: _getIcon(data.id, data.proportion),
        ),
      );
    }
  }

  Color _getColor(EntityID id, int index) {
    switch (id) {
      case EntityID.road:
        return Colors.blueGrey; // 道路
      case EntityID.wall:
        return Colors.brown; // 墙壁
      case EntityID.player:
      case EntityID.enter:
      case EntityID.exit:
        switch (index) {
          case 1:
            return const Color(0xFFC0C0C0);
          case 2:
            return Colors.blue;
          case 3:
            return Colors.lightGreen;
          case 4:
            return Colors.deepOrange;
          case 5:
            return Colors.brown;
          default:
            return Colors.blueGrey;
        }
      case EntityID.experience:
      case EntityID.businessman:
      case EntityID.home:
        return Colors.teal;
      case EntityID.weak:
        return const Color.fromARGB(255, 255, 128, 128);
      case EntityID.opponent:
        return const Color.fromARGB(255, 255, 64, 64);
      case EntityID.strong:
        return const Color.fromARGB(255, 255, 32, 32);
      case EntityID.boss:
        return const Color.fromARGB(255, 255, 0, 0);
      default:
        return Colors.blueGrey;
    }
  }

  Widget _getIcon(EntityID id, double proportion) {
    switch (id) {
      case EntityID.road:
        return Container(); // 道路
      case EntityID.wall:
        return const Text('🧱'); // 墙壁
      case EntityID.player:
        if (proportion < 0.25) {
          return const Text('😢');
        } else if (proportion < 0.5) {
          return const Text('😮');
        } else if (proportion < 0.75) {
          return const Text('😊');
        } else {
          return const Text('😎');
        }
      case EntityID.enter:
        return const Icon(Icons.exit_to_app); // 入口
      case EntityID.exit:
        return const Icon(Icons.door_sliding); // 出口
      case EntityID.experience:
        return const Text('🏟️'); // 训练场
      case EntityID.businessman:
        return const Text('🏦'); // 商店
      case EntityID.home:
        return const Text('🏠'); //家
      case EntityID.hospital:
        return const Text('💊');
      case EntityID.sword:
        return const Text('🗡️');
      case EntityID.shield:
        return const Text('🛡️');
      case EntityID.purse:
        return const Text('💰'); //钱袋
      case EntityID.weak:
        return const Text('👻'); // 弱鸡
      case EntityID.opponent:
        return const Text('🤡'); // 对手
      case EntityID.strong:
        return const Text('👿'); // 强敌
      case EntityID.boss:
        return const Text('💀'); // 魔王
      default:
        return const Text('❓'); // 未知
    }
  }
}

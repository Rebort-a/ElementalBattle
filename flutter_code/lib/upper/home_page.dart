import 'package:flutter/material.dart';

import '../foundation/energy.dart';
import '../foundation/image.dart';
import '../middleware/common.dart';
import '../foundation/map.dart';
import '../middleware/elemental.dart';
import '../middleware/home_logic.dart';

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
          // 底部空白区域
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
    return Flexible(
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
        children: [
          const Spacer(flex: 2),
          _buildInfo("🌈", info.typeString),
          _buildInfo(attributeNames[AttributeType.hp.index], info.health),
          _buildInfo(attributeNames[AttributeType.atk.index], info.attack),
          _buildInfo(attributeNames[AttributeType.def.index], info.defence),
        ],
      ),
    );
  }

  Widget _buildInfo(String label, ValueNotifier notifier) {
    return Expanded(
      flex: 5,
      child: ValueListenableBuilder(
        valueListenable: notifier,
        builder: (context, value, child) {
          return Text("$label: $value");
        },
      ),
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
        ScaleButton(
          size: const Size(48, 48),
          onTap: homeLogic.movePlayerUp,
        ),
        const SizedBox(height: 16), // 在上键和左键之间添加空间
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleButton(
              size: const Size(48, 48),
              onTap: homeLogic.movePlayerLeft,
            ),
            const SizedBox(width: 64), // 在左键和右键之间添加空间
            ScaleButton(
              size: const Size(48, 48),
              onTap: homeLogic.movePlayerRight,
            ),
          ],
        ),
        const SizedBox(height: 16), // 在左键和下键之间添加空间
        ScaleButton(
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
      aspectRatio: 1, // 宽高比为1:1，即正方形
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 8),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Container(
              color: Colors.grey,
              child: Center(
                child: SizedBox(
                  height: ((constraints.maxHeight ~/ map.length) * map.length)
                      .toDouble(),
                  width:
                      ((constraints.maxWidth ~/ map[0].length) * map[0].length)
                          .toDouble(),
                  child: GridView.builder(
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
                          return ImageManager.getPresetsImage(value.id,
                              value.index, value.proportion, value.fog);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../foundation/energy.dart';
import '../foundation/image.dart';
import '../middleware/common.dart';
import '../foundation/map.dart';
import '../middleware/home_logic.dart';

class HomePage extends StatelessWidget {
  final HomeLogic homeLogic = HomeLogic();

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return orientation == Orientation.portrait
              ? _buildPortraitLayout(context)
              : _buildLandscapeLayout(context);
        },
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
        title: ValueListenableBuilder<int>(
          valueListenable: homeLogic.floorNum,
          builder: (context, value, _) => Text(value > 0 ? '地下$value层' : '主城'),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      );

  // 竖屏布局
  Widget _buildPortraitLayout(BuildContext context) => Column(
        children: [
          // 弹出页面
          _buildDialog(),

          Flexible(
            child: Column(
              children: [
                Expanded(flex: 5, child: _buildMapRegion()),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildPortraitInfoRegion(),
                      _buildPortraitButtonRegion(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildDirectionRegion(),
          // 底部空白区域
          _buildBlankRegion(),
        ],
      );

  // 横屏布局
  Widget _buildLandscapeLayout(BuildContext context) => Column(
        children: [
          // 弹出页面
          _buildDialog(),

          Flexible(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      _buildLandscapeButtonRegion(context),
                      _buildLandscapeInfoRegion(),
                    ],
                  ),
                ),
                Expanded(flex: 5, child: _buildMapRegion()),
                Expanded(flex: 3, child: _buildDirectionRegion()),
              ],
            ),
          ),

          // 底部空白区域
          _buildBlankRegion(),
        ],
      );

  Widget _buildDialog() => ValueListenableBuilder<void Function(BuildContext)>(
        valueListenable: homeLogic.showPage,
        builder: (context, value, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            value(context);
            homeLogic.showPage.value = (BuildContext context) {};
          });

          return const SizedBox.shrink();
        },
      );

  Widget _buildBlankRegion() {
    return const SizedBox(height: 64);
  }

  Widget _buildMapRegion() => AspectRatio(
        aspectRatio: 1, // 宽高比为1:1，即正方形
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 8),
          ),
          child: ValueListenableBuilder<List<List<ValueNotifier<CellData>>>>(
            valueListenable: homeLogic.displayMap,
            builder: (context, map, _) => LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final cellWidth = constraints.maxHeight ~/ map.length;
                final cellHeight = constraints.maxWidth ~/ map[0].length;
                final cellSize =
                    cellWidth < cellHeight ? cellWidth : cellHeight;

                // 计算地图的实际尺寸
                final mapWidth = cellSize * map[0].length;
                final mapHeight = cellSize * map.length;

                return Container(
                  color: Colors.grey,
                  child: Center(
                    child: SizedBox(
                      height: mapWidth.toDouble(),
                      width: mapHeight.toDouble(),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(), // 禁止滚动
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: map.length,
                          childAspectRatio: 1, // 保持单元格正方形
                        ),
                        itemCount: map.length * map[0].length,
                        itemBuilder: (context, index) {
                          final x = index % map.length;
                          final y = index ~/ map.length;
                          return ValueListenableBuilder(
                            valueListenable: map[y][x],
                            builder: (context, value, child) {
                              return ImageManager().getImage(
                                  value.id,
                                  value.iconIndex,
                                  value.colorIndex,
                                  value.fogFlag);
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
        ),
      );

  Widget _buildPortraitInfoRegion() => Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _InfoItem(label: "🌈", value: homeLogic.player.preview.typeString),
            _InfoItem(
              label: attributeNames[AttributeType.hp.index],
              value: homeLogic.player.preview.health,
            ),
            _InfoItem(
              label: attributeNames[AttributeType.atk.index],
              value: homeLogic.player.preview.attack,
            ),
            _InfoItem(
              label: attributeNames[AttributeType.def.index],
              value: homeLogic.player.preview.defence,
            ),
          ],
        ),
      );

  Widget _buildLandscapeInfoRegion() => Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            const Spacer(flex: 1),
            _InfoItem(label: "🌈", value: homeLogic.player.preview.typeString),
            _InfoItem(
              label: attributeNames[AttributeType.hp.index],
              value: homeLogic.player.preview.health,
            ),
            _InfoItem(
              label: attributeNames[AttributeType.atk.index],
              value: homeLogic.player.preview.attack,
            ),
            _InfoItem(
              label: attributeNames[AttributeType.def.index],
              value: homeLogic.player.preview.defence,
            ),
          ],
        ),
      );

  Widget _buildPortraitButtonRegion(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _AppButton(
            text: "背包",
            onPressed: () => homeLogic.navigateToPackagePage(context),
          ),
          _AppButton(
            text: "技能",
            onPressed: () => homeLogic.navigateToSkillsPage(context),
          ),
          _AppButton(
            text: "状态",
            onPressed: () => homeLogic.navigateToStatusPage(context),
          ),
          _AppButton(
            text: "切换",
            onPressed: homeLogic.switchPlayerNext,
          ),
        ],
      );

  Widget _buildLandscapeButtonRegion(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _AppButton(
            text: "背包",
            onPressed: () => homeLogic.navigateToPackagePage(context),
          ),
          _AppButton(
            text: "技能",
            onPressed: () => homeLogic.navigateToSkillsPage(context),
          ),
          _AppButton(
            text: "状态",
            onPressed: () => homeLogic.navigateToStatusPage(context),
          ),
          _AppButton(
            text: "切换",
            onPressed: homeLogic.switchPlayerNext,
          ),
        ],
      );

  Widget _buildDirectionRegion() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          _DirectionButton(
            onTap: homeLogic.movePlayerUp,
            icon: Icons.keyboard_arrow_up,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DirectionButton(
                onTap: homeLogic.movePlayerLeft,
                icon: Icons.keyboard_arrow_left,
              ),
              const SizedBox(width: 16 * 4),
              _DirectionButton(
                onTap: homeLogic.movePlayerRight,
                icon: Icons.keyboard_arrow_right,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DirectionButton(
            onTap: homeLogic.movePlayerDown,
            icon: Icons.keyboard_arrow_down,
          ),
        ],
      );
}

class _InfoItem extends StatelessWidget {
  final String label;
  final ValueNotifier<dynamic> value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ValueListenableBuilder(
        valueListenable: value,
        builder: (_, val, __) =>
            Text("$label: $val", textAlign: TextAlign.center),
      ),
    );
  }
}

class _AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _AppButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  const _DirectionButton({required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      size: const Size.square(48),
      onTap: onTap,
      // icon: Icon(icon, size: _LayoutConstants.buttonSize),
    );
  }
}

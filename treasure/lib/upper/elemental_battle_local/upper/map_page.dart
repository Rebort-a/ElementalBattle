import 'package:flutter/material.dart';

import '../foundation/energy.dart';
import '../foundation/image.dart';
import '../middleware/common.dart';
import '../foundation/map.dart';
import '../middleware/home_logic.dart';

class MapPage extends StatelessWidget {
  final HomeLogic homeLogic = HomeLogic();

  MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: OrientationBuilder(
        builder: (context, orientation) {
          // 根据屏幕方向选择布局
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
      );

  // 竖屏布局
  Widget _buildPortraitLayout(BuildContext context) => Column(
        children: [
          // 弹出页面
          _buildDialog(),

          Flexible(
            child: Column(
              children: [
                // 地图区域
                Expanded(flex: 8, child: _buildMapRegion()),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // 信息区域
                      _buildInfoRegion(Axis.horizontal),
                      // 行为按钮区域
                      _buildActionButtonRegion(context, Axis.horizontal),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 方向按钮区域
          _buildDirectionButtonRegion(),
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
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 行为按钮区域
                      _buildActionButtonRegion(context, Axis.vertical),

                      //信息区域
                      _buildInfoRegion(Axis.vertical),
                    ],
                  ),
                ),
                // 地图区域
                Expanded(flex: 5, child: _buildMapRegion()),
                // 方向按钮区域
                Expanded(flex: 3, child: _buildDirectionButtonRegion()),
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
        aspectRatio: 1.0, // 宽高比为1:1（正方形）
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blueGrey,
              border: Border.all(color: Colors.grey, width: 8),
            ),
            child: ValueListenableBuilder<List<List<ValueNotifier<CellData>>>>(
              valueListenable: homeLogic.displayMap,
              builder: (context, map, _) {
                if (map.isEmpty || map[0].isEmpty) {
                  return const Center(child: Text('地图数据为空'));
                }

                final int rows = map.length; // 行数（y轴，纵向单元格数量）
                final int cols = map[0].length; // 列数（x轴，横向单元格数量）

                return LayoutBuilder(
                  builder: (context, constraints) {
                    //取像素整数
                    int containerWidth = (constraints.maxWidth ~/ cols) * cols;
                    int containerHeight =
                        (constraints.maxHeight ~/ rows) * rows;

                    int containerSize = containerWidth < containerHeight
                        ? containerWidth
                        : containerHeight;

                    return SizedBox(
                      width: containerSize.toDouble(),
                      height: containerSize.toDouble(),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols, // 列数
                          childAspectRatio: 1, // 单元格正方形
                          mainAxisSpacing: 0, // 移除网格间距
                          crossAxisSpacing: 0,
                        ),
                        itemCount: rows * cols, // 总单元格数
                        itemBuilder: (context, index) {
                          final x = index % cols; // x坐标（列）
                          final y = index ~/ cols; // y坐标（行）
                          return ValueListenableBuilder(
                            valueListenable: map[y][x],
                            builder: (context, value, child) {
                              return ImageManager().getImage(
                                value.id,
                                value.iconIndex,
                                value.colorIndex,
                                value.fogFlag,
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

  Widget _buildInfoRegion(Axis direction) {
    final infoItems = [
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
    ];

    final children = direction == Axis.horizontal
        ? infoItems
        : [const Spacer(flex: 1), ...infoItems];

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: direction == Axis.horizontal
          ? Row(children: children)
          : Column(children: children),
    );
  }

  Widget _buildActionButtonRegion(BuildContext context, Axis direction) {
    final buttons = [
      _ActionButton(
        text: "背包",
        onPressed: () => homeLogic.navigateToPackagePage(context),
      ),
      _ActionButton(
        text: "技能",
        onPressed: () => homeLogic.navigateToSkillsPage(context),
      ),
      _ActionButton(
        text: "状态",
        onPressed: () => homeLogic.navigateToStatusPage(context),
      ),
      _ActionButton(
        text: "切换",
        onPressed: homeLogic.switchPlayerNext,
      ),
    ];

    return direction == Axis.horizontal
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: buttons)
        : Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: buttons);
  }

  Widget _buildDirectionButtonRegion() => Column(
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
      flex: 1,
      child: ValueListenableBuilder(
        valueListenable: value,
        builder: (_, val, __) =>
            Text("$label: $val", textAlign: TextAlign.center),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _ActionButton({required this.text, required this.onPressed});

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

import 'package:flutter/material.dart';
import 'package:flutter_code/foundation/entity.dart';

import '../foundation/energy.dart';
import '../foundation/image.dart';
import '../middleware/elemental.dart';
import '../middleware/player.dart';
import '../middleware/combat_logic.dart';

class CombatPage extends StatelessWidget {
  late final CombatLogic combatLogic;
  final PlayerElemental player;
  final EnemyElemental enemy;
  final bool offensive;

  CombatPage(
      {super.key,
      required this.player,
      required this.enemy,
      required this.offensive}) {
    combatLogic =
        CombatLogic(player: player, enemy: enemy, offensive: offensive);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("战斗"),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            // 弹出页面
            _buildDialog(),
            // 信息区域
            _buildInfoRegion(),
            // 消息区域
            _buildMessageRegion(),
            // 按键区域
            _buildButtonRegion(),
            // 底部空白区域
            _buildBlankRegion(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialog() {
    return ValueListenableBuilder<void Function(BuildContext)>(
      valueListenable: combatLogic.showPage,
      builder: (context, value, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          value(context);
        });
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildInfoRegion() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlayerInfo(),
          _buildEnemyInfo(),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo() {
    return BattleInfoRegion(info: combatLogic.player.preview);
  }

  Widget _buildEnemyInfo() {
    return BattleInfoRegion(info: combatLogic.enemy.preview);
  }

  Widget _buildMessageRegion() {
    return Expanded(
      child: ValueListenableBuilder<String>(
        valueListenable: combatLogic.combatMessage,
        builder: (context, value, child) {
          return BattleMessageRegion(combatMessage: value);
        },
      ),
    );
  }

  Widget _buildButtonRegion() {
    return BattleButtonRegion(combatLogic: combatLogic);
  }

  Widget _buildBlankRegion() {
    return const SizedBox(height: 192);
  }
}

class BattleInfoRegion extends StatelessWidget {
  final ElementalPreview info;

  const BattleInfoRegion({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildInfoTitle(),
        Text('等级: ${info.level}'),
        _buildInfoRoll('生命值', info.health),
        _buildInfoRoll('攻击力', info.attack),
        _buildInfoRoll('防御力', info.defence),
        _buildGlobalStatus(),
      ],
    );
  }

  Widget _buildInfoTitle() {
    return Row(
      children: [
        ValueListenableBuilder(
          valueListenable: info.name,
          builder: (context, value, child) {
            return Text(value);
          },
        ),
        ValueListenableBuilder(
          valueListenable: info.emoji,
          builder: (context, value, child) {
            return ImageManager.getIcon(EntityID.player, value);
          },
        ),
      ],
    );
  }

  Widget _buildInfoRoll(String label, ValueNotifier<int> notifier) {
    return Row(
      children: [
        Text('$label: '),
        ValueListenableBuilder<int>(
          valueListenable: notifier,
          builder: (context, value, child) {
            return TweenAnimationBuilder(
              tween:
                  Tween<double>(begin: value.toDouble(), end: value.toDouble()),
              duration: const Duration(milliseconds: 500),
              builder: (context, double value, child) {
                return Text(
                  '${value.toInt()}',
                  key: ValueKey<int>(value.toInt()),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildGlobalStatus() {
    return ValueListenableBuilder(
      valueListenable: info.resumes,
      builder: (context, value, child) {
        List<Widget> widgets = [];

        // 添加当前元素到第一行
        widgets.add(_buildElementBox(value[0]));

        // 添加其余元素到第二行
        List<Widget> otherWidgets = List.generate(value.length - 1, (index) {
          return _buildElementBox(value[index + 1]);
        });

        // 如果有其他元素，则添加到第二行
        widgets.add(Wrap(children: otherWidgets));

        return Column(
          children: widgets,
        );
      },
    );
  }

  Widget _buildElementBox(EnergyResume resume) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: resume.health > 0 ? Colors.blue : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(energyNames[resume.type.index]),
    );
  }
}

class BattleMessageRegion extends StatelessWidget {
  final String combatMessage;

  const BattleMessageRegion({super.key, required this.combatMessage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10.0),
      ),
      // 使用SizedBox来限制高度
      child: SizedBox(
        height: 200, // 设置一个固定的高度
        child: SingleChildScrollView(
          reverse: true,
          child: Text(
            combatMessage,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class BattleButtonRegion extends StatelessWidget {
  final CombatLogic combatLogic;

  const BattleButtonRegion({super.key, required this.combatLogic});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButton("进攻", combatLogic.conductAttack),
        _buildButton("格挡", combatLogic.conductParry),
        _buildButton("技能", combatLogic.conductSkill),
        _buildButton("逃跑", combatLogic.conductEscape),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

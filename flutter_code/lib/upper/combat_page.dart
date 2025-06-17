import 'package:flutter/material.dart';

import '../foundation/energy.dart';
import '../foundation/image.dart';
import '../middleware/elemental.dart';
import '../middleware/combat_logic.dart';

class CombatPage extends StatelessWidget {
  late final CombatLogic combatLogic;
  final Elemental player;
  final Elemental enemy;
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPlayerInfo()),
        Expanded(child: _buildEnemyInfo()),
      ],
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
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildInfoRow(_buildInfoName(), _buildInfoEmoji()),
        _buildInfoRow(_buildInfoLabel('等级'), _buildInfoNotifier(info.level)),
        _buildInfoRow(_buildInfoLabel('生命值'), _buildInfoNotifier(info.health)),
        _buildInfoRow(_buildInfoLabel('攻击力'), _buildInfoNotifier(info.attack)),
        _buildInfoRow(_buildInfoLabel('防御力'), _buildInfoNotifier(info.defence)),
        _buildGlobalStatus(),
      ],
    );
  }

  Widget _buildInfoRow(Widget title, Widget content) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              title,
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              content,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoName() {
    return ValueListenableBuilder(
      valueListenable: info.name,
      builder: (context, value, child) {
        return Text(value);
      },
    );
  }

  Widget _buildInfoEmoji() {
    return ValueListenableBuilder(
      valueListenable: info.emoji,
      builder: (context, value, child) {
        return ImageManager.getCombatEmoji(value);
      },
    );
  }

  Widget _buildInfoLabel(String label) {
    return Text('$label: ');
  }

  Widget _buildInfoNotifier(ValueNotifier<int> notifier) {
    return ValueListenableBuilder<int>(
      valueListenable: notifier,
      builder: (context, value, child) {
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: value.toDouble(), end: value.toDouble()),
          duration: const Duration(milliseconds: 500),
          builder: (context, double value, child) {
            return Text(
              '${value.toInt()}',
              key: ValueKey<int>(value.toInt()),
            );
          },
        );
      },
    );
  }

  Widget _buildGlobalStatus() {
    return ValueListenableBuilder(
      valueListenable: info.resumes,
      builder: (context, List<EnergyResume> resumes, child) {
        final front = resumes.isNotEmpty
            ? _buildElementBox(resumes.first)
            : const SizedBox.shrink();
        final backend = resumes.length > 1
            ? Wrap(
                children: resumes.skip(1).map(_buildElementBox).toList(),
              )
            : const SizedBox.shrink();

        return Column(
          children: [
            front,
            backend,
          ],
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

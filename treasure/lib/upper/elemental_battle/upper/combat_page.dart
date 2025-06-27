import 'package:flutter/material.dart';

import '../../../middleware/back_end.dart';
import '../../../middleware/front_end.dart';
import '../middleware/energy.dart';
import '../middleware/elemental.dart';
import 'combat_manager.dart';

class CombatPage extends StatelessWidget {
  final RoomInfo roomInfo;
  final String userName;
  late final CombatManager _combatManager;

  CombatPage({super.key, required this.roomInfo, required this.userName}) {
    _combatManager = CombatManager(roomInfo: roomInfo, userName: userName);
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
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return ValueListenableBuilder<GameStep>(
      valueListenable: _combatManager.gameStep,
      builder: (__, step, _) {
        return Column(
          children: [
            // 弹出页面
            _buildDialog(),
            ...(step.index >= GameStep.playerTrun.index
                ? _buildCombat()
                : _buildPrepare(step)),

            Expanded(
                child:
                    MessageList(networkEngine: _combatManager.networkEngine)),
            MessageInput(networkEngine: _combatManager.networkEngine),
          ],
        );
      },
    );
  }

  List<Widget> _buildPrepare(GameStep step) {
    String statusMessage = _getStatusMessage(step);

    return [
      if (step == GameStep.disconnect || step == GameStep.connected)
        const CircularProgressIndicator(),
      const SizedBox(height: 20),
      Text(statusMessage),
      const SizedBox(height: 20),
      if (step == GameStep.frontConfig || step == GameStep.rearConfig)
        ElevatedButton(
          onPressed: () => _combatManager.navigateToCastPage(),
          child: const Text('配置角色'),
        ),
      const SizedBox(height: 20),
      if (step == GameStep.rearConfig)
        ElevatedButton(
          onPressed: () => _combatManager.navigateToStatePage(),
          child: const Text('查看对手信息'),
        ),
    ];
  }

  String _getStatusMessage(GameStep gameStep) {
    switch (gameStep) {
      case GameStep.disconnect:
        return "等待连接";
      case GameStep.connected:
        return "已连接，等待对手加入...";
      case GameStep.frontConfig:
        return "请配置";
      case GameStep.rearWait:
        return "等待先手配置";
      case GameStep.frontWait:
        return "等待后手配置";
      case GameStep.rearConfig:
        return "请配置或查看对方配置";
      default:
        return "战斗结束";
    }
  }

  List<Widget> _buildCombat() {
    return [
      // 信息区域
      _buildInfoRegion(),
      // 消息区域
      _buildMessageRegion(),
      // 按键区域
      _buildButtonRegion(),
    ];
  }

  Widget _buildDialog() {
    return ValueListenableBuilder<void Function(BuildContext)>(
      valueListenable: _combatManager.showPage,
      builder: (context, value, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          value(context);
          _combatManager.showPage.value = (BuildContext context) {};
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
    return BattleInfoRegion(info: _combatManager.player.preview);
  }

  Widget _buildEnemyInfo() {
    return BattleInfoRegion(info: _combatManager.enemy.preview);
  }

  Widget _buildMessageRegion() {
    return Expanded(
      child: ValueListenableBuilder<String>(
        valueListenable: _combatManager.infoList,
        builder: (context, value, child) {
          return BattleMessageRegion(infoList: value);
        },
      ),
    );
  }

  Widget _buildButtonRegion() {
    return BattleButtonRegion(combatManager: _combatManager);
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
            children: [title],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [content],
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
        return _getCombatEmoji(value);
      },
    );
  }

  static Widget _getCombatEmoji(double emoji) {
    if (emoji < 0.125) {
      return const Text('😢');
    } else if (emoji < 0.25) {
      return const Text('😞');
    } else if (emoji < 0.5) {
      return const Text('😮');
    } else if (emoji < 0.75) {
      return const Text('😐');
    } else if (emoji < 0.875) {
      return const Text('😊');
    } else {
      return const Text('😎');
    }
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
            return Text('${value.toInt()}', key: ValueKey<int>(value.toInt()));
          },
        );
      },
    );
  }

  Widget _buildGlobalStatus() {
    return ValueListenableBuilder(
      valueListenable: info.resumes,
      builder: (context, value, child) {
        final front = value.isNotEmpty
            ? _buildElementBox(value.first)
            : const SizedBox.shrink();
        final backend = value.length > 1
            ? Wrap(children: value.skip(1).map(_buildElementBox).toList())
            : const SizedBox.shrink();

        return Column(children: [front, backend]);
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
  final String infoList;

  const BattleMessageRegion({super.key, required this.infoList});

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
          child: Text(infoList, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class BattleButtonRegion extends StatelessWidget {
  final CombatManager combatManager;

  const BattleButtonRegion({super.key, required this.combatManager});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButton("进攻", combatManager.conductAttack),
        _buildButton("格挡", combatManager.conductParry),
        _buildButton("技能", combatManager.conductSkill),
        _buildButton("逃跑", combatManager.conductEscape),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(onPressed: onPressed, child: Text(text));
  }
}

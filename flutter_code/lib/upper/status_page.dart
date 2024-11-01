import 'package:flutter/material.dart';

import '../foundation/effect.dart';
import '../middleware/player.dart';

class StatusPage extends StatefulWidget {
  final PlayerElemental player;
  const StatusPage({super.key, required this.player});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.player.current;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('状态'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStatusInfo(),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPlayerInfo(),
          const Divider(),
          _buildAttributeInfo(),
          const Divider(),
          _buildSkillsList(),
          const Divider(),
          _buildEffectsList(),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo() {
    return Column(
      children: [
        Text(widget.player.name,
            style: Theme.of(context).textTheme.titleMedium),
        Text('经验: ${widget.player.experience}',
            style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }

  Widget _buildAttributeInfo() {
    return Column(
      children: [
        _buildTextItem('等级: ${widget.player.getAppointLevel(_index)}'),
        _buildTextItem('生命值上限: ${widget.player.getAppointCapacity(_index)}'),
        _buildTextItem('初始攻击力: ${widget.player.getAppointAttackBase(_index)}'),
        _buildTextItem('初始防御力: ${widget.player.getAppointDefenceBase(_index)}'),
        const Divider(),
        _buildTextItem('当前生命值: ${widget.player.getAppointHealth(_index)}'),
        _buildTextItem('当前攻击力: ${widget.player.getAppointAttack(_index)}'),
        _buildTextItem('当前防御力: ${widget.player.getAppointDefence(_index)}'),
      ],
    );
  }

  Widget _buildSkillsList() {
    return ListTile(
      title: const Text('掌握技能:', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        children: widget.player
            .getAppointSkills(_index)
            .where((skill) => skill.learned)
            .map((skill) => _buildTextItem(skill.name))
            .toList(),
      ),
    );
  }

  Widget _buildEffectsList() {
    return ListTile(
      title: const Text('获得影响:', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        children: widget.player
            .getAppointEffects(_index)
            .where((effect) =>
                (effect.type == EffectType.infinite || effect.times > 0))
            .map((effect) => _buildTextItem(
                  '${effect.id} ${effect.type} ${effect.value} ${effect.times}',
                ))
            .toList(),
      ),
    );
  }

// 自定义文本组件，用于统一文本展示的样式
  Widget _buildTextItem(String text) {
    return Text(text, style: const TextStyle(fontSize: 16)); // 可以根据需要调整样式
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavigationButton(Icons.arrow_left, () {
          setState(() {
            _index = (_index + widget.player.count - 1) % widget.player.count;
          });
        }),
        _buildElementName(),
        _buildNavigationButton(Icons.arrow_right, () {
          setState(() {
            _index = (_index + 1) % widget.player.count;
          });
        }),
      ],
    );
  }

  Widget _buildNavigationButton(IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Icon(icon),
    );
  }

  Widget _buildElementName() {
    return Text(widget.player.getAppointTypeString(_index));
  }
}

import 'package:flutter/material.dart';

import '../foundation/effect.dart';
import '../middleware/elemental.dart';

class StatusPage extends StatefulWidget {
  final Elemental elemental;
  const StatusPage({super.key, required this.elemental});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.elemental.current;
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
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildNameInfo(),
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

  Widget _buildNameInfo() {
    return Column(
      children: [
        Text(widget.elemental.name,
            style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildAttributeInfo() {
    return Column(
      children: [
        _buildTextItem('等级: ${widget.elemental.getAppointLevel(_index)}'),
        _buildTextItem('生命值上限: ${widget.elemental.getAppointCapacity(_index)}'),
        _buildTextItem(
            '初始攻击力: ${widget.elemental.getAppointAttackBase(_index)}'),
        _buildTextItem(
            '初始防御力: ${widget.elemental.getAppointDefenceBase(_index)}'),
        const Divider(),
        _buildTextItem('当前生命值: ${widget.elemental.getAppointHealth(_index)}'),
        _buildTextItem('当前攻击力: ${widget.elemental.getAppointAttack(_index)}'),
        _buildTextItem('当前防御力: ${widget.elemental.getAppointDefence(_index)}'),
      ],
    );
  }

  Widget _buildSkillsList() {
    return ListTile(
      title: const Text('掌握技能:', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        children: widget.elemental
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
        children: widget.elemental
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
            _index = widget.elemental.findAvailableIndex(_index, -1);
          });
        }),
        _buildElementName(),
        _buildNavigationButton(Icons.arrow_right, () {
          setState(() {
            _index = widget.elemental.findAvailableIndex(_index, 1);
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
    return Text(widget.elemental.getAppointTypeString(_index));
  }
}

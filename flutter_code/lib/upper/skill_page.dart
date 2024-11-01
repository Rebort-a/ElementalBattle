import 'package:flutter/material.dart';

import '../foundation/skill.dart';
import '../middleware/common.dart';
import '../middleware/player.dart';

class SkillsPage extends StatefulWidget {
  final PlayerElemental player;
  const SkillsPage({super.key, required this.player});

  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage> {
  late List<CombatSkill> _playerSkills;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.player.current;
    _updateSkills();
  }

  _updateSkills() {
    _playerSkills = widget.player.getAppointSkills(_index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('技能'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSkillTree(),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildSkillTree() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          children: List.generate(_playerSkills.length, _buildSkillNode),
        ),
      ),
    );
  }

  Widget _buildSkillNode(int index) {
    return GestureDetector(
      onTap: () => _showPlayerSkill(context, index),
      child: Container(
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: _playerSkills[index].learned ? Colors.blue : Colors.grey,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(child: _buildSkillText(_playerSkills[index])),
      ),
    );
  }

  Widget _buildSkillText(CombatSkill skill) {
    // String typeText = skill.type == SkillType.active ? '🔥' : '🛡️';
    String typeText = skill.type == SkillType.active ? '主动' : '被动';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          skill.name,
          style: const TextStyle(color: Colors.white, fontSize: 16.0),
        ),
        Text(
          typeText,
          style: const TextStyle(color: Colors.white, fontSize: 12.0),
        ),
      ],
    );
  }

  void _showPlayerSkill(BuildContext context, int index) {
    final AlertDialog showPage = AlertDialog(
      title: Text(_playerSkills[index].name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('目标: ${_getTargetText(_playerSkills[index])}'),
          Text('效果: ${_playerSkills[index].description}'),
        ],
      ),
      actions: [
        if (!_playerSkills[index].learned)
          TextButton(
            child: const Text('学习'),
            onPressed: () {
              if (widget.player.experience >= 30) {
                widget.player.experience -= 30;
                SnackBarMessage(context, '学习成功！');
                setState(() {
                  _playerSkills[index].learned = true;
                });
              } else {
                SnackBarMessage(context, '经验不足！');
              }
              Navigator.of(context).pop();
            },
          ),
        TextButton(
          child: Text(_playerSkills[index].learned ? '关闭' : '取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );

    showDialog(context: context, builder: (context) => showPage);
  }

  String _getTargetText(CombatSkill skill) {
    switch (skill.targetType) {
      case SkillTarget.selfFront:
        return '已方前台角色';
      case SkillTarget.selfAny:
        return '己方任一角色';
      case SkillTarget.enemyFront:
        return '敌方前台角色';
      case SkillTarget.enemyAny:
        return '敌方任一角色';
    }
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavigationButton(Icons.arrow_left, () {
          setState(() {
            _index = (_index + widget.player.count - 1) % widget.player.count;
            _updateSkills();
          });
        }),
        _buildElementName(),
        _buildNavigationButton(Icons.arrow_right, () {
          setState(() {
            _index = (_index + 1) % widget.player.count;
            _updateSkills();
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

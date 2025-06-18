import 'package:flutter/material.dart';

import '../foundation/energy.dart';
import '../foundation/skill.dart';
import '../middleware/elemental.dart';
import '../middleware/player.dart';
import 'combat_page.dart';

class PracticePage extends StatefulWidget {
  final NormalPlayer player;
  const PracticePage({super.key, required this.player});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  final TextEditingController _nameController =
      TextEditingController(text: "假人");
  int _totalPoints = 30;
  final Map<EnergyType, bool> _energyEnabled = {
    for (EnergyType type in EnergyType.values) type: true
  };
  final Map<EnergyType, int> _healthPoints = {
    for (EnergyType type in EnergyType.values) type: 0
  };
  final Map<EnergyType, int> _attackPoints = {
    for (EnergyType type in EnergyType.values) type: 0
  };
  final Map<EnergyType, int> _defencePoints = {
    for (EnergyType type in EnergyType.values) type: 0
  };
  final Map<EnergyType, int> _skillsLearned = {
    for (EnergyType type in EnergyType.values) type: 1 // 默认学习第一个技能
  };

  int _currentEnergyIndex = 0;
  EnergyType get _currentEnergy => EnergyType.values[_currentEnergyIndex];

  // 控制器用于控制PageView
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentEnergyEnabled = _energyEnabled[_currentEnergy]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('自定义敌人练习'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _createEnemy,
          ),
        ],
      ),
      body: Column(
        children: [
          // 总点数显示
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '剩余点数: $_totalPoints',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // 名称输入
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '敌人名称',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // 增强的灵根卡片区域，添加了左右切换按钮
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 灵根卡片
                PageView.builder(
                  controller: _pageController,
                  itemCount: EnergyType.values.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentEnergyIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final energyType = EnergyType.values[index];
                    return _buildEnergyCard(energyType);
                  },
                ),
                // 左切换按钮
                Positioned(
                  left: 0,
                  child: _buildNavigationButton(
                    Icons.arrow_back_ios,
                    () => _changeEnergy(-1),
                  ),
                ),
                // 右切换按钮
                Positioned(
                  right: 0,
                  child: _buildNavigationButton(
                    Icons.arrow_forward_ios,
                    () => _changeEnergy(1),
                  ),
                ),
              ],
            ),
          ),

          // 属性加点
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttributeControl(
                  '生命',
                  _healthPoints[_currentEnergy]!,
                  isCurrentEnergyEnabled
                      ? (value) => _updateAttribute(AttributeType.hp, value)
                      : null,
                  isCurrentEnergyEnabled,
                ),
                _buildAttributeControl(
                  '攻击',
                  _attackPoints[_currentEnergy]!,
                  isCurrentEnergyEnabled
                      ? (value) => _updateAttribute(AttributeType.atk, value)
                      : null,
                  isCurrentEnergyEnabled,
                ),
                _buildAttributeControl(
                  '防御',
                  _defencePoints[_currentEnergy]!,
                  isCurrentEnergyEnabled
                      ? (value) => _updateAttribute(AttributeType.def, value)
                      : null,
                  isCurrentEnergyEnabled,
                ),
              ],
            ),
          ),

          // 技能树
          Expanded(
            child: _buildSkillTree(isCurrentEnergyEnabled),
          ),
        ],
      ),
    );
  }

  // 构建圆形导航按钮
  Widget _buildNavigationButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  // 切换灵根
  void _changeEnergy(int delta) {
    final newIndex = _currentEnergyIndex + delta;
    if (newIndex >= 0 && newIndex < EnergyType.values.length) {
      setState(() {
        _currentEnergyIndex = newIndex;
        _pageController.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Widget _buildEnergyCard(EnergyType energyType) {
    final isEnabled = _energyEnabled[energyType]!;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isEnabled ? null : Colors.grey.withOpacity(0.3),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  energyNames[energyType.index],
                  style: TextStyle(
                    fontSize: 32,
                    color: isEnabled ? null : Colors.grey,
                  ),
                ),
                Text(
                  energyType.toString().split('.').last,
                  style: TextStyle(
                    fontSize: 16,
                    color: isEnabled ? null : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _toggleEnergyEnabled(energyType),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isEnabled ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEnabled ? Icons.check : Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeControl(
      String label, int value, Function(int)? onChanged, bool isEnabled) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isEnabled ? null : Colors.grey,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove, color: isEnabled ? null : Colors.grey),
              onPressed:
                  isEnabled && value > 0 ? () => onChanged?.call(-1) : null,
            ),
            Text(
              value.toString(),
              style: TextStyle(
                color: isEnabled ? null : Colors.grey,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add, color: isEnabled ? null : Colors.grey),
              onPressed: isEnabled && _totalPoints > 0
                  ? () => onChanged?.call(1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillTree(bool isEnergyEnabled) {
    final allSkills = SkillCollection.totalSkills[_currentEnergy.index];
    final learnedCount = _skillsLearned[_currentEnergy]!;
    final totalSkillsCount = allSkills.length;

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: totalSkillsCount,
      itemBuilder: (context, index) {
        final skill = allSkills[index];
        final isLearned = index < learnedCount;
        // 仅允许学习下一个技能（最后一个已学习技能的下一个）
        final canLearn = isEnergyEnabled &&
            index == learnedCount &&
            index < totalSkillsCount;
        // 仅允许遗忘最后一个已学习技能，且不是第一个技能
        final canForget = isEnergyEnabled &&
            isLearned &&
            index == learnedCount - 1 &&
            index > 0;

        return GestureDetector(
          onTap:
              canLearn || canForget || (isLearned && index == 0) // 第一个技能始终可点击查看
                  ? () => _showSkillDialog(index, canLearn, canForget)
                  : null,
          child: Container(
            decoration: BoxDecoration(
              color: isLearned
                  ? Colors.blue.withOpacity(isEnergyEnabled ? 1.0 : 0.5)
                  : Colors.grey[300]!.withOpacity(isEnergyEnabled ? 1.0 : 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  skill.name,
                  style: TextStyle(
                    color: isLearned ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  skill.type == SkillType.active ? '主动' : '被动',
                  style: TextStyle(
                    color: isLearned ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSkillDialog(int skillIndex, bool canLearn, bool canForget) {
    final allSkills = SkillCollection.totalSkills[_currentEnergy.index];
    CombatSkill skill = allSkills[skillIndex];
    final isLearned = skillIndex < _skillsLearned[_currentEnergy]!;
    final totalSkillsCount = allSkills.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(skill.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('类型: ${skill.type == SkillType.active ? '主动' : '被动'}'),
            Text('目标: ${_getTargetText(skill.targetType)}'),
            const SizedBox(height: 8),
            Text(skill.description),
          ],
        ),
        actions: [
          if (!isLearned && canLearn && skillIndex < totalSkillsCount)
            TextButton(
              onPressed: _totalPoints > 0
                  ? () {
                      setState(() {
                        _skillsLearned[_currentEnergy] =
                            _skillsLearned[_currentEnergy]! + 1;
                        _totalPoints--;
                        Navigator.pop(context);
                      });
                    }
                  : null,
              child: const Text('学习'),
            ),
          if (isLearned && canForget)
            TextButton(
              child: const Text('遗忘'),
              onPressed: () {
                setState(() {
                  _skillsLearned[_currentEnergy] =
                      _skillsLearned[_currentEnergy]! - 1;
                  _totalPoints++;
                  Navigator.pop(context);
                });
              },
            ),
          TextButton(
            child: const Text('关闭'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  String _getTargetText(SkillTarget target) {
    switch (target) {
      case SkillTarget.selfFront:
        return '己方前台';
      case SkillTarget.selfAny:
        return '己方任意';
      case SkillTarget.enemyFront:
        return '敌方前台';
      case SkillTarget.enemyAny:
        return '敌方任意';
    }
  }

  void _toggleEnergyEnabled(EnergyType energyType) {
    setState(() {
      final wasEnabled = _energyEnabled[energyType]!;
      _energyEnabled[energyType] = !wasEnabled;

      if (wasEnabled) {
        // 禁用灵根，返还点数并增加3点
        _totalPoints += _healthPoints[energyType]!;
        _totalPoints += _attackPoints[energyType]!;
        _totalPoints += _defencePoints[energyType]!;
        _totalPoints += _skillsLearned[energyType]! - 1; // 扣除第一个强制技能
        _totalPoints += 3; // 启用时扣除的3点

        // 重置该灵根的所有属性，但保留第一个技能
        _healthPoints[energyType] = 0;
        _attackPoints[energyType] = 0;
        _defencePoints[energyType] = 0;
        _skillsLearned[energyType] = 1; // 始终保留第一个技能
      } else {
        // 启用灵根，扣除3点
        if (_totalPoints >= 3) {
          _totalPoints -= 3;
        } else {
          // 点数不足，恢复禁用状态
          _energyEnabled[energyType] = false;
        }
      }
    });
  }

  void _updateAttribute(AttributeType attribute, int delta) {
    setState(() {
      if (delta > 0 && _totalPoints > 0) {
        // 加点
        switch (attribute) {
          case AttributeType.hp:
            _healthPoints[_currentEnergy] = _healthPoints[_currentEnergy]! + 1;
          case AttributeType.atk:
            _attackPoints[_currentEnergy] = _attackPoints[_currentEnergy]! + 1;
          case AttributeType.def:
            _defencePoints[_currentEnergy] =
                _defencePoints[_currentEnergy]! + 1;
        }
        _totalPoints--;
      } else if (delta < 0 &&
          (_healthPoints[_currentEnergy]! > 0 ||
              _attackPoints[_currentEnergy]! > 0 ||
              _defencePoints[_currentEnergy]! > 0)) {
        // 减点
        switch (attribute) {
          case AttributeType.hp:
            if (_healthPoints[_currentEnergy]! > 0) {
              _healthPoints[_currentEnergy] =
                  _healthPoints[_currentEnergy]! - 1;
            }
          case AttributeType.atk:
            if (_attackPoints[_currentEnergy]! > 0) {
              _attackPoints[_currentEnergy] =
                  _attackPoints[_currentEnergy]! - 1;
            }
          case AttributeType.def:
            if (_defencePoints[_currentEnergy]! > 0) {
              _defencePoints[_currentEnergy] =
                  _defencePoints[_currentEnergy]! - 1;
            }
        }
        _totalPoints++;
      }
    });
  }

  void _createEnemy() {
    final configs = Elemental.getDefaultConfig();

    for (final type in EnergyType.values) {
      final config = configs[type]!;
      config.energySwitch = _energyEnabled[type]!;
      config.healthPoints = _healthPoints[type]!;
      config.attackPoints = _attackPoints[type]!;
      config.defencePoints = _defencePoints[type]!;
      config.skillPoints = _skillsLearned[type]!;
    }

    final enemy = Elemental(
      baseName: _nameController.text,
      config: configs,
    );

    // 返回创建的自定义敌人
    navigateToCombatPage(context, enemy, true);
  }

  void navigateToCombatPage(
      BuildContext context, Elemental enemy, bool offensive) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CombatPage(
                player: widget.player,
                enemy: enemy,
                offensive: offensive,
              )),
    ).then((value) {
      // 当页面弹出（即返回）时，这个回调会被执行
      widget.player.restoreEnergies();
    });
  }
}

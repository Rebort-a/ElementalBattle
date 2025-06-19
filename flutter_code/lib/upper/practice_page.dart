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
  final PageController _pageController = PageController();
  int _totalPoints = 30;
  EnergyType _currentEnergy = EnergyType.wood;

  final Map<EnergyType, EnergyConfig> _configs = Elemental.getDefaultConfig();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _configs[_currentEnergy]!;
    final isEnabled = config.energySwitch;

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
          _buildPointCounter(),
          _buildNameInput(),
          _buildEnergySelector(isEnabled),
          _buildAttributeControls(config, isEnabled),
          _buildSkillTree(config, isEnabled),
        ],
      ),
    );
  }

  Widget _buildPointCounter() => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          '剩余点数: $_totalPoints',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildNameInput() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '敌人名称',
            border: OutlineInputBorder(),
          ),
        ),
      );

  Widget _buildEnergySelector(bool isEnabled) => Container(
        height: 120,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: EnergyType.values.length,
              onPageChanged: (index) =>
                  setState(() => _currentEnergy = EnergyType.values[index]),
              itemBuilder: (_, index) =>
                  _buildEnergyCard(EnergyType.values[index]),
            ),
            Positioned(
              left: 0,
              child: _buildNavButton(Icons.arrow_back_ios, -1),
            ),
            Positioned(
              right: 0,
              child: _buildNavButton(Icons.arrow_forward_ios, 1),
            ),
          ],
        ),
      );

  Widget _buildNavButton(IconData icon, int delta) => Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue,
          boxShadow: [
            BoxShadow(
                color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: () => _changeEnergy(delta),
          padding: EdgeInsets.zero,
        ),
      );

  Widget _buildEnergyCard(EnergyType type) {
    final config = _configs[type]!;
    final isEnabled = config.energySwitch;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isEnabled ? null : Colors.grey.withOpacity(0.3),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  energyNames[type.index],
                  style: TextStyle(
                      fontSize: 32, color: isEnabled ? null : Colors.grey),
                ),
                Text(
                  type.toString().split('.').last,
                  style: TextStyle(
                      fontSize: 16, color: isEnabled ? null : Colors.grey),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _toggleEnergy(type),
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

  Widget _buildAttributeControls(EnergyConfig config, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttributeControl(
              AttributeType.hp, config.healthPoints, isEnabled),
          _buildAttributeControl(
              AttributeType.atk, config.attackPoints, isEnabled),
          _buildAttributeControl(
              AttributeType.def, config.defencePoints, isEnabled),
        ],
      ),
    );
  }

  Widget _buildAttributeControl(
      AttributeType type, int points, bool isEnabled) {
    final step = switch (type) {
      AttributeType.hp => Energy.healthStep,
      AttributeType.atk => Energy.attackStep,
      AttributeType.def => Energy.defenceStep,
    };
    final baseValue = Energy.baseAttributes[_currentEnergy.index][type.index];
    final value = baseValue + points * step;

    return Column(
      children: [
        Text(attributeNames[type.index],
            style: TextStyle(color: isEnabled ? null : Colors.grey)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            '属性值: $value',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isEnabled ? Colors.blue : Colors.grey,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove, color: isEnabled ? null : Colors.grey),
              onPressed: isEnabled && points > 0
                  ? () => _updateAttribute(type, -1)
                  : null,
            ),
            Text(points.toString(),
                style: TextStyle(color: isEnabled ? null : Colors.grey)),
            IconButton(
              icon: Icon(Icons.add, color: isEnabled ? null : Colors.grey),
              onPressed: isEnabled && _totalPoints > 0
                  ? () => _updateAttribute(type, 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillTree(EnergyConfig config, bool isEnabled) {
    final skills = SkillCollection.totalSkills[_currentEnergy.index];
    final learnedCount = config.skillPoints;

    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: skills.length,
        itemBuilder: (_, index) =>
            _buildSkillCard(skills[index], index, learnedCount, isEnabled),
      ),
    );
  }

  Widget _buildSkillCard(
      CombatSkill skill, int index, int learnedCount, bool isEnabled) {
    final isLearned = index < learnedCount;
    final canLearn = isEnabled && index == learnedCount;
    final canForget =
        isEnabled && isLearned && index == learnedCount - 1 && index > 0;

    return GestureDetector(
      onTap: () => _showSkillDialog(skill, index, canLearn, canForget),
      child: Container(
        decoration: BoxDecoration(
          color: isLearned
              ? Colors.blue.withOpacity(isEnabled ? 1.0 : 0.5)
              : Colors.grey[300]!.withOpacity(isEnabled ? 1.0 : 0.5),
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
  }

  void _changeEnergy(int delta) {
    final newIndex = _currentEnergy.index + delta;
    if (newIndex >= 0 && newIndex < EnergyType.values.length) {
      setState(() {
        _currentEnergy = EnergyType.values[newIndex];
        _pageController.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _toggleEnergy(EnergyType type) {
    setState(() {
      final config = _configs[type]!;
      final wasEnabled = config.energySwitch;
      config.energySwitch = !wasEnabled;

      if (wasEnabled) {
        // 返还点数
        _totalPoints += config.healthPoints +
            config.attackPoints +
            config.defencePoints +
            (config.skillPoints - 1) +
            3;

        // 重置配置
        config.healthPoints = 0;
        config.attackPoints = 0;
        config.defencePoints = 0;
        config.skillPoints = 1;
      } else if (_totalPoints >= 3) {
        _totalPoints -= 3;
      } else {
        config.energySwitch = false; // 点数不足，恢复状态
      }
    });
  }

  void _updateAttribute(AttributeType type, int delta) {
    setState(() {
      final config = _configs[_currentEnergy]!;
      final current = switch (type) {
        AttributeType.hp => config.healthPoints,
        AttributeType.atk => config.attackPoints,
        AttributeType.def => config.defencePoints,
      };

      if (delta > 0 && _totalPoints > 0) {
        switch (type) {
          case AttributeType.hp:
            config.healthPoints++;
          case AttributeType.atk:
            config.attackPoints++;
          case AttributeType.def:
            config.defencePoints++;
        }
        _totalPoints--;
      } else if (delta < 0 && current > 0) {
        switch (type) {
          case AttributeType.hp:
            config.healthPoints--;
          case AttributeType.atk:
            config.attackPoints--;
          case AttributeType.def:
            config.defencePoints--;
        }
        _totalPoints++;
      }
    });
  }

  void _showSkillDialog(
      CombatSkill skill, int index, bool canLearn, bool canForget) {
    final config = _configs[_currentEnergy]!;
    final learnedCount = config.skillPoints;
    final isLearned = index < learnedCount;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(skill.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('类型: ${skill.type == SkillType.active ? '主动' : '被动'}'),
            Text('目标: ${CombatSkill.getTargetText(skill.targetType)}'),
            const SizedBox(height: 8),
            Text(skill.description),
          ],
        ),
        actions: [
          if (!isLearned && canLearn)
            TextButton(
              onPressed: _totalPoints > 0
                  ? () {
                      setState(() {
                        config.skillPoints++;
                        _totalPoints--;
                        Navigator.pop(context);
                      });
                    }
                  : null,
              child: const Text('学习'),
            ),
          if (canForget)
            TextButton(
              onPressed: () {
                setState(() {
                  config.skillPoints--;
                  _totalPoints++;
                  Navigator.pop(context);
                });
              },
              child: const Text('遗忘'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _createEnemy() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CombatPage(
                player: widget.player,
                enemy: Elemental(
                    baseName: _nameController.text, configs: _configs),
                offensive: true,
              )),
    ).then((_) => widget.player.restoreEnergies());
  }
}

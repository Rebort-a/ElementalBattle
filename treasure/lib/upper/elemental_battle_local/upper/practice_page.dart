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

  final PageController _pageController =
      PageController(initialPage: 2, viewportFraction: 0.6);

  final Map<EnergyType, EnergyConfig> _configs = Elemental.getDefaultConfig();

  int _totalPoints = 30;
  EnergyType _currentEnergy = EnergyType.water;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _configs[_currentEnergy]!;
    final isEnabled = config.aptitude;

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
          _buildPointRegion(),
          _buildNameRegion(),
          _buildEnergyRegion(),
          _buildAttributeRegion(config, isEnabled),
          _buildSkillTreeRegion(config, isEnabled),
        ],
      ),
    );
  }

  Widget _buildPointRegion() => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          '剩余点数: $_totalPoints',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildNameRegion() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '敌人名称',
            border: OutlineInputBorder(),
          ),
        ),
      );

  Widget _buildEnergyRegion() => Container(
        height: 120,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: PageView.custom(
          controller: _pageController,
          onPageChanged: (index) =>
              setState(() => _currentEnergy = EnergyType.values[index]),
          childrenDelegate: SliverChildBuilderDelegate(
            (context, index) => _buildTransformedCard(index),
            childCount: EnergyType.values.length,
          ),
        ),
      );

  Widget _buildTransformedCard(int index) {
    const double scaleFactor = 0.8; // 缩放因子
    Matrix4 matrix = Matrix4.identity();

    // 计算变换效果
    if (index == _currentEnergy.index) {
      // 当前页
      double currScale = 1 - (_currentEnergy.index - index) * (1 - scaleFactor);
      double currTrans = 120.0 * (1 - currScale) / 2;
      matrix = Matrix4.diagonal3Values(1.0, currScale, 1.0)
        ..setTranslationRaw(0.0, currTrans, 0.0);
    } else if (index == _currentEnergy.index + 1) {
      // 下一页
      double currScale =
          scaleFactor + (_currentEnergy.index - index + 1) * (1 - scaleFactor);
      double currTrans = 120.0 * (1 - currScale) / 2;
      matrix = Matrix4.diagonal3Values(1.0, currScale, 1.0)
        ..setTranslationRaw(0.0, currTrans, 0.0);
    } else if (index == _currentEnergy.index - 1) {
      // 上一页
      double currScale = 1 - (_currentEnergy.index - index) * (1 - scaleFactor);
      double currTrans = 120.0 * (1 - currScale) / 2;
      matrix = Matrix4.diagonal3Values(1.0, currScale, 1.0)
        ..setTranslationRaw(0.0, currTrans, 0.0);
    } else {
      // 其他页
      matrix = Matrix4.diagonal3Values(1.0, scaleFactor, 1.0)
        ..setTranslationRaw(0.0, 120.0 * (1 - scaleFactor) / 2, 0.0);
    }

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentEnergy = EnergyType.values[index]);
      },
      child: Transform(
        transform: matrix,
        child: _buildEnergyCard(EnergyType.values[index],
            _configs[EnergyType.values[index]]!.aptitude),
      ),
    );
  }

  Widget _buildEnergyCard(EnergyType type, bool isEnabled) {
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

  Widget _buildAttributeRegion(EnergyConfig config, bool isEnabled) {
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
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isEnabled ? Colors.black : Colors.grey,
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

  Widget _buildSkillTreeRegion(EnergyConfig config, bool isEnabled) {
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

  void _toggleEnergy(EnergyType type) {
    setState(() {
      final config = _configs[type]!;
      final wasEnabled = config.aptitude;
      config.aptitude = !wasEnabled;

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
        config.aptitude = false; // 点数不足，恢复状态
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(skill.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('目标: ${CombatSkill.getTargetText(skill.targetType)}'),
            Text('效果: ${skill.description}'),
          ],
        ),
        actions: [
          if (canLearn)
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

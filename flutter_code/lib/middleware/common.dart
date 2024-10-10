import 'package:flutter/material.dart';

import '../foundation/energy.dart';
import '../foundation/skill.dart';

// 敌人名称
const List<String> enemyNames = ["敌方小弟", "敌方大哥", "敌方长老", "敌方魔王"];

// 战斗结果类型
enum ResultType { continued, victory, defeat, escape, draw }

class AlwaysNotifyValueNotifier<T> extends ValueNotifier<T> {
  AlwaysNotifyValueNotifier(super.value);

  @override
  set value(T newValue) {
    super.value = newValue;
    notifyListeners();
  }
}

class SelectEnergy {
  final BuildContext context;
  final List<Energy> energies;
  final void Function(int) onSelected;
  final bool available;

  SelectEnergy(
      {required this.context,
      required this.energies,
      required this.onSelected,
      required this.available}) {
    _showEnergy(context, energies, onSelected, available);
  }

  _showEnergy(BuildContext context, List<Energy> energies,
      void Function(int) onSelected, bool available) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择一个元素'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(energies.length, (index) {
              Energy energy = energies[index];
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: available
                        ? energy.health > 0
                            ? () {
                                onSelected(index);
                                Navigator.of(context).pop();
                              }
                            : null
                        : () {
                            onSelected(index);
                            Navigator.of(context).pop();
                          },
                    style: ElevatedButton.styleFrom(
                      foregroundColor:
                          energy.health > 0 ? Colors.white : Colors.black,
                      backgroundColor:
                          energy.health > 0 ? Colors.blue : Colors.grey,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: Text(
                        '${energy.name} ${energy.health}/${energy.capacityBase}'),
                  ),
                  const SizedBox(height: 5), // 添加间隙
                ],
              );
            }),
          ),
        );
      },
    );
  }
}

class SelectSkill {
  final BuildContext context;
  final Energy energy;
  final void Function(CombatSkill) handleSkill;
  SelectSkill(
      {required this.context,
      required this.energy,
      required this.handleSkill}) {
    _showSkills(context, energy, handleSkill);
  }

  _showSkills(BuildContext context, Energy energy,
      void Function(CombatSkill) handleSkill) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择一个技能'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: energy.skills
                .asMap()
                .entries
                .where((entry) =>
                    (entry.value.type == SkillType.active) &&
                    entry.value.learned)
                .map((entry) {
              CombatSkill skill = entry.value;
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      handleSkill(skill);
                    },
                    child: Text(skill.name),
                  ),
                  const SizedBox(height: 5), // 添加间隙
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class SnackBarMessage {
  final BuildContext context;
  final String message;
  SnackBarMessage(this.context, this.message) {
    _showSnackBar(context, message);
  }
  _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

class DiaglogMessage {
  final BuildContext context;
  final String title;
  final String content;
  final VoidCallback before;
  final VoidCallback after;
  DiaglogMessage(
      this.context, this.title, this.content, this.before, this.after) {
    _showDialog(context, title, content, before, after);
  }

  _showDialog(BuildContext context, String title, String content,
      VoidCallback before, VoidCallback after) {
    before();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('关闭'),
              onPressed: () {
                Navigator.of(context).pop(); // 关闭对话框
              },
            ),
          ],
        );
      },
    ).then((value) {
      // 对话框关闭后的回调
      after();
    });
  }
}

class UpgradeDialog {
  final BuildContext context;
  final VoidCallback before;
  final VoidCallback after;
  final void Function(int index, AttributeType attribute) upgrade;
  UpgradeDialog(this.context, this.before, this.after, this.upgrade) {
    _showUpgradeDialog(context, before, after, upgrade);
  }

  _showUpgradeDialog(
      BuildContext context,
      VoidCallback before,
      VoidCallback after,
      void Function(int index, AttributeType attribute) upgrade) {
    before();
    int chosenElement = -1; // 初始化为无效值
    AttributeType chosenAttribute = AttributeType.hp; // 初始化为生命值

    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<int> elementsForDialog =
            List.generate(energyNames.length, (index) => index);
        List<int> attributesForDialog =
            List.generate(attributeNames.length, (index) => index);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('选择一个元素:'),
                  ...elementsForDialog.map(
                    (elementIndex) => ListTile(
                      title: Text(
                        energyNames[elementIndex],
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      onTap: () {
                        setState(() {
                          chosenElement = elementIndex;
                        });
                      },
                      trailing: chosenElement == elementIndex
                          ? const Icon(Icons.check)
                          : null,
                      style: chosenElement == elementIndex
                          ? ListTileStyle.drawer
                          : ListTileStyle.list,
                    ),
                  ),
                  const SizedBox(height: 10), // 分隔元素和属性选择
                  if (chosenElement != -1) ...[
                    const Text('选择属性:'),
                    ...attributesForDialog.map(
                      (attributeIndex) => ListTile(
                        title: Text(
                          attributeNames[attributeIndex],
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        onTap: () {
                          setState(() {
                            chosenAttribute =
                                AttributeType.values[attributeIndex];
                          });
                        },
                        trailing: chosenAttribute.index == attributeIndex
                            ? const Icon(Icons.check)
                            : null,
                        style: chosenAttribute.index == attributeIndex
                            ? ListTileStyle.drawer
                            : ListTileStyle.list,
                      ),
                    ),
                  ]
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  onPressed: () {
                    // 如果用户没有选择属性或元素，则不继续执行
                    if (chosenElement == -1) {
                    } else {
                      upgrade(chosenElement, chosenAttribute);
                    }
                    Navigator.of(context).pop(); // 当属性被选择时，允许点击确定
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    ).then((value) {
      // 对话框关闭后的回调
      after();
    });
  }
}

class CustomDirectionButton extends StatefulWidget {
  final Size size;
  final VoidCallback onTap;
  final Widget? icon;
  final Color color;
  final bool enableLongPress;

  const CustomDirectionButton({
    super.key,
    required this.size,
    required this.onTap,
    this.icon,
    this.color = Colors.blue,
    this.enableLongPress = true,
  });

  @override
  State<CustomDirectionButton> createState() => _CustomerDirectionButtonState();
}

class _CustomerDirectionButtonState extends State<CustomDirectionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        setState(() {});
      });
    _animation =
        Tween<double>(begin: 1.0, end: 0.95).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.color,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          _animationController.forward();
          widget.onTap();
        },
        onTapUp: (_) {
          _animationController.reverse();
        },
        onTapCancel: () {
          _animationController.reverse();
        },
        child: Transform.scale(
          scale: _animation.value,
          child: SizedBox.fromSize(size: widget.size),
        ),
      ),
    );
  }
}

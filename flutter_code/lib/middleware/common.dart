import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter/services.dart';

import '../foundation/energy.dart';
import '../foundation/skill.dart';
import 'elemental.dart';

// 战斗结果类型
enum ResultType { continued, victory, defeat, escape, draw }

class AlwaysValueNotifier<T> extends ValueNotifier<T> {
  AlwaysValueNotifier(super.value);

  @override
  set value(T newValue) {
    super.value = newValue;
    notifyListeners();
  }
}

class SelectEnergy {
  final BuildContext context;
  final Elemental elemental;
  final void Function(int) onSelected;
  final bool available;

  SelectEnergy(
      {required this.context,
      required this.elemental,
      required this.onSelected,
      required this.available}) {
    _showEnergy(context, elemental, onSelected, available);
  }

  _showEnergy(BuildContext context, Elemental elemental,
      void Function(int) onSelected, bool available) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择一个灵根'),
          content: Container(
            // 设置最大高度，超过时可滚动
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(elemental.config.length, (index) {
                  // 仅处理enable为true的Energy
                  if (!elemental.isEnable(index)) {
                    return const SizedBox();
                  }

                  String name = elemental.getAppointName(index);
                  int health = elemental.getAppointHealth(index);
                  int capacity = elemental.getAppointCapacity(index);
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: available
                            ? health > 0
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
                              health > 0 ? Colors.white : Colors.black,
                          backgroundColor:
                              health > 0 ? Colors.blue : Colors.grey,
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: Text('$name $health/$capacity'),
                      ),
                      const SizedBox(height: 5), // 添加间隙
                    ],
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SelectSkill {
  final BuildContext context;
  final List<CombatSkill> skills;
  final void Function(CombatSkill) handleSkill;
  SelectSkill(
      {required this.context,
      required this.skills,
      required this.handleSkill}) {
    _showSkillsDialog(context, skills, handleSkill);
  }

  _showSkillsDialog(BuildContext context, List<CombatSkill> skills,
      void Function(CombatSkill) handleSkill) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择一个技能'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: skills
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

class DialogMessage {
  final BuildContext context;
  final String title;
  final String content;
  final bool Function() before;
  final VoidCallback onTap;
  final VoidCallback after;
  DialogMessage(this.context, this.title, this.content, this.before, this.onTap,
      this.after) {
    _showDialog(context, title, content, before, after);
  }

  _showDialog(BuildContext context, String title, String content,
      bool Function() before, VoidCallback after) {
    if (before()) {
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
                  onTap();
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
}

class UpgradeDialog {
  final BuildContext context;
  final bool Function() before;
  final VoidCallback after;
  final void Function(int index, AttributeType attribute) upgrade;

  UpgradeDialog(this.context, this.before, this.after, this.upgrade) {
    _showUpgradeDialog(context, before, after, upgrade);
  }

  _showUpgradeDialog(
      BuildContext context,
      bool Function() before,
      VoidCallback after,
      void Function(int index, AttributeType attribute) upgrade) {
    if (before()) {
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
                content: Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('选择灵根:'),
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
                        const SizedBox(height: 10), // 分隔灵根和属性选择
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
                  ),
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
                      // 如果用户没有选择属性或灵根，则不继续执行
                      if (chosenElement == -1) {
                        // 可以添加提示或日志
                      } else {
                        upgrade(chosenElement, chosenAttribute);
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text('确定'),
                  ),
                ],
              );
            },
          );
        },
      ).then((value) {
        after();
      });
    }
  }
}

class ScaleButton extends StatefulWidget {
  final Size size;
  final VoidCallback onTap;
  final Widget? icon;
  final Color color;
  final bool press;

  const ScaleButton({
    super.key,
    required this.size,
    required this.onTap,
    this.icon,
    this.color = Colors.blue,
    this.press = true,
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(() {
        setState(() {});
      });

    _animation = Tween<double>(begin: 1.0, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _cancelTimer();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      widget.onTap();
      HapticFeedback.mediumImpact();
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    widget.onTap();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    // HapticFeedback.lightImpact();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _onLongPress() {
    if (widget.press) {
      _controller.forward();
      _startTimer();
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (widget.press) {
      _controller.reverse();
      _cancelTimer();
    }
  }

  void _onLongPressUp() {
    if (widget.press) {
      _controller.reverse();
      _cancelTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: _onLongPress,
      onLongPressUp: _onLongPressUp,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: _onLongPressUp,
      child: Transform.scale(
        scale: _animation.value,
        child: Container(
          width: widget.size.width,
          height: widget.size.height,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5), // 阴影颜色
                spreadRadius: 0, // 阴影扩散半径
                blurRadius: 4, // 阴影模糊半径
                offset: const Offset(0, 4), // 阴影偏移量
              ),
            ],
          ),
          child: Center(
            child: widget.icon,
          ),
        ),
      ),
    );
  }
}

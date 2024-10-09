import 'package:flutter/material.dart';
import 'package:flutter_code/foundation/skill.dart';
import 'dart:math';

import '../foundation/energy.dart';
import 'entity.dart';
import 'map.dart';
import 'prop.dart';

// 敌人类型
enum EnemyType { weak, opponent, strong, boss }

// 敌人名称
const List<String> enemyNames = ["敌方小弟", "敌方大哥", "敌方长老", "敌方魔王"];

class EnergyResume {
  final int index;
  final String name;
  final EnergyType type;
  final int health;
  final int capacity;

  EnergyResume({
    required this.index,
    required this.name,
    required this.type,
    required this.health,
    required this.capacity,
  });
}

class RosePreview {
  final ValueNotifier<List<EnergyResume>> resumes = ValueNotifier([]);
  final ValueNotifier<String> name = ValueNotifier("");
  final ValueNotifier<String> element = ValueNotifier("");
  final ValueNotifier<int> health = ValueNotifier(0);
  final ValueNotifier<int> capacity = ValueNotifier(0);
  final ValueNotifier<int> attack = ValueNotifier(0);
  final ValueNotifier<int> defence = ValueNotifier(0);
  late int survival;

  update(List<Energy> energies, int current) {
    survival = 0;

    resumes.value = List.generate(
      energies.length,
      (index) {
        Energy energy = energies[(current + index) % energies.length];
        if (energy.health > 0) {
          survival++;
        }
        return EnergyResume(
          index: index,
          name: energy.name,
          type: energy.type,
          health: energy.health,
          capacity: energy.capacity,
        );
      },
    );

    name.value = energies[current].name;
    element.value = energyNames[energies[current].type.index];
    health.value = energies[current].health;
    capacity.value = energies[current].capacity;
    attack.value = energies[current].attack;
    defence.value = energies[current].defence;
  }
}

class Rose extends MovableEntity {
  final _random = Random();
  final String name;
  final int count;
  int level;
  late final List<Energy> energies;
  late int _current;
  final RosePreview preview = RosePreview();

  Rose({
    required this.name,
    required this.count,
    required this.level,
    required super.id,
    required super.y,
    required super.x,
  }) {
    energies = getEnergy(count); // 根据元素数量初始化元素列表
    _current = _random.nextInt(count); // 当前元素为随机
    updateEnergy();
  }

  int get current => _current;

  List<Energy> getEnergy(int count) {
    // 根据EnergyType创建全部列表
    List<int> allIndexes =
        List.generate(EnergyType.values.length, (index) => index);

    // 打乱索引列表
    allIndexes.shuffle();

    // 截取前count
    List<int> selectedIndexes = allIndexes.sublist(0, count);

    // 重新按照相生顺序排序
    selectedIndexes.sort();

    // 根据索引创建SingleElement列表并
    List<Energy> selectedElements = selectedIndexes
        .map((index) => Energy(
              name: "$name.${energyNames[index]}",
              type: EnergyType.values[index],
            ))
        .toList();

    return selectedElements;
  }

  switchPrevious() {
    for (int i = 0; i < count; i++) {
      _current = (_current + count - 1) % count;
      if (energies[_current].health > 0) {
        break;
      }
    }
    updateEnergy();
  }

  switchNext() {
    for (int i = 0; i < count; i++) {
      _current = (_current + 1) % count;
      if (energies[_current].health > 0) {
        break;
      }
    }
    updateEnergy();
  }

  switchAppoint(int index) {
    if (energies[index].health > 0) {
      _current = index;
      updateEnergy();
    }
  }

  restoreEnergies() {
    for (int i = 0; i < count; i++) {
      energies[i].restoreAttributes();
      energies[i].restoreEffect();
    }
    updateEnergy();
  }

  upgradeEnergy(int index, AttributeType attribute) {
    energies[index].upgradeAttributes(attribute);
    updateEnergy();
  }

  updateEnergy() {
    preview.update(energies, _current);
  }

  recoverHealth(int index, int value) {
    energies[index].recoverHealth(value);
  }

  sufferSkill(int index, CombatSkill skill) {
    energies[index].sufferSkill(skill);
  }
}

class EnemyRose extends Rose {
  EnemyRose(
      {required super.name,
      required super.count,
      required super.level,
      required super.id,
      required super.y,
      required super.x}) {
    _upgradeRandom(level);
  }

  _upgradeRandom(int times) {
    times += 3 * (5 - count);
    for (int i = 0; i < times; i++) {
      int elementIndex = _random.nextInt(count); // 随机选择一个元素
      AttributeType attributeType = AttributeType
          .values[_random.nextInt(AttributeType.values.length)]; // 随机选择一个属性
      upgradeEnergy(elementIndex, attributeType); // 进行升级
    }
  }
}

class PlayerRose extends Rose {
  late final Map<EntityID, MapProp> props;
  late int money;
  late int experience;
  int gained = 0;
  PlayerRose({required super.id, required super.y, required super.x})
      : super(name: "旅行者", count: EnergyType.values.length, level: 2) {
    money = 20;
    experience = 60;
    props = PropCollection.totalItems;
  }

  addExperience(int num) {
    experience += num;
    gained += num;
    if (gained >= 30) {
      gained -= 30;
      level++;
    }
  }
}

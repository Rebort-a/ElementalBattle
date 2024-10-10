import 'package:flutter/material.dart';
import 'dart:math';

import '../foundation/energy.dart';
import '../foundation/entity.dart';
import '../foundation/skill.dart';
import 'map.dart';
import 'prop.dart';

class EnergyResume {
  final EnergyType type;
  final int health;

  EnergyResume({
    required this.type,
    required this.health,
  });
}

class ElementalPreview {
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
          type: energy.type,
          health: energy.health,
        );
      },
    );

    name.value = energies[current].name;
    element.value = energyNames[energies[current].type.index];
    health.value = energies[current].health;
    capacity.value = energies[current].capacityBase;
    attack.value =
        energies[current].attackBase + energies[current].attackOffset;
    defence.value =
        energies[current].defenceBase + energies[current].defenceOffset;
  }
}

class Elemental extends MovableEntity {
  final _random = Random();
  late final List<Energy> energies;
  late int _current;
  final ElementalPreview preview = ElementalPreview();

  int get current => _current;

  final String name;
  final int count;
  int level;

  Elemental({
    required this.name,
    required this.count,
    required this.level,
    required super.id,
    required super.y,
    required super.x,
  }) {
    energies = getEnergy(count); // 根据元素数量初始化元素列表
    _current = _random.nextInt(count); // 当前元素为随机
    updatePreview();
  }

  updatePreview() {
    preview.update(energies, _current);
  }

  List<Energy> getEnergy(int count) {
    if (count > EnergyType.values.length) {
      count = EnergyType.values.length;
    } else if (count < 1) {
      count = 1;
    }

    // 获取全部的EnergyType组建索引数组
    List<int> allIndexes =
        List.generate(EnergyType.values.length, (index) => index);

    // 打乱索引列表
    allIndexes.shuffle();

    // 截取前count
    List<int> selectedIndexes = allIndexes.sublist(0, count);

    // 重新按照相生顺序排序
    selectedIndexes.sort();

    // 根据索引创建列表
    List<Energy> selectedEnergies = selectedIndexes
        .map((index) => Energy(
              name: "$name.${energyNames[index]}",
              type: EnergyType.values[index],
            ))
        .toList();

    return selectedEnergies;
  }

  switchPrevious() {
    for (int i = 0; i < count; i++) {
      _current = (_current + count - 1) % count;
      if (energies[_current].health > 0) {
        break;
      }
    }
    updatePreview();
  }

  switchNext() {
    for (int i = 0; i < count; i++) {
      _current = (_current + 1) % count;
      if (energies[_current].health > 0) {
        break;
      }
    }
    updatePreview();
  }

  switchAppoint(int index) {
    if (energies[index].health > 0) {
      _current = index;
      updatePreview();
    }
  }

  restoreEnergies() {
    for (int i = 0; i < count; i++) {
      energies[i].restoreAttributes();
      energies[i].restoreEffects();
    }
    updatePreview();
  }

  upgradeEnergy(int index, AttributeType attribute) {
    energies[index].upgradeAttributes(attribute);
    updatePreview();
  }

  recoverHealth(int index, int value) {
    energies[index].recoverHealth(value);
    updatePreview();
  }

  sufferSkill(int index, CombatSkill skill) {
    energies[index].sufferSkill(skill);
    updatePreview();
  }

  int battleWith(Elemental enemyElemental, ValueNotifier<String> message) {
    EnergyCombat combat = EnergyCombat(
        source: energies[current],
        target: enemyElemental.energies[enemyElemental.current]);
    combat.battle();
    message.value += combat.message;
    updatePreview();
    enemyElemental.updatePreview();
    return combat.record;
  }
}

class EnemyElemental extends Elemental {
  EnemyElemental(
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

class PlayerElemental extends Elemental {
  late final Map<EntityID, MapProp> props;
  late final Map<EntityID,
          void Function(BuildContext context, void Function(int index) onTap)>
      propsHandler;
  late int money;
  late int experience;
  int gained = 0;
  PlayerElemental({required super.id, required super.y, required super.x})
      : super(name: "旅行者", count: EnergyType.values.length, level: 2) {
    money = 20;
    experience = 60;
    props = PropCollection.totalItems;
    propsHandler = PropCollection.totalItemHandler;
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

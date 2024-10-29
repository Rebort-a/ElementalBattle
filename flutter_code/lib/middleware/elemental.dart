import 'package:flutter/material.dart';
import 'dart:math';

import '../foundation/energy.dart';
import '../foundation/skill.dart';
import '../foundation/map.dart';

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
  final ValueNotifier<String> type = ValueNotifier("");
  final ValueNotifier<int> level = ValueNotifier(0);
  final ValueNotifier<int> health = ValueNotifier(0);
  final ValueNotifier<int> capacity = ValueNotifier(0);
  final ValueNotifier<int> attack = ValueNotifier(0);
  final ValueNotifier<int> defence = ValueNotifier(0);
  final ValueNotifier<double> emoji = ValueNotifier(0);

  void initInfo(List<Energy> energies, int current) {
    updateResumesInfo(energies, current);
    updateCurrentInfo(energies[current]);
  }

  void updateResumesInfo(List<Energy> energies, int current) {
    int survival = 0;

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

    emoji.value =
        (survival / energies.length) * (health.value / capacity.value);
  }

  void updateCurrentInfo(Energy energy) {
    name.value = energy.name;
    type.value = energyNames[energy.type.index];
    level.value = energy.level;
    health.value = energy.health;
    capacity.value = energy.capacityBase + energy.capacityExtra;
    attack.value = energy.attackBase + energy.attackOffset;
    defence.value = energy.defenceBase + energy.defenceOffset;
  }

  void updatePredictedInfo(int attackValue, int defenceValue) {
    attack.value = attackValue;
    defence.value = defenceValue;
  }
}

class Elemental extends MovableEntity {
  final _random = Random();
  late final List<Energy> _energies;
  late int _current;
  final ElementalPreview preview = ElementalPreview();

  int get current => _current;

  final String name;
  final int count;
  int levelTimes;

  Elemental({
    required this.name,
    required this.count,
    required this.levelTimes,
    required super.id,
    required super.y,
    required super.x,
  }) {
    _energies = getEnergy(count); // 根据元素数量初始化元素列表
    _current = _random.nextInt(count); // 当前元素为随机
    preview.initInfo(_energies, _current); // 更新预览
  }

  updatePreview() {
    preview.initInfo(_energies, _current);
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

  void switchPrevious() {
    for (int i = 0; i < count; i++) {
      _current = (_current + count - 1) % count;
      if (_energies[_current].health > 0) {
        break;
      }
    }
    updatePreview();
  }

  void switchNext() {
    for (int i = 0; i < count; i++) {
      _current = (_current + 1) % count;
      if (_energies[_current].health > 0) {
        break;
      }
    }
    updatePreview();
  }

  void switchAppoint(int index) {
    if (_energies[index].health > 0) {
      _current = index;
      updatePreview();
    }
  }

  void restoreEnergies() {
    for (int i = 0; i < count; i++) {
      _energies[i].restoreAttributes();
      _energies[i].restoreEffects();
    }
    updatePreview();
  }

  void upgradeEnergy(int index, AttributeType attribute) {
    _energies[index].upgradeAttributes(attribute);
    updatePreview();
  }

  void recoverHealth(int index, int value) {
    _energies[index].recoverHealth(value);
    updatePreview();
  }

  void sufferSkill(int index, CombatSkill skill) {
    _energies[index].sufferSkill(skill);
    updatePreview();
  }

  void getPassiveEffect() {
    for (var skill in _energies[_current].skills) {
      if ((skill.type == SkillType.passive) && skill.learned) {
        _energies[_current].sufferSkill(skill);
        updatePreview();
      }
    }
  }

  List<CombatSkill> getCurrentSkills() {
    return _energies[_current].skills;
  }

  List<CombatSkill> getAppointSkills(int index) {
    return _energies[index].skills;
  }

  Energy getCurrentEnergy() {
    return _energies[_current];
  }

  Energy getAppointEnergy(int index) {
    return _energies[index];
  }

  int battleWith(
      Elemental elemental, int index, ValueNotifier<String> message) {
    EnergyCombat combat = EnergyCombat(
        source: _energies[current], target: elemental._energies[index]);

    combat.battle();
    message.value += combat.message;
    updatePreview();
    elemental.updatePreview();
    return combat.record;
  }

  void confrontWith(Elemental elemental) {
    int attackValue = EnergyCombat.handleAttackEffect(
        _energies[_current], elemental.getCurrentEnergy(), false);

    int defenceValue = EnergyCombat.handleDefenceEffect(
        elemental.getCurrentEnergy(), _energies[_current], false);

    preview.updatePredictedInfo(attackValue, defenceValue);
  }
}

class EnemyElemental extends Elemental {
  EnemyElemental(
      {required super.name,
      required super.count,
      required super.levelTimes,
      required super.id,
      required super.y,
      required super.x}) {
    _upgradeRandom(levelTimes);
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

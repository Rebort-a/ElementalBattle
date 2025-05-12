import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_code/foundation/effect.dart';

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
  final ValueNotifier<String> name = ValueNotifier("");
  final ValueNotifier<int> type = ValueNotifier(0);
  final ValueNotifier<String> typeString = ValueNotifier("");
  final ValueNotifier<int> level = ValueNotifier(0);
  final ValueNotifier<int> health = ValueNotifier(0);
  final ValueNotifier<int> capacity = ValueNotifier(0);
  final ValueNotifier<int> attack = ValueNotifier(0);
  final ValueNotifier<int> defence = ValueNotifier(0);
  final ValueNotifier<List<EnergyResume>> resumes = ValueNotifier([]);
  final ValueNotifier<double> emoji = ValueNotifier(0);

  void updateInfo(List<Energy> energies, int current) {
    _updateCurrentInfo(energies[current]);
    _updateResumesInfo(energies, current);
  }

  void _updateResumesInfo(List<Energy> energies, int current) {
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

  void _updateCurrentInfo(Energy energy) {
    name.value = energy.name;
    type.value = energy.type.index;
    typeString.value = energyNames[energy.type.index];
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
  final ElementalPreview preview = ElementalPreview();
  final _random = Random();
  late final List<Energy> _energies;
  late int _current;

  int get current => _current;

  String getCurrentName() {
    return _energies[_current].name;
  }

  String getAppointName(int index) {
    return _energies[index].name;
  }

  int getAppointLevel(int index) {
    return _energies[index].level;
  }

  EnergyType getCurrentType() {
    return _energies[_current].type;
  }

  String getAppointTypeString(int index) {
    return energyNames[_energies[index].type.index];
  }

  int getAppointHealth(int index) {
    return _energies[index].health;
  }

  int getAppointCapacity(int index) {
    return _energies[index].capacityBase;
  }

  int getAppointAttackBase(int index) {
    return _energies[index].attackBase;
  }

  int getAppointDefenceBase(int index) {
    return _energies[index].defenceBase;
  }

  int getAppointAttack(int index) {
    return _energies[index].attackBase + _energies[index].attackOffset;
  }

  int getAppointDefence(int index) {
    return _energies[index].defenceBase + _energies[index].defenceOffset;
  }

  List<CombatSkill> getCurrentSkills() {
    return _energies[_current].skills;
  }

  List<CombatSkill> getAppointSkills(int index) {
    return _energies[index].skills;
  }

  List<CombatEffect> getAppointEffects(int index) {
    return _energies[index].effects;
  }

  final String name;
  final int count;
  int upgradeTimes;

  Elemental({
    required this.name,
    required this.count,
    required this.upgradeTimes,
    required super.id,
    required super.y,
    required super.x,
  }) {
    _energies = _getRandomEnergies(count); // 根据灵根数量初始化灵根列表
    _current = _random.nextInt(count); // 当前灵根为随机
    _updatePreview();
  }

  List<Energy> _getRandomEnergies(int count) {
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

  void _updatePreview() {
    preview.updateInfo(_energies, _current); // 更新预览
  }

  void switchPrevious() {
    for (int i = 0; i < count; i++) {
      _current = (_current + count - 1) % count;
      if (_energies[_current].health > 0) {
        break;
      }
    }
    _updatePreview();
  }

  void switchNext() {
    for (int i = 0; i < count; i++) {
      _current = (_current + 1) % count;
      if (_energies[_current].health > 0) {
        break;
      }
    }
    _updatePreview();
  }

  void switchAppoint(int index) {
    if (_energies[index].health > 0) {
      _current = index;
      _updatePreview();
    }
  }

  void restoreEnergies() {
    for (Energy energy in _energies) {
      energy.restoreAttributes();
      energy.restoreEffects();
    }

    _updatePreview();
  }

  void upgradeEnergy(int index, AttributeType attribute) {
    _energies[index].upgradeAttributes(attribute);
    _updatePreview();
  }

  void recoverEnergy(int index, int value) {
    _energies[index].recoverHealth(value);
    _updatePreview();
  }

  void sufferSkill(int index, CombatSkill skill) {
    _energies[index].sufferSkill(skill);
    _updatePreview();
  }

  void applyPassiveEffect() {
    for (Energy energy in _energies) {
      energy.applyPassiveEffect();
    }

    _updatePreview();
  }

  int confrontReply(int Function(Energy) handler) {
    return handler(_energies[_current]);
  }

  void confrontRequest(Elemental elemental) {
    int attackValue = elemental.confrontReply((energy) {
      return EnergyCombat.handleAttackEffect(
          _energies[_current], energy, false);
    });

    int defenceValue = elemental.confrontReply((energy) {
      return EnergyCombat.handleDefenceEffect(
          energy, _energies[_current], false);
    });

    preview.updatePredictedInfo(attackValue, defenceValue);
  }

  EnergyCombat battleReply(int index, EnergyCombat Function(Energy) handler) {
    EnergyCombat combat = handler(_energies[index]);
    combat.battle();
    _updatePreview();
    return combat;
  }

  int battleRequest(
      Elemental elemental, int index, ValueNotifier<String> message) {
    EnergyCombat combat = elemental.battleReply(index, (energy) {
      return EnergyCombat(source: _energies[_current], target: energy);
    });

    _updatePreview();
    message.value += combat.message;
    return combat.record;
  }
}

class EnemyElemental extends Elemental {
  EnemyElemental(
      {required super.name,
      required super.count,
      required super.upgradeTimes,
      required super.id,
      required super.y,
      required super.x}) {
    _upgradeRandom(upgradeTimes);
  }

  _upgradeRandom(int times) {
    times += 3 * (5 - count);
    for (int i = 0; i < times; i++) {
      int elementIndex = _random.nextInt(count); // 随机选择一个灵根
      AttributeType attributeType = AttributeType
          .values[_random.nextInt(AttributeType.values.length)]; // 随机选择一个属性
      upgradeEnergy(elementIndex, attributeType); // 进行升级
    }
  }
}

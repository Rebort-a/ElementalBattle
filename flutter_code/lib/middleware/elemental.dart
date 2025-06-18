import 'dart:math';

import 'package:flutter/material.dart';

import '../foundation/effect.dart';
import '../foundation/energy.dart';
import '../foundation/entity.dart';
import '../foundation/map.dart';
import '../foundation/skill.dart';

mixin EnergyConfigMixin {
  bool energySwitch = true;
  int healthPoints = 0;
  int attackPoints = 0;
  int defencePoints = 0;
  int skillPoints = 1;
}

class EnergyConfig with EnergyConfigMixin {
  EnergyConfig({
    bool? energySwitch,
    int? healthPoints,
    int? attackPoints,
    int? defencePoints,
    int? skillPoints,
  }) {
    this.energySwitch = energySwitch ?? this.energySwitch;
    this.healthPoints = healthPoints ?? this.healthPoints;
    this.attackPoints = attackPoints ?? this.attackPoints;
    this.defencePoints = defencePoints ?? this.defencePoints;
    this.skillPoints = skillPoints ?? this.skillPoints;
  }
}

class EnergyManager extends Energy with EnergyConfigMixin {
  EnergyManager({required super.type, required String baseName})
      : super(name: '$baseName.${energyNames[type.index]}') {
    _applyConfig();
  }

  void _applyConfig() {
    void applyPoints(AttributeType type, int count) {
      for (int i = 0; i < count; i++) {
        upgradeAttributes(type);
      }
    }

    applyPoints(AttributeType.hp, healthPoints);
    applyPoints(AttributeType.atk, attackPoints);
    applyPoints(AttributeType.def, defencePoints);

    for (int i = 0; i < skillPoints; i++) {
      learnSkill(i);
    }
  }

  void _updateAttribute(AttributeType type, int value) {
    final diff = value - _getCurrentValue(type);
    if (diff > 0) {
      for (int i = 0; i < diff; i++) {
        upgradeAttributes(type);
      }
    }
  }

  int _getCurrentValue(AttributeType type) {
    return switch (type) {
      AttributeType.hp => healthPoints,
      AttributeType.atk => attackPoints,
      AttributeType.def => defencePoints,
    };
  }

  @override
  set healthPoints(int value) => _updateAttribute(AttributeType.hp, value);

  @override
  set attackPoints(int value) => _updateAttribute(AttributeType.atk, value);

  @override
  set defencePoints(int value) => _updateAttribute(AttributeType.def, value);

  @override
  set skillPoints(int value) {
    if (value > skillPoints) {
      for (int i = skillPoints; i < value; i++) {
        learnSkill(i);
      }
    }
    super.skillPoints = value;
  }
}

class EnergyResume {
  final EnergyType type;
  final int health;

  const EnergyResume({required this.type, required this.health});
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

  void updateInfo(Map<EnergyType, EnergyManager> strategy, EnergyType current) {
    _updateCurrentInfo(strategy[current]!);
    _updateResumesInfo(strategy, current);
  }

  void _updateResumesInfo(
      Map<EnergyType, EnergyManager> strategy, EnergyType current) {
    final enabledTypes = strategy.entries
        .where((e) => e.value.energySwitch)
        .map((e) => e.key)
        .toList();

    if (enabledTypes.isEmpty) {
      resumes.value = [];
      emoji.value = 0;
      return;
    }

    final startIndex = enabledTypes.indexOf(current);
    resumes.value = List.generate(
      enabledTypes.length,
      (i) {
        final type = enabledTypes[(startIndex + i) % enabledTypes.length];
        return EnergyResume(type: type, health: strategy[type]!.health);
      },
    );

    final survivalCount = resumes.value.where((r) => r.health > 0).length;
    final healthValue = health.value;
    final capacityValue = capacity.value;

    emoji.value = (capacityValue > 0 && enabledTypes.isNotEmpty)
        ? (survivalCount / enabledTypes.length) * (healthValue / capacityValue)
        : 0;
  }

  void _updateCurrentInfo(Energy energy) {
    name.value = energy.name;
    type.value = energy.type.index;
    typeString.value = energyNames[energy.type.index];
    level.value = energy.level;
    health.value = energy.health;
    capacity.value = energy.capacityTotal;
    attack.value = energy.attackTotal;
    defence.value = energy.defenceTotal;
  }

  void updatePredictedInfo(int attackValue, int defenceValue) {
    attack.value = attackValue;
    defence.value = defenceValue;
  }
}

class Elemental {
  final ElementalPreview preview = ElementalPreview();
  final String baseName;
  final Map<EnergyType, EnergyConfig> config;
  late final Map<EnergyType, EnergyManager> _strategy;
  late int _current;

  static Map<EnergyType, EnergyConfig> getDefaultConfig({
    bool? energySwitch,
    int? healthPoints,
    int? attackPoints,
    int? defencePoints,
    int? skillPoints,
  }) {
    return Map.fromEntries(
      EnergyType.values.map(
        (t) => MapEntry(
          t,
          EnergyConfig(
            energySwitch: energySwitch,
            healthPoints: healthPoints,
            attackPoints: attackPoints,
            defencePoints: defencePoints,
            skillPoints: skillPoints,
          ),
        ),
      ),
    );
  }

  Elemental({required this.baseName, required this.config}) {
    _initStrategy();
    _initCurrent();
  }

  void _initStrategy() {
    _strategy = Map.fromEntries(config.entries.map((e) {
      final manager = EnergyManager(type: e.key, baseName: baseName)
        ..energySwitch = e.value.energySwitch
        ..healthPoints = e.value.healthPoints
        ..attackPoints = e.value.attackPoints
        ..defencePoints = e.value.defencePoints
        ..skillPoints = e.value.skillPoints;
      return MapEntry(e.key, manager);
    }));
  }

  void _initCurrent() {
    _current = Random().nextInt(EnergyType.values.length);
    switchPrevious();
  }

  EnergyManager _energyAt(int index) => _strategy[EnergyType.values[index]]!;

  int get current => _current;

  int findNextIndex(int start, int step) {
    final count = EnergyType.values.length;
    for (int i = 1; i <= count; i++) {
      final index = (start + step * i) % count;
      final energy = _energyAt(index);
      if (energy.energySwitch && energy.health > 0) return index;
    }
    return _current;
  }

  void switchPrevious() => switchAppoint(findNextIndex(_current, -1));
  void switchNext() => switchAppoint(findNextIndex(_current, 1));

  void switchAppoint(int index) {
    if (index != _current) {
      _current = index;
      _updatePreview();
    }
  }

  bool isEnable(int index) => _energyAt(index).energySwitch;
  String getAppointName(int index) => _energyAt(index).name;
  int getAppointLevel(int index) => _energyAt(index).level;
  int getAppointCapacity(int index) => _energyAt(index).capacityBase;
  int getAppointAttackBase(int index) => _energyAt(index).attackBase;
  int getAppointDefenceBase(int index) => _energyAt(index).defenceBase;
  int getAppointHealth(int index) => _energyAt(index).health;
  int getAppointAttack(int index) => _energyAt(index).attackTotal;
  int getAppointDefence(int index) => _energyAt(index).defenceTotal;
  String getAppointTypeString(int index) => energyNames[index];

  List<CombatSkill> getAppointSkills(int index) => _energyAt(index).skills;
  List<CombatEffect> getAppointEffects(int index) => _energyAt(index).effects;

  void restoreEnergies() {
    for (Energy e in _strategy.values) {
      e.restoreAttributes();
      e.restoreEffects();
    }
    _updatePreview();
  }

  void upgradeEnergy(int index, AttributeType attribute) {
    switch (attribute) {
      case AttributeType.hp:
        _energyAt(index).healthPoints++;
      case AttributeType.atk:
        _energyAt(index).attackPoints++;
      case AttributeType.def:
        _energyAt(index).defencePoints++;
    }
    _updatePreview();
  }

  void upgradeSkill(int index) => _energyAt(index).skillPoints++;

  void recoverEnergy(int index, int value) {
    _energyAt(index).recoverHealth(value);
    _updatePreview();
  }

  void sufferSkill(int index, CombatSkill skill) {
    _energyAt(index).sufferSkill(skill);
    _updatePreview();
  }

  void applyPassiveEffect() {
    for (Energy e in _strategy.values) {
      e.applyPassiveEffect();
    }
    _updatePreview();
  }

  int confrontReply(int Function(EnergyManager) handler) =>
      handler(_energyAt(_current));

  void confrontRequest(Elemental elemental) {
    final attackValue = elemental.confrontReply(
        (e) => EnergyCombat.handleAttackEffect(_energyAt(_current), e, false));

    final defenceValue = elemental.confrontReply(
        (e) => EnergyCombat.handleDefenceEffect(e, _energyAt(_current), false));

    preview.updatePredictedInfo(attackValue, defenceValue);
  }

  EnergyCombat battleReply(
      int index, EnergyCombat Function(EnergyManager) handler) {
    final combat = handler(_energyAt(index));
    combat.execute();
    _updatePreview();
    return combat;
  }

  int battleRequest(
      Elemental elemental, int index, ValueNotifier<String> message) {
    final combat = elemental.battleReply(
        index, (e) => EnergyCombat(source: _energyAt(_current), target: e));

    _updatePreview();
    message.value += combat.message;
    return combat.record;
  }

  void _updatePreview() =>
      preview.updateInfo(_strategy, EnergyType.values[_current]);
}

class ElementalEntity extends Elemental with MovableEntity {
  ElementalEntity({
    required super.baseName,
    required super.config,
    required EntityID id,
    required int y,
    required int x,
  }) {
    this.id = id;
    this.y = y;
    this.x = x;
  }
}

class RandomEnemy extends ElementalEntity {
  static const enemyNames = ["小鬼", "小丑", "恶魔", "鬼王"];

  final int grade;

  RandomEnemy._({
    required super.baseName,
    required super.config,
    required super.id,
    required super.y,
    required super.x,
    required this.grade,
  });

  factory RandomEnemy.generate({
    required EntityID id,
    required int y,
    required int x,
    required int grade,
  }) {
    final typeIndex = Random().nextInt(enemyNames.length - 1);
    final baseName = enemyNames[typeIndex];
    final config = _generateRandomConfig(grade + typeIndex);

    return RandomEnemy._(
      id: id,
      y: y,
      x: x,
      baseName: baseName,
      config: config,
      grade: grade,
    );
  }

  static Map<EnergyType, EnergyConfig> _generateRandomConfig(
      int upgradePoints) {
    final configs = Elemental.getDefaultConfig(skillPoints: 2);
    final random = Random();
    final types = List.of(EnergyType.values);

    // 随机禁用部分灵根
    types.shuffle();
    final disableCount = random.nextInt(5);
    types.take(disableCount).forEach((t) {
      configs[t]!.energySwitch = false;
      upgradePoints += 3;
    });

    // 分配点数到启用的灵根
    final enabledTypes = types.skip(disableCount).toList();
    final pointsPerType =
        _distributePoints(enabledTypes.length, upgradePoints, random);

    // 分配属性点
    for (int i = 0; i < enabledTypes.length; i++) {
      final config = configs[enabledTypes[i]]!;
      final points = pointsPerType[i];
      _allocateAttributes(config, points, random);
    }

    return configs;
  }

  static List<int> _distributePoints(int count, int total, Random random) {
    final points = List.filled(count, 0);
    for (int i = 0; i < total; i++) {
      points[random.nextInt(count)]++;
    }
    return points;
  }

  static void _allocateAttributes(
      EnergyConfig config, int points, Random random) {
    final attributes = [
      () => config.healthPoints++,
      () => config.attackPoints++,
      () => config.defencePoints++,
    ];

    for (int i = 0; i < points; i++) {
      attributes[random.nextInt(attributes.length)]();
    }
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';

import '../foundation/effect.dart';
import '../foundation/energy.dart';
import '../foundation/skill.dart';

mixin EnergyConfigMixin {
  bool aptitude = true;
  int healthPoints = 0;
  int attackPoints = 0;
  int defencePoints = 0;
  int skillPoints = 0;
}

class EnergyConfig with EnergyConfigMixin {
  EnergyConfig({
    bool? aptitude,
    int? healthPoints,
    int? attackPoints,
    int? defencePoints,
    int? skillPoints,
  }) {
    this.aptitude = aptitude ?? true;
    this.healthPoints = healthPoints ?? 0;
    this.attackPoints = attackPoints ?? 0;
    this.defencePoints = defencePoints ?? 0;
    this.skillPoints = skillPoints ?? 1;
  }
}

class EnergyManager extends Energy with EnergyConfigMixin {
  EnergyManager({required super.type, required String baseName})
      : super(name: '$baseName.${energyNames[type.index]}');

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

  void _updateCurrentInfo(Energy energy) {
    name.value = energy.name;
    type.value = energy.typeIndex;
    typeString.value = energyNames[energy.typeIndex];
    level.value = energy.level;
    health.value = energy.health;
    capacity.value = energy.capacityTotal;
    attack.value = energy.attackTotal;
    defence.value = energy.defenceTotal;
  }

  void _updateResumesInfo(
      Map<EnergyType, EnergyManager> strategy, EnergyType current) {
    final enabledTypes = strategy.entries
        .where((e) => e.value.aptitude)
        .map((e) => e.key)
        .toList();

    // 按照五行相生顺序排列启用的灵根
    final orderedTypes = _arrangeByGenerationOrder(enabledTypes, current);

    resumes.value = List.generate(
      orderedTypes.length,
      (i) {
        final type = orderedTypes[i];
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

  // 按照五行相生顺序排列灵根
  List<EnergyType> _arrangeByGenerationOrder(
      List<EnergyType> enabledTypes, EnergyType startType) {
    final orderedTypes = <EnergyType>[];
    EnergyType currentType = startType;
    int count = 0;

    // 最多遍历五行灵根数量次
    while (orderedTypes.length < enabledTypes.length &&
        count < EnergyType.values.length) {
      // 如果当前灵根是启用的，添加到有序列表
      if (enabledTypes.contains(currentType)) {
        orderedTypes.add(currentType);
      }

      // 按五行相生顺序获取下一个灵根
      currentType = Elemental.generationOrder[currentType]!;
      count++;
    }

    return orderedTypes;
  }

  void updatePredictedInfo(int attackValue, int defenceValue) {
    attack.value = attackValue;
    defence.value = defenceValue;
  }
}

class Elemental {
  final ElementalPreview preview = ElementalPreview();
  late final Map<EnergyType, EnergyManager> _strategy;

  late String _baseName;
  late int _current;

  Elemental({
    required String baseName,
    required Map<EnergyType, EnergyConfig> configs,
    required int current,
  }) {
    _initElemental(baseName, configs, current);
  }

  void _initElemental(
      String baseName, Map<EnergyType, EnergyConfig> configs, int current) {
    _baseName = baseName;
    _strategy = createStrategyFromConfigs(baseName, configs);
    _current = current;
    switchPrevious();
  }

  // 从配置创建策略（EnergyManager映射）
  static Map<EnergyType, EnergyManager> createStrategyFromConfigs(
      String baseName, Map<EnergyType, EnergyConfig> configs) {
    return Map.fromEntries(configs.entries.map((e) {
      final manager = EnergyManager(type: e.key, baseName: baseName)
        ..aptitude = e.value.aptitude
        ..healthPoints = e.value.healthPoints
        ..attackPoints = e.value.attackPoints
        ..defencePoints = e.value.defencePoints
        ..skillPoints = e.value.skillPoints;
      return MapEntry(e.key, manager);
    }));
  }

  // 从策略创建配置（反向转换函数）
  static Map<EnergyType, EnergyConfig> createConfigsFromStrategy(
      Map<EnergyType, EnergyManager> strategy) {
    return Map.fromEntries(strategy.entries.map((e) {
      return MapEntry(
          e.key,
          EnergyConfig(
            aptitude: e.value.aptitude,
            healthPoints: e.value.healthPoints,
            attackPoints: e.value.attackPoints,
            defencePoints: e.value.defencePoints,
            skillPoints: e.value.skillPoints,
          ));
    }));
  }

  EnergyManager _energyAt(int index) => _strategy[EnergyType.values[index]]!;

  int get current => _current;

  void switchPrevious() => switchAppoint(findAvailableIndex(_current, -1));
  void switchNext() => switchAppoint(findAvailableIndex(_current, 1));

  void switchAppoint(int index) {
    if (index != _current) {
      _current = index;
      _updatePreview();
    }
  }

  int findAvailableIndex(int start, int step) {
    final count = EnergyType.values.length;
    for (int i = 1; i <= count; i++) {
      final index = (start + step * i) % count;
      final energy = _energyAt(index);
      if (energy.aptitude) return index;
    }
    return _current;
  }

  // 根据五行相生顺序切换到下一个有效灵根
  void switchAliveByOrder() {
    EnergyType currentType = EnergyType.values[_current];

    for (int i = 1; i < EnergyType.values.length; i++) {
      currentType = generationOrder[currentType]!;

      // 检查下一个灵根是否有效
      if (_strategy[currentType]!.aptitude &&
          _strategy[currentType]!.health > 0) {
        switchAppoint(currentType.index);
        break;
      }
    }
  }

  // 五行相生的映射表，key为当前元素，value为相生顺序的下一个元素
  static Map<EnergyType, EnergyType> generationOrder = {
    EnergyType.metal: EnergyType.water, // 金生水
    EnergyType.water: EnergyType.wood, // 水生木
    EnergyType.wood: EnergyType.fire, // 木生火
    EnergyType.fire: EnergyType.earth, // 火生土
    EnergyType.earth: EnergyType.metal, // 土生金
  };

  String get name => _baseName;

  String getAppointName(int index) => _energyAt(index).name;
  bool getAppointAptitude(int index) => _energyAt(index).aptitude;
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

  void updateAllNames(String newName) {
    _baseName = newName;
    for (EnergyType type in EnergyType.values) {
      _energyAt(type.index).changeName('$_baseName.${energyNames[type.index]}');
    }
    _updatePreview();
  }

  void restoreAllAttributesAndEffects() {
    for (Energy e in _strategy.values) {
      e.restoreAttributes();
      e.restoreEffects();
    }
    _updatePreview();
  }

  void upgradeAppointAttribute(int index, AttributeType attribute) {
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

  void upgradeAppointSkill(int index) => _energyAt(index).skillPoints++;

  void recoverAppoint(int index, int value) {
    _energyAt(index).recoverHealth(value);
    _updatePreview();
  }

  void applyAllPassiveEffect() {
    for (Energy e in _strategy.values) {
      e.applyPassiveEffect();
    }
    _updatePreview();
  }

  void appointSufferSkill(int index, CombatSkill skill) {
    _energyAt(index).sufferSkill(skill);
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

  EnergyCombat comabtReply(
      int index, EnergyCombat Function(EnergyManager) handler) {
    final combat = handler(_energyAt(index));
    combat.execute();
    _updatePreview();
    return combat;
  }

  int combatRequest(
      Elemental elemental, int index, ValueNotifier<String> message) {
    final combat = elemental.comabtReply(
        index, (e) => EnergyCombat(source: _energyAt(_current), target: e));

    _updatePreview();
    message.value += combat.message;
    return combat.record;
  }

  void _updatePreview() =>
      preview.updateInfo(_strategy, EnergyType.values[_current]);

  // 将配置转化为JSON
  static Map<String, dynamic> configsToJson(
      String baseName, Map<EnergyType, EnergyConfig> configs, int current) {
    return {
      'baseName': baseName,
      'configs': configs.map((key, value) => MapEntry(
            key.toString().split('.').last,
            {
              'aptitude': value.aptitude,
              'healthPoints': value.healthPoints,
              'attackPoints': value.attackPoints,
              'defencePoints': value.defencePoints,
              'skillPoints': value.skillPoints,
            },
          )),
      'current': current,
    };
  }

  static String baseNameFromJson(Map<String, dynamic> json) => json['baseName'];

  static Map<EnergyType, EnergyConfig> configsFromJson(
      Map<String, dynamic> json) {
    return Map<EnergyType, EnergyConfig>.from(
      (json['configs'] as Map<String, dynamic>).map((key, value) {
        return MapEntry(
          EnergyType.values.firstWhere(
              (e) => e.toString().split('.').last == key,
              orElse: () => throw Exception('Invalid energy type: $key')),
          EnergyConfig(
            aptitude: value['aptitude'] as bool,
            healthPoints: value['healthPoints'] as int,
            attackPoints: value['attackPoints'] as int,
            defencePoints: value['defencePoints'] as int,
            skillPoints: value['skillPoints'] as int,
          ),
        );
      }),
    );
  }

  static int currentFromJson(Map<String, dynamic> json) => json['current'];

  factory Elemental.fromJson(Map<String, dynamic> json) {
    final String baseName = Elemental.baseNameFromJson(json);
    final Map<EnergyType, EnergyConfig> configs =
        Elemental.configsFromJson(json);
    final int current = Elemental.currentFromJson(json);
    return Elemental(
      baseName: baseName,
      configs: configs,
      current: current,
    );
  }

  factory Elemental.fromSocket(List<int> data) {
    return Elemental.fromJson(jsonDecode(utf8.decode(data)));
  }

  List<int> toSocketData() {
    return utf8.encode(jsonEncode(
        configsToJson(name, createConfigsFromStrategy(_strategy), _current)));
  }

  // 默认配置
  static Map<EnergyType, EnergyConfig> getDefaultConfig({
    bool? aptitude,
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
            aptitude: aptitude,
            healthPoints: healthPoints,
            attackPoints: attackPoints,
            defencePoints: defencePoints,
            skillPoints: skillPoints,
          ),
        ),
      ),
    );
  }
}

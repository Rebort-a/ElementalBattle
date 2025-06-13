import 'dart:math';

import 'effect.dart';
import 'skill.dart';

// 灵根：特征，体系，潜力的统称（实在找不到更合适的单词[允悲]），灵根拥有独立的属性，技能和效果

// 五灵根枚举类型，按照相生顺序排列
enum EnergyType { metal, water, wood, fire, earth }

// 五灵根名称
const List<String> energyNames = ["🔩", "🌊", "🪵", "🔥", "🪨"];

// 属性枚举类型
enum AttributeType { hp, atk, def }

// 属性名称
const List<String> attributeNames = ["❤️", "⚔️", "🛡️"];

// 灵根类
class Energy {
  late int _health; // 血量

  late int _capacityBase; // 上限
  late int _capacityExtra; // 额外上限

  late int _attackBase; // 基础攻击
  late int _attackOffset; // 攻击力偏移

  late int _defenceBase; // 基础防御
  late int _defenceOffset; // 防御力偏移

  late final List<CombatSkill> _skills; // 技能列表

  late final List<CombatEffect> _effects; // 效果列表

  int _level = 0;

  // 初始数值
  static final List<List<int>> _baseAttributes = [
    [128, 32, 32], // metal
    [160, 16, 64], // water
    [256, 32, 16], // wood
    [96, 64, 16], // fire
    [384, 16, 0] // earth
  ];

  int get health => _health;

  int get capacityBase => _capacityBase;
  int get capacityExtra => _capacityExtra;

  int get attackBase => _attackBase;
  int get attackOffset => _attackOffset;

  int get defenceBase => _defenceBase;
  int get defenceOffset => _defenceOffset;

  List<CombatSkill> get skills => _skills;

  List<CombatEffect> get effects => _effects;

  int get level => _level;

  int _addHealth(int value) {
    _health += value;
    if (_health > (_capacityBase + _capacityExtra)) {
      value -= _health - (_capacityBase + _capacityExtra);
      _health = (_capacityBase + _capacityExtra);
    }
    return value;
  }

  int _reduceHealth(int value) {
    _health -= value;
    if (_health < 0) {
      value += _health;
      _health = 0;
    }
    return value;
  }

  void changeCapacityExtra(int value) {
    _capacityExtra += value;
    if (_capacityExtra < 0) {
      _capacityExtra = 0;
    } else if (_capacityExtra > _capacityBase) {
      _capacityExtra = _capacityBase;
    }
  }

  void changeAttackOffset(int value) {
    if (_health == (_capacityBase + _capacityExtra)) {
      _attackOffset = 0;
    } else {
      _attackOffset += value;
    }
  }

  void changeDefenceOffset(int value) {
    if (_health == (_capacityBase + _capacityExtra)) {
      _defenceOffset = 0;
    } else {
      _defenceOffset += value;
    }
  }

  final String name;
  final EnergyType type;

  Energy({
    required this.name,
    required this.type,
  }) {
    _initAttributes();
    _initSkills();
    _initEffects();
  }

  // 从列表中获取初始属性
  void _initAttributes() {
    _capacityBase = _baseAttributes[type.index][AttributeType.hp.index];
    _attackBase = _baseAttributes[type.index][AttributeType.atk.index];
    _defenceBase = _baseAttributes[type.index][AttributeType.def.index];

    restoreAttributes();
  }

  // 清空技能，并将可学习技能列表的第一个技能作为初始技能
  void _initSkills() {
    // 长度为本属性所有可用技能
    _skills =
        List.generate(SkillCollection.totalSkills[type.index].length, (index) {
      return SkillCollection.totalSkills[type.index][index].copyWith();
    });

    // 默认学习第一个技能
    _skills[0].learned = true;
  }

  // 清空效果
  void _initEffects() {
    // 长度为所有效果，方便战斗时核查
    _effects = List.generate(EffectID.values.length, (index) {
      return CombatEffect(
        id: EffectID.values[index],
        type: EffectType.limited,
        value: 0,
        times: 0,
      );
    });
  }

  // 还原影响
  void restoreEffects() {
    for (int i = 0; i < _effects.length; i++) {
      _effects[i] = CombatEffect(
        id: EffectID.values[i],
        type: EffectType.limited,
        value: 0,
        times: 0,
      );
    }
  }

  // 还原属性
  void restoreAttributes() {
    _capacityExtra = 0; // 清除额外上限
    _attackOffset = 0; // 清除偏移
    _defenceOffset = 0;
    _health = capacityBase; // 恢复血量到上限
  }

  // 回复生命
  int recoverHealth(int value) {
    return EnergyCombat.handleRecoverHealth(this, value, _addHealth);
  }

  // 扣除生命
  int deductHealth(int value, bool damageType) {
    return EnergyCombat.handleDeductHealth(
        this, value, damageType, _reduceHealth);
  }

  // 升级属性
  void upgradeAttributes(AttributeType attribute) {
    switch (attribute) {
      case AttributeType.hp:
        _capacityBase += 32;
        recoverHealth(32);
        _level++;
        break;
      case AttributeType.atk:
        _attackBase += 8;
        _level++;
        break;
      case AttributeType.def:
        _defenceBase += 8;
        _level++;
        break;
    }
  }

  // 学习技能
  void learnSkill(int index) {
    if (index < _skills.length) {
      _skills[index].learned = true;
      _level++;
    }
  }

  // 遭受技能
  void sufferSkill(CombatSkill skill) {
    skill.handler(skills, effects);
  }

  // 施加被动技能影响
  void applyPassiveEffect() {
    for (CombatSkill skill in _skills) {
      if (skill.learned) {
        if (skill.type == SkillType.passive) {
          if (skill.targetType == SkillTarget.selfFront) {
            sufferSkill(skill);
          }
        }
      } else {
        break;
      }
    }
  }

  CombatEffect getEffect(EffectID id) {
    return _effects[id.index];
  }
}

class EnergyCombat {
  final Energy source;
  final Energy target;
  String message = "";
  int record = 0;

  EnergyCombat({required this.source, required this.target});

  void battle() {
    record = _handleCombat(source, target);
  }

  static int handleAttackEffect(Energy attacker, Energy defender, bool expend) {
    int attack = attacker.attackBase + attacker.attackOffset;
    CombatEffect effect;

    effect = attacker.getEffect(EffectID.giantKiller);
    if (expend ? effect.expend() : effect.check()) {
      attack += (defender.health * effect.value).round();
    }

    effect = attacker.getEffect(EffectID.strengthen);
    if (expend ? effect.expend() : effect.check()) {
      attack += (attack * effect.value).round();
    }

    effect = attacker.getEffect(EffectID.weakenAttack);
    if (expend ? effect.expend() : effect.check()) {
      attack -= (attack * effect.value).round();
    }
    return attack;
  }

  static int handleDefenceEffect(
      Energy attacker, Energy defender, bool expend) {
    int defence = defender.defenceBase + defender.defenceOffset;
    CombatEffect effect;

    effect = defender.getEffect(EffectID.strengthen);
    if (expend ? effect.expend() : effect.check()) {
      defence += (defence * effect.value).round();
    }

    effect = defender.getEffect(EffectID.weakenDefence);
    if (expend ? effect.expend() : effect.check()) {
      defence -= (defence * effect.value).round();
    }

    return defence;
  }

  double _handleCoeffcientEffect(Energy attacker, Energy defender) {
    double coeff = 1.0;

    CombatEffect effect;

    effect = attacker.getEffect(EffectID.sacrificing);
    if (effect.expend()) {
      int deduction = attacker.health - effect.value.round();

      double increaseCoeff = deduction / attacker.capacityBase;

      coeff *= (1 + increaseCoeff);

      attacker.deductHealth(deduction, true);

      message +=
          ('${attacker.name} 对自身造成 $deduction ⚡法术伤害，伤害系数提高 ${(increaseCoeff * 100).toStringAsFixed(0)}% ， 当前生命值为 ${attacker.health}\n');
    }

    effect = attacker.getEffect(EffectID.coeffcient);
    if (effect.expend()) {
      coeff *= (1 + effect.value);
      if (!effect.check()) {
        effect.value = 0;
      }
    }

    effect = defender.getEffect(EffectID.parryState);
    if (effect.expend()) {
      coeff *= (1 - effect.value);
    }

    return coeff;
  }

  double _handleEnchantRatio(Energy attacker, Energy defender) {
    double enchantRatio = 0.0;

    CombatEffect effect;
    effect = attacker.getEffect(EffectID.enchanting);
    if (effect.expend()) {
      if (effect.value > 1) {
        effect.value = 1;
      } else if (effect.value < 0) {
        effect.value = 0;
      }
      enchantRatio = effect.value;

      if (!effect.check()) {
        effect.value = 0;
      }
    }
    return enchantRatio;
  }

  int _handleInstantlyEffect(Energy attacker, Energy defender) {
    int result = 0;

    CombatEffect effect = defender.getEffect(EffectID.restoreLife);
    if (effect.expend()) {
      int recovery =
          (effect.value * (attacker.capacityBase + attacker.capacityExtra))
              .round();

      int actualRecovery = defender.recoverHealth(recovery);
      message +=
          ('${defender.name} 回复了 $actualRecovery 生命值❤️‍🩹, 当前生命值为 ${defender.health}\n');
      result = 1;
    }

    return result;
  }

  int _handleCombat(Energy attacker, Energy defender) {
    int result = 0;
    int combatCount = 1;

    result = _handleInstantlyEffect(attacker, defender);
    if (result != 0) {
      return 0;
    }

    int attack = handleAttackEffect(attacker, defender, true);

    int defence = handleDefenceEffect(attacker, defender, true);

    double coeff = _handleCoeffcientEffect(attacker, defender);

    double enchantRatio = _handleEnchantRatio(attacker, defender);

    CombatEffect effect;

    effect = attacker.getEffect(EffectID.multipleHit);
    if (effect.expend()) {
      combatCount += effect.value.round();
    }

    for (int i = 0; i < combatCount; ++i) {
      double physicsAttack = attack * (1 - enchantRatio);
      double magicAttack = attack * enchantRatio;

      effect = attacker.getEffect(EffectID.physicsAddition);
      if (effect.expend()) {
        physicsAttack += effect.value;
        effect.value = 0;
      }

      effect = attacker.getEffect(EffectID.magicAddition);
      if (effect.expend()) {
        magicAttack += effect.value;
        effect.value = 0;
      }

      result = _handleAttack(
          attacker, defender, physicsAttack, defence, coeff, false);
      if (result != 0) {
        return result;
      }

      result = _handleAttack(attacker, defender, magicAttack, 0, coeff, true);
      if (result != 0) {
        return result;
      }
    }

    return 0;
  }

  int _handleAttack(Energy attacker, Energy defender, double attack,
      int defence, double coeff, bool damageType) {
    if (attack > 0) {
      int damage = _handleDamageAddition(
          defender, _calculateDamage(attack, defence, coeff));

      return _handleDamage(attacker, defender, damage, damageType);
    } else {
      return 0;
    }
  }

  int _calculateDamage(double attack, int defence, double coeff) {
    int damage = 0;

    if (defence > 0) {
      damage = (attack * (attack / (attack + defence)) * coeff).round();
    } else {
      damage = ((attack - defence) * coeff).round();
    }

    message +=
        ("⚔️:${attack.toStringAsFixed(1)} 🛡️:$defence ${(coeff * 100).toStringAsFixed(0)}% => 💔:$damage\n");

    return damage;
  }

  int _handleDamageAddition(Energy energy, int damage) {
    CombatEffect effect = energy.getEffect(EffectID.burnDamage);
    if (effect.expend()) {
      damage += effect.value.round();
      effect.value = 0;
    }

    return damage;
  }

  int _handleDamage(
      Energy attacker, Energy defender, int damage, bool damageType) {
    int actualDamage = defender.deductHealth(damage, damageType);

    message +=
        ('${defender.name} 受到 $actualDamage ${damageType ? '⚡法术' : '🗡️物理'} 伤害, 当前生命值为 ${defender.health}\n');

    _handleDamageToBlood(attacker, actualDamage);

    if (defender.health <= 0) {
      return 1;
    } else {
      _handleHotDamage(attacker, defender, damage, damageType);
      return _handleDamageToCounter(attacker, defender);
    }
  }

  static int handleDeductHealth(
      Energy energy, int damage, bool damageType, int Function(int) delHealth) {
    // 获取实际伤害量
    damage = delHealth(damage);
    _handleAdjustByDamage(energy, damage, damageType);

    _handleExemptionDeath(energy);

    energy.changeCapacityExtra(-damage);

    _handleDamageToAddition(energy, damage, damageType);

    return damage;
  }

  static void _handleAdjustByDamage(
      Energy energy, int damage, bool damageType) {
    CombatEffect effect = energy.getEffect(EffectID.adjustAttribute);
    if (effect.expend()) {
      int health = energy.health + damage;

      double damageRatio = damage / energy.capacityBase;
      double healthRatio = health / energy.capacityBase;

      int adjustValue = (energy.defenceBase *
              damageRatio *
              pow(healthRatio + sqrt(2) - 1, 3.05))
          .round();

      energy.changeDefenceOffset(-adjustValue);
      energy.changeAttackOffset((adjustValue * effect.value).round());

      if (damageType) {
        effect = energy.getEffect(EffectID.enchanting);
        effect.value += damageRatio;
        effect.times += 1;
      }
    }
  }

  static void _handleExemptionDeath(Energy energy) {
    if (energy.health <= 0) {
      CombatEffect effect = energy.getEffect(EffectID.exemptionDeath);
      if (effect.expend()) {
        energy.recoverHealth(effect.value.round() - energy.health);
      }
    }
  }

  static void _handleDamageToAddition(
      Energy energy, int damage, bool damageType) {
    CombatEffect effect = energy.getEffect(EffectID.accumulateAnger);
    if (effect.expend()) {
      if (damageType) {
        int addition = (damage * effect.value * 0.3).round();
        effect = energy.getEffect(EffectID.magicAddition);
        effect.value += addition;
        effect.times = 1;
      } else {
        int addition = (damage * effect.value).round();
        effect = energy.getEffect(EffectID.physicsAddition);
        effect.value += addition;
        effect.times = 1;
      }
    }
  }

  void _handleDamageToBlood(Energy energy, int damage) {
    CombatEffect effect = energy.getEffect(EffectID.absorbBlood);
    if (effect.expend()) {
      int recovery = (damage * effect.value).round();
      int actualRecovery = energy.recoverHealth(recovery);
      message +=
          ('${energy.name} 回复了 $actualRecovery 生命值❤️‍🩹, 当前生命值为 ${energy.health}\n');
    }
  }

  static int handleRecoverHealth(
      Energy energy, int recovery, Function(int) addHealth) {
    _handleIncreaseCapacity(energy, recovery);

    recovery = addHealth(recovery);

    _handleAdjustByRecovery(energy, recovery);

    return recovery;
  }

  static void _handleIncreaseCapacity(Energy energy, int recovery) {
    int checkHealth = energy.health + recovery;
    int capacity = energy.capacityBase + energy.capacityExtra;

    if (checkHealth > capacity) {
      CombatEffect effect = energy.getEffect(EffectID.increaseCapacity);
      if (effect.expend()) {
        energy.changeCapacityExtra(checkHealth - capacity);
      }
    }
  }

  static void _handleAdjustByRecovery(Energy energy, int recovery) {
    CombatEffect effect = energy.getEffect(EffectID.adjustAttribute);
    if (effect.expend()) {
      double recoveryRatio = recovery / energy.capacityBase;
      double healthRatio = energy.health / energy.capacityBase;

      int adjustValue = (energy.defenceBase *
              recoveryRatio *
              pow(healthRatio + sqrt(2) - 1, 3.05))
          .round();

      energy.changeDefenceOffset(adjustValue);
      energy.changeAttackOffset(-(adjustValue * effect.value).round());
    }
  }

  void _handleHotDamage(
      Energy attacker, Energy defender, int damage, bool damageType) {
    if (damageType) {
      CombatEffect effect = attacker.getEffect(EffectID.hotDamage);
      if (effect.expend()) {
        defender.getEffect(EffectID.burnDamage).value += damage * effect.value;
        defender.getEffect(EffectID.burnDamage).times = 1;
      }
    }
  }

  int _handleDamageToCounter(Energy attacker, Energy defender) {
    int result = 0;

    CombatEffect effect = defender.getEffect(EffectID.rugged);
    if (effect.expend()) {
      double attack =
          ((defender.capacityBase + defender.capacityExtra) - defender.health) *
              effect.value;

      int defence = handleDefenceEffect(defender, attacker, true);

      result = -_handleAttack(
          defender, attacker, attack, defence, effect.value, false);
      if (result != 0) {
        return result;
      }
    }

    effect = defender.getEffect(EffectID.revengeAtonce);
    if (effect.expend()) {
      int counterCount = effect.value.round();

      for (int i = 0; i < counterCount; ++i) {
        result = -_handleCombat(defender, attacker);
        if (result != 0) {
          return result;
        }
      }
    }
    return 0;
  }
}

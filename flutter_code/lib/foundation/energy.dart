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

  int _changeHealth(int value) {
    _health += value;
    if (_health < 0) {
      value -= _health;
      _health = 0;
    } else if (_health > (_capacityBase + _capacityExtra)) {
      value -= _health - (_capacityBase + _capacityExtra);
      _health = (_capacityBase + _capacityExtra);
    }
    return value;
  }

  changeCapcityExtra(int value) {
    _capacityExtra += value;
    if (_capacityExtra < 0) {
      _capacityExtra = 0;
    } else if (_capacityExtra > _capacityBase) {
      _capacityExtra = _capacityBase;
    }
  }

  changeAttackOffset(int value) {
    if (_health == (_capacityBase + _capacityExtra)) {
      _attackOffset = 0;
    } else {
      _attackOffset += value;
    }
  }

  changeDefenceOffset(int value) {
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
  _initAttributes() {
    _capacityBase = _baseAttributes[type.index][AttributeType.hp.index];
    _attackBase = _baseAttributes[type.index][AttributeType.atk.index];
    _defenceBase = _baseAttributes[type.index][AttributeType.def.index];

    restoreAttributes();
  }

  // 清空技能，并将可学习技能列表的第一个技能作为初始技能
  _initSkills() {
    // 长度为本属性所有可用技能
    _skills =
        List.generate(SkillCollection.totalSkills[type.index].length, (index) {
      return SkillCollection.totalSkills[type.index][index].copyWith();
    });

    // 默认学习第一个技能
    _skills[0].learned = true;
  }

  // 清空效果
  _initEffects() {
    // 长度为所有效果，方便战斗时核查
    _effects = List.generate(EffectID.values.length, (index) {
      return CombatEffect(
        id: EffectID.values[index],
        type: EffectType.limited,
        value: 1,
        times: 0,
      );
    });
  }

// 还原影响
  restoreEffects() {
    for (int i = 0; i < _effects.length; i++) {
      _effects[i] = CombatEffect(
        id: EffectID.values[i],
        type: EffectType.limited,
        value: 1,
        times: 0,
      );
    }
  }

// 还原属性
  restoreAttributes() {
    _capacityExtra = 0; // 清除额外上限
    _attackOffset = 0; // 清除偏移
    _defenceOffset = 0;
    _health = capacityBase; // 恢复血量到上限
  }

  // 回复生命
  int recoverHealth(int value) {
    return EnergyCombat.handleRecoverHealth(this, value, _changeHealth);
  }

  // 扣除生命
  int deductHealth(int value, bool damageType) {
    return EnergyCombat.handleDeductHealth(
        this, value, damageType, _changeHealth);
  }

  // 升级属性
  upgradeAttributes(AttributeType attribute) {
    switch (attribute) {
      case AttributeType.hp:
        _capacityBase += 32;
        recoverHealth(32);
        break;
      case AttributeType.atk:
        _attackBase += 8;
        break;
      case AttributeType.def:
        _defenceBase += 8;
        break;
    }
  }

  // 遭受技能
  sufferSkill(CombatSkill skill) {
    skill.handler(skills, effects);
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

    effect = attacker.effects[EffectID.giantKiller.index];
    if (expend ? effect.expend() : effect.check()) {
      attack += (defender.health * effect.value).round();
    }

    effect = attacker.effects[EffectID.strengthen.index];
    if (expend ? effect.expend() : effect.check()) {
      attack += (attack * effect.value).round();
    }

    effect = attacker.effects[EffectID.weakenAttack.index];
    if (expend ? effect.expend() : effect.check()) {
      attack -= (attack * effect.value).round();
    }
    return attack;
  }

  static int handleDefenceEffect(
      Energy attacker, Energy defender, bool expend) {
    int defence = defender.defenceBase + defender.defenceOffset;
    CombatEffect effect;

    effect = defender.effects[EffectID.strengthen.index];
    if (expend ? effect.expend() : effect.check()) {
      defence += (defence * effect.value).round();
    }

    effect = defender.effects[EffectID.weakenDefence.index];
    if (expend ? effect.expend() : effect.check()) {
      defence -= (defence * effect.value).round();
    }

    return defence;
  }

  double _handleCoeffcientEffect(Energy attacker, Energy defender) {
    double coeff = 1.0;

    CombatEffect effect;

    effect = attacker.effects[EffectID.sacrificing.index];
    if (effect.expend()) {
      int deduction = attacker.health - effect.value.round();

      double increaseCoeff = deduction / attacker.capacityBase;

      coeff *= (1 + increaseCoeff);

      attacker.deductHealth(deduction, true);

      message +=
          ('${attacker.name} 对自身造成 $deduction ⚡法术伤害，伤害系数提高 ${(increaseCoeff * 100).toStringAsFixed(0)}% ， 当前生命值为 ${attacker.health}\n');
    }

    effect = attacker.effects[EffectID.coeffcient.index];
    if (effect.expend()) {
      coeff *= (1 + effect.value);
      effect.value = 1;
    }

    effect = defender.effects[EffectID.parryState.index];
    if (effect.expend()) {
      coeff *= (1 - effect.value);
    }

    return coeff;
  }

  int _handleInstantlyEffect(Energy attacker, Energy defender) {
    int result = 0;

    CombatEffect effect = defender.effects[EffectID.restoreLife.index];
    if (effect.expend()) {
      int recovery =
          (effect.value * (attacker.capacityBase + attacker.capacityExtra))
              .round();

      defender.recoverHealth(recovery);
      message +=
          ('${defender.name} 回复了 $recovery 生命值❤️‍🩹, 当前生命值为 ${defender.health}\n');
      result = 1;
    }

    return result;
  }

  int _handleCombat(Energy attacker, Energy defender) {
    int result = 0;
    int combatCount = 1;
    CombatEffect effect;

    result = _handleInstantlyEffect(attacker, defender);
    if (result != 0) {
      return 0;
    }

    effect = attacker.effects[EffectID.multipleHit.index];
    if (effect.expend()) {
      combatCount += effect.value.round();
    }

    for (int i = 0; i < combatCount; ++i) {
      int attack = handleAttackEffect(attacker, defender, true);

      int defence = handleDefenceEffect(attacker, defender, true);

      double coeff = _handleCoeffcientEffect(attacker, defender);

      double enchantRatio = 0.0;

      effect = attacker.effects[EffectID.enchanting.index];
      if (effect.expend()) {
        enchantRatio = effect.value;
        if (enchantRatio > 1) {
          enchantRatio = 1;
        } else if (enchantRatio < 0) {
          enchantRatio = 0;
        }
      }

      double physicsAttack = attack * (1 - enchantRatio);
      double magicAttack = attack * enchantRatio;

      effect = attacker.effects[EffectID.physicsAddition.index];
      if (effect.expend()) {
        physicsAttack += effect.value - 1;
        effect.value = 1;
      }

      effect = attacker.effects[EffectID.magicAddition.index];
      if (effect.expend()) {
        magicAttack += effect.value - 1;
        effect.value = 1;
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
    }

    return 0;
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
    CombatEffect effect = energy.effects[EffectID.burnDamage.index];
    if (effect.expend()) {
      damage += effect.value.round() - 1;
      effect.value = 1;
    }

    return damage;
  }

  int _handleDamage(
      Energy attacker, Energy defender, int damage, bool damageType) {
    int result = defender.deductHealth(damage, damageType);

    message +=
        ('${defender.name} 受到 $damage ${damageType ? '⚡法术' : '🗡️物理'} 伤害, 当前生命值为 ${defender.health}\n');

    _handleDamageToBlood(attacker, damage);

    _handleHotDamage(attacker, defender, damage, damageType);

    if (result != 0) {
      return result;
    } else {
      return _handleDamageToCounter(attacker, defender);
    }
  }

  static int handleDeductHealth(Energy energy, int damage, bool damageType,
      int Function(int) changeHealth) {
    damage = -changeHealth(-damage);
    _handleAdjustByDamage(energy, damage, damageType);

    _handleExemptionDeath(energy);

    energy.changeCapcityExtra(-damage);

    _handleDamageToAddition(energy, damage, damageType);

    return energy.health > 0 ? 0 : 1;
  }

  static void _handleAdjustByDamage(
      Energy energy, int damage, bool damageType) {
    CombatEffect effect = energy.effects[EffectID.adjustAttribute.index];
    if (effect.expend()) {
      int health = energy.health + damage;

      double damageRatio = damage / energy.capacityBase;
      double healthRatio = health / energy.capacityBase;

      int adjustValue =
          (energy.defenceBase * damageRatio * pow(healthRatio + sqrt(2) - 1, 4))
              .round();

      energy.changeDefenceOffset(-adjustValue);
      energy.changeAttackOffset((adjustValue * effect.value).round());

      if (damageType) {
        effect = energy.effects[EffectID.enchanting.index];
        effect.value = damageRatio;
        effect.times += 1;
      }
    }
  }

  static void _handleExemptionDeath(Energy energy) {
    if (energy.health <= 0) {
      CombatEffect effect = energy.effects[EffectID.exemptionDeath.index];
      if (effect.expend()) {
        energy.recoverHealth(effect.value.round() - energy.health);
      }
    }
  }

  static void _handleDamageToAddition(
      Energy energy, int damage, bool damageType) {
    CombatEffect effect = energy.effects[EffectID.accumulateAnger.index];
    if (effect.expend()) {
      int addition = 0;
      if (damageType) {
        addition = (damage * effect.value * 0.3).round();
        effect = energy.effects[EffectID.magicAddition.index];
        effect.value += addition;
        effect.times = 1;
      } else {
        addition = (damage * effect.value).round();
        effect = energy.effects[EffectID.physicsAddition.index];
        effect.value += addition;
        effect.times = 1;
      }
    }
  }

  void _handleDamageToBlood(Energy energy, int damage) {
    CombatEffect effect = energy.effects[EffectID.absorbBlood.index];
    if (effect.expend()) {
      int recovery = (damage * effect.value).round();
      energy.recoverHealth(recovery);
      message +=
          ('${energy.name} 回复了 $recovery 生命值❤️‍🩹, 当前生命值为 ${energy.health}\n');
    }
  }

  static int handleRecoverHealth(
      Energy energy, int recovery, Function(int) changeHealth) {
    _handleIncreaseCapacity(energy, recovery);

    recovery = changeHealth(recovery);

    _handleAdjustByRecovery(energy, recovery);

    return 0;
  }

  static void _handleIncreaseCapacity(Energy energy, int recovery) {
    int checkHealth = energy.health + recovery;
    int capacity = energy.capacityBase + energy.capacityExtra;

    if (checkHealth > capacity) {
      CombatEffect effect = energy.effects[EffectID.increaseCapacity.index];
      if (effect.expend()) {
        energy.changeCapcityExtra(checkHealth - capacity);
      }
    }
  }

  static void _handleAdjustByRecovery(Energy energy, int recovery) {
    CombatEffect effect = energy.effects[EffectID.adjustAttribute.index];
    if (effect.expend()) {
      double recoveryRatio = recovery / energy.capacityBase;
      double healthRatio = energy.health / energy.capacityBase;

      int adjustValue = (energy.defenceBase *
              recoveryRatio *
              pow(healthRatio + sqrt(2) - 1, 4))
          .round();

      energy.changeDefenceOffset(adjustValue);
      energy.changeAttackOffset(-(adjustValue * effect.value).round());
    }
  }

  void _handleHotDamage(
      Energy attacker, Energy defender, int damage, bool damageType) {
    if (damageType) {
      CombatEffect effect = attacker.effects[EffectID.hotDamage.index];
      if (effect.expend()) {
        defender.effects[EffectID.burnDamage.index].value +=
            damage * effect.value;
        defender.effects[EffectID.burnDamage.index].times = 1;
      }
    }
  }

  int _handleDamageToCounter(Energy attacker, Energy defender) {
    int result = 0;

    CombatEffect effect = defender.effects[EffectID.rugged.index];
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

    effect = defender.effects[EffectID.revengeAtonce.index];
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

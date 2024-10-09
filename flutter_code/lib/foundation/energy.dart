import 'dart:math';

import 'package:flutter/material.dart';

import 'effect.dart';
import 'skill.dart';

// 灵根：特征，体系，潜力的统称（实在找不到更合适的单词🥹），灵根拥有独立的属性，技能和效果

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
  final String name;
  final EnergyType type;

  late int _health;
  late int attack;
  late int defence;

  late int healthBase;
  late int healthExtra;
  late int capacity;

  late int attackBase;
  late int attackOffset;

  late int defenceBase;
  late int defenceOffset;

  // 技能列表
  late List<CombatSkill> skills;

  // 效果列表
  late List<CombatEffect> effects;

  // 初始数值
  static List<List<int>> baseAttributes = [
    [128, 32, 32], // metal
    [160, 16, 64], // water
    [256, 32, 16], // wood
    [96, 64, 16], // fire
    [384, 16, 0] // earth
  ];

  Energy({
    required this.name,
    required this.type,
  }) {
    _initAttributes();
    _restoreSkill();
    restoreEffect();
  }

  int get health => _health;

  _changeHealth(int value) {
    _health += value;
  }

  // 从列表中获取初始属性
  _initAttributes() {
    healthBase = baseAttributes[type.index][AttributeType.hp.index];
    attackBase = baseAttributes[type.index][AttributeType.atk.index];
    defenceBase = baseAttributes[type.index][AttributeType.def.index];

    restoreAttributes();
  }

  // 清空技能，并将可学习技能列表的第一个技能作为初始技能
  _restoreSkill() {
    // 长度为本属性所有可用技能
    skills =
        List.generate(SkillCollection.totalSkills[type.index].length, (index) {
      return SkillCollection.totalSkills[type.index][index];
    });

    // 默认学习第一个技能
    skills[0].learned = true;
  }

  // 清空效果
  restoreEffect() {
    // 长度为所有效果，方便战斗时核查
    effects = List.generate(EffectID.values.length, (index) {
      return CombatEffect(
        id: EffectID.values[index],
        type: EffectType.limited,
        value: 1,
        times: 0,
      );
    });
  }

  restoreAttributes() {
    healthExtra = 0;
    attackOffset = 0;
    defenceOffset = 0;
    updateAttributes();
    _health = capacity;
  }

  updateAttributes() {
    attack = attackBase + attackOffset;
    defence = defenceBase + defenceOffset;
    capacity = healthBase + healthExtra;
  }

  // 回复生命
  int recoverHealth(int value) {
    return EnergyCombat.handleRecoverHealth(this, value, _changeHealth);
  }

  // 扣除生命
  int deductHealth(int value, bool isMagic) {
    return EnergyCombat.handleDeductHealth(this, value, isMagic, _changeHealth);
  }

  // 升级属性
  upgradeAttributes(AttributeType attribute) {
    switch (attribute) {
      case AttributeType.hp:
        healthBase += 32;
        updateAttributes();
        recoverHealth(32);
        break;
      case AttributeType.atk:
        attackBase += 8;
        updateAttributes();
        break;
      case AttributeType.def:
        defenceBase += 8;
        updateAttributes();
        break;
    }
  }

  sufferSkill(CombatSkill skill) {
    skill.handler(skills, effects);
  }
}

class EnergyCombat {
  final Energy source;
  final Energy target;
  final ValueNotifier<String> message;
  int result = 0;

  EnergyCombat(
      {required this.source, required this.target, required this.message}) {
    result = _handleCombat(source, target);
  }

  static _handleEffectAttribute(
      Energy attacker, Energy defender, bool implement) {
    attacker.updateAttributes();
    defender.updateAttributes();

    CombatEffect effect;

    effect = attacker.effects[EffectID.giantKiller.index];
    if (implement ? effect.implement() : effect.check()) {
      attacker.attack += (defender.health * effect.value).round();
    }

    effect = attacker.effects[EffectID.strengthenAttribute.index];
    if (implement ? effect.implement() : effect.check()) {
      attacker.attack += (attacker.attack * effect.value).round();
      attacker.defence += (attacker.defence * effect.value).round();
    }

    effect = defender.effects[EffectID.strengthenAttribute.index];
    if (implement ? effect.implement() : effect.check()) {
      defender.attack += (defender.attack * effect.value).round();
      defender.defence += (defender.defence * effect.value).round();
    }

    effect = attacker.effects[EffectID.weakenAttack.index];
    if (implement ? effect.implement() : effect.check()) {
      attacker.attack -= (attacker.attack * effect.value).round();
    }

    effect = defender.effects[EffectID.weakenDefence.index];
    if (implement ? effect.implement() : effect.check()) {
      defender.defence -= (attacker.defence * effect.value).round();
    }
  }

  static int _actualRecovery(Energy energy, int recovery) {
    int checkHealth = energy.health + recovery;
    if (checkHealth > energy.capacity) {
      EnergyCombat.handleIncreaseCapacity(
          energy, checkHealth - energy.capacity);
      recovery -= checkHealth - energy.capacity;
    }
    return recovery;
  }

  static int _actualDeduction(Energy energy, int damage) {
    int checkHealth = energy.health - damage;
    if (checkHealth < 0) {
      damage += checkHealth;
    }
    return damage;
  }

  static int handleDeductHealth(
      Energy energy, int damage, bool isMagic, Function(int) changeHealth) {
    damage = _actualDeduction(energy, damage);

    _handleAdjustAttribute(energy, damage);

    changeHealth(-damage);

    if (energy.healthExtra > 0) {
      energy.healthExtra -= damage;
      if (energy.healthExtra < 0) {
        energy.healthExtra = 0;
      }
      energy.updateAttributes();
    }

    _handleExemptionDeath(energy);

    _handleDamageToAddition(energy, damage, isMagic);

    return energy.health > 0 ? 0 : 1;
  }

  static int handleRecoverHealth(
      Energy energy, int recovery, Function(int) changeHealth) {
    recovery = _actualRecovery(energy, recovery);

    changeHealth(recovery);

    _handleAdjustAttribute(energy, -recovery);

    return 0;
  }

  double _handleEffectCoeff(Energy attacker, Energy defender, double coeff) {
    CombatEffect effect;

    effect = attacker.effects[EffectID.sacrificing.index];
    if (effect.implement()) {
      attacker.deductHealth(attacker.health - 1, true);

      coeff *= (1 + ((attacker.health - 1) / (attacker.healthBase)));
    }

    effect = attacker.effects[EffectID.damageCoeff.index];
    if (effect.implement()) {
      coeff *= (1 + effect.value);
    }

    effect = defender.effects[EffectID.parryState.index];
    if (effect.implement()) {
      coeff *= (1 - effect.value);
    }

    return coeff;
  }

  int _handleCombat(Energy attacker, Energy defender) {
    CombatEffect effect;
    int combatCount = 1;

    effect = attacker.effects[EffectID.multipleHit.index];
    if (effect.implement()) {
      combatCount += effect.value.round();
    }

    for (int i = 0; i < combatCount; ++i) {
      int ret = 0;
      double coeff = 1.0;
      double enchantRatio = 0;

      _handleEffectAttribute(attacker, defender, true);

      coeff = _handleEffectCoeff(attacker, defender, coeff);

      effect = attacker.effects[EffectID.enchanting.index];
      if (effect.implement()) {
        enchantRatio += effect.value;
      }

      double physicsAttack = attacker.attack * (1 - enchantRatio);
      double magicAttack = attacker.attack * enchantRatio;

      effect = attacker.effects[EffectID.physicsAddition.index];
      if (effect.implement()) {
        physicsAttack += effect.value - 1;
        effect.value = 1;
      }

      effect = attacker.effects[EffectID.magicAddition.index];
      if (effect.implement()) {
        magicAttack += effect.value - 1;
        effect.value = 1;
      }

      ret = _handleAttack(attacker, defender, physicsAttack, coeff, false);
      if (ret != 0) {
        return ret;
      }

      ret = _handleAttack(attacker, defender, magicAttack, coeff, true);
      if (ret != 0) {
        return ret;
      }
    }

    return 0;
  }

  int _handleAttack(Energy attacker, Energy defender, double attack,
      double coeff, bool isMagic) {
    int damage = 0;

    if (attack > 0) {
      if (isMagic) {
        damage = _calculateDamage(attack, 0, coeff);
      } else {
        damage = _calculateDamage(attack, defender.defence, coeff);
      }

      damage = _handleBurnDamage(defender, damage);

      return _handleDamage(attacker, defender, damage, isMagic);
    }

    return 0;
  }

  int _calculateDamage(double attackValue, int defenceValue, double coeff) {
    double damage = 0.0;

    if (defenceValue > 0) {
      damage = attackValue * (attackValue / (attackValue + defenceValue));
    } else {
      damage = attackValue - defenceValue;
    }
    int finalDamage = (damage * coeff).round();

    message.value +=
        ("⚔️:${attackValue.toStringAsFixed(1)} 🛡️:${defenceValue.toStringAsFixed(1)} ${(coeff * 100).toStringAsFixed(0)}% => 💔:$finalDamage\n");

    return finalDamage;
  }

  int _handleBurnDamage(Energy energy, int damage) {
    CombatEffect effect = energy.effects[EffectID.burnDamage.index];
    if (effect.implement()) {
      damage += effect.value.round() - 1;
    }

    return damage;
  }

  int _handleDamage(
      Energy attacker, Energy defender, int damage, bool isMagic) {
    int ret = 0;

    ret = defender.deductHealth(damage, isMagic);

    message.value +=
        ('${defender.name} 受到 $damage ${isMagic ? '⚡法术' : '🗡️物理'} 伤害, 当前生命值为 ${defender.health}\n');

    _handleDamageToBlood(attacker, damage);

    _handleSplashDamage(attacker, defender, damage, isMagic);

    if (ret != 0) {
      return ret;
    } else {
      return _handleDamageToCounter(attacker, defender);
    }
  }

  static void _handleAdjustAttribute(Energy energy, int damage) {
    if (damage > 0) {
      CombatEffect effect = energy.effects[EffectID.adjustAttribute.index];
      if (effect.implement()) {
        double damageRatio = damage / energy.healthBase;
        double healthRatio = energy.health / energy.healthBase;

        int adjustValue = (energy.defenceBase *
                damageRatio *
                pow(healthRatio + sqrt(2) - 1, 4))
            .round();

        energy.defenceOffset -= adjustValue;
        energy.attackOffset += (adjustValue * effect.value).round();

        effect = energy.effects[EffectID.adjustAttribute.index];
      }
    }

    energy.updateAttributes();
  }

  static void _handleExemptionDeath(Energy energy) {
    if (energy.health <= 0) {
      CombatEffect effect = energy.effects[EffectID.exemptionDeath.index];
      if (effect.implement()) {
        energy.recoverHealth(1 - energy.health);
      }
    }
  }

  static void _handleDamageToAddition(Energy energy, int damage, bool isMagic) {
    CombatEffect effect = energy.effects[EffectID.accumulateAnger.index];
    if (effect.implement()) {
      int addition = 0;
      if (isMagic) {
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

    effect = energy.effects[EffectID.toughBrave.index];
    if (effect.implement()) {
      double increaseCoeff = 1 - (energy.health / energy.capacity);

      energy.effects[EffectID.damageCoeff.index].value *= (1 + increaseCoeff);
      energy.effects[EffectID.damageCoeff.index].times = 1;
    }
  }

  void _handleDamageToBlood(Energy energy, int damage) {
    CombatEffect effect = energy.effects[EffectID.absorbBlood.index];
    if (effect.implement()) {
      int recovery = (damage * effect.value).round();
      energy.recoverHealth(recovery);
      message.value +=
          ('${energy.name} 回复了 $recovery 生命值❤️‍🩹, 当前生命值为 ${energy.health}\n');
    }
  }

  static void handleIncreaseCapacity(Energy energy, int overflow) {
    CombatEffect effect = energy.effects[EffectID.increaseCapacity.index];
    if (effect.implement()) {
      energy.healthExtra += overflow;
      if (energy.healthExtra > energy.healthBase) {
        energy.healthExtra = energy.healthBase;
      }
      energy.updateAttributes();
    }
  }

  void _handleSplashDamage(
      Energy attacker, Energy defender, int damage, bool isMagic) {
    if (isMagic) {
      CombatEffect effect = attacker.effects[EffectID.splashDamage.index];
      if (effect.implement()) {
        defender.effects[EffectID.burnDamage.index].value +=
            damage * effect.value;
        defender.effects[EffectID.burnDamage.index].times = 1;
      }
    }
  }

  int _handleDamageToCounter(Energy attacker, Energy defender) {
    CombatEffect effect = defender.effects[EffectID.revengeAtonce.index];
    if (effect.implement()) {
      int ret = 0;
      int counterCount = effect.value.round();

      for (int i = 0; i < counterCount; ++i) {
        ret = -_handleCombat(defender, attacker);
        if (ret != 0) {
          return ret;
        }
      }
    }
    return 0;
  }
}

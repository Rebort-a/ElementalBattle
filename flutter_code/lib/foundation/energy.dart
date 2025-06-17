import 'dart:math';

import 'effect.dart';
import 'skill.dart';

// 灵根枚举类型
enum EnergyType { metal, water, wood, fire, earth }

// 灵根名称
const energyNames = ["🔩", "🌊", "🪵", "🔥", "🪨"];

// 属性枚举类型
enum AttributeType { hp, atk, def }

// 属性名称
const attributeNames = ["❤️", "⚔️", "🛡️"];

// 基础属性配置
const _baseAttributes = [
  [128, 32, 32], // metal
  [160, 16, 64], // water
  [256, 32, 16], // wood
  [96, 64, 16], // fire
  [384, 16, 0] // earth
];

// 灵根类
class Energy {
  final String name;
  final EnergyType type;

  int _level = 0;
  int _health = 0;
  int _capacityBase = 0;
  int _capacityExtra = 0;
  int _attackBase = 0;
  int _attackOffset = 0;
  int _defenceBase = 0;
  int _defenceOffset = 0;

  late final List<CombatSkill> skills;
  late final List<CombatEffect> effects;

  Energy({required this.name, required this.type}) {
    _initAttributes();
    _initSkills();
    _initEffects();
  }

  // 属性访问器
  int get health => _health;
  int get capacityBase => _capacityBase;
  int get capacityExtra => _capacityExtra;
  int get capacityTotal => capacityBase + capacityExtra;
  int get attackBase => _attackBase;
  int get attackOffset => _attackOffset;
  int get attackTotal => attackBase + attackOffset;
  int get defenceBase => _defenceBase;
  int get defenceOffset => _defenceOffset;
  int get defenceTotal => defenceBase + defenceOffset;
  int get level => _level;

  // 初始化属性
  void _initAttributes() {
    final attributes = _baseAttributes[type.index];
    _capacityBase = attributes[0];
    _attackBase = attributes[1];
    _defenceBase = attributes[2];
    restoreAttributes();
  }

  // 初始化技能
  void _initSkills() {
    skills = SkillCollection.totalSkills[type.index]
        .map((skill) => skill.copyWith())
        .toList();
  }

  // 初始化效果
  void _initEffects() {
    effects = EffectID.values
        .map((id) =>
            CombatEffect(id: id, type: EffectType.limited, value: 0, times: 0))
        .toList();
  }

  // 还原效果
  void restoreEffects() {
    for (final effect in effects) {
      effect.reset();
    }
  }

  // 还原属性
  void restoreAttributes() {
    _capacityExtra = 0;
    _attackOffset = 0;
    _defenceOffset = 0;
    _health = capacityTotal;
  }

  // 调整生命值
  int _adjustHealth(int value) {
    final newHealth = (_health + value).clamp(0, capacityTotal);
    final actualChange = newHealth - _health;
    _health = newHealth;
    return actualChange;
  }

  // 回复生命
  int recoverHealth(int value) {
    return EnergyCombat.handleRecoverHealth(this, value, _adjustHealth);
  }

  // 扣除生命
  int deductHealth(int value, bool isMagic) {
    return EnergyCombat.handleDeductHealth(
        this, value, isMagic, (v) => _adjustHealth(-v));
  }

  // 升级属性
  void upgradeAttributes(AttributeType attribute) {
    switch (attribute) {
      case AttributeType.hp:
        _capacityBase += 32;
        _adjustHealth(32);
        break;
      case AttributeType.atk:
        _attackBase += 8;
        break;
      case AttributeType.def:
        _defenceBase += 8;
        break;
    }
    _level++;
  }

  // 学习技能
  void learnSkill(int index) {
    if (index >= 0 && index < skills.length) {
      skills[index].learned = true;
      _level++;
    }
  }

  // 遭受技能
  void sufferSkill(CombatSkill skill) {
    skill.handler(skills, effects);
  }

  // 施加被动技能影响
  void applyPassiveEffect() {
    for (final skill in skills) {
      if (skill.learned && skill.type == SkillType.passive) {
        if (skill.targetType == SkillTarget.selfFront) {
          sufferSkill(skill);
        }
      }
    }
  }

  // 获取效果
  CombatEffect getEffect(EffectID id) => effects[id.index];
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

  // 核心战斗处理
  int _handleCombat(Energy attacker, Energy defender) {
    if (_handleInstantEffect(attacker, defender)) return 0;

    int combatCount = 1 + _getMultiHitCount(attacker);

    for (var i = 0; i < combatCount; i++) {
      final result = _executeAttackRound(attacker, defender);
      if (result != 0) return result;
    }

    return 0;
  }

  // 处理即时效果
  bool _handleInstantEffect(Energy attacker, Energy defender) {
    final effect = defender.getEffect(EffectID.restoreLife);
    if (effect.expend()) {
      final recovery = (effect.value * attacker.capacityTotal).round();
      final actual = target.recoverHealth(recovery);
      message +=
          "${target.name} 回复了 $actual 生命值❤️‍🩹, 当前生命值 ${target.health}\n";
      return true;
    }
    return false;
  }

  // 获取多重攻击次数
  int _getMultiHitCount(Energy energy) {
    final effect = energy.getEffect(EffectID.multipleHit);
    return effect.expend() ? effect.value.round() : 0;
  }

  // 执行一轮攻击
  int _executeAttackRound(Energy attacker, Energy defender) {
    final attack = calculateAttack(attacker, defender, true);
    final defence = calculateDefence(attacker, defender, true);
    final coeff = _calculateCoefficient(attacker, defender);
    final enchantRatio = _getEnchantRatio(attacker, defender);

    double physicsAttack = attack * (1 - enchantRatio);
    double magicAttack = attack * enchantRatio;

    final physicsAddition = attacker.getEffect(EffectID.physicsAddition);
    if (physicsAddition.expend()) {
      physicsAttack += physicsAddition.value;
    }

    final magicAddition = attacker.getEffect(EffectID.magicAddition);
    if (magicAddition.expend()) {
      magicAttack += magicAddition.value;
    }

    var result =
        _handleAttack(attacker, defender, physicsAttack, defence, coeff, false);
    if (result != 0) return result;

    return _handleAttack(attacker, defender, magicAttack, 0, coeff, true);
  }

  // 计算攻击力
  static int calculateAttack(Energy attacker, Energy defender, bool expend) {
    int attack = attacker.attackTotal;

    final giantKiller = attacker.getEffect(EffectID.giantKiller);
    if (expend ? giantKiller.expend() : giantKiller.check()) {
      attack += (defender.health * giantKiller.value).round();
    }

    final strengthen = attacker.getEffect(EffectID.strengthen);
    if (expend ? strengthen.expend() : strengthen.check()) {
      attack += (attacker.attackBase * strengthen.value).round();
    }

    final weakenAttack = attacker.getEffect(EffectID.weakenAttack);
    if (expend ? weakenAttack.expend() : weakenAttack.check()) {
      attack -= (attack * weakenAttack.value).round();
    }

    return attack;
  }

  // 计算防御力
  static int calculateDefence(Energy attacker, Energy defender, bool expend) {
    var defence = defender.defenceTotal;

    final strengthen = defender.getEffect(EffectID.strengthen);
    if (expend ? strengthen.expend() : strengthen.check()) {
      defence += (defender.defenceBase * strengthen.value).round();
    }

    final weakenDefence = defender.getEffect(EffectID.weakenDefence);
    if (expend ? weakenDefence.expend() : weakenDefence.check()) {
      defence -= (defence * weakenDefence.value).round();
    }

    return defence;
  }

  // 计算伤害系数
  double _calculateCoefficient(Energy attacker, Energy defender) {
    double coeff = 1.0;

    final sacrificing = attacker.getEffect(EffectID.sacrificing);
    if (sacrificing.expend()) {
      final deduction = attacker.health - sacrificing.value.round();
      final increaseCoeff = deduction / attacker.capacityBase;
      coeff *= (1 + increaseCoeff);
      attacker.deductHealth(deduction, true);
      message +=
          "${attacker.name} 对自身造成 $deduction ⚡伤害，伤害系数提高 ${(increaseCoeff * 100).toStringAsFixed(0)}%\n";
    }

    final coefficient = attacker.getEffect(EffectID.coeffcient);
    if (coefficient.expend()) {
      coeff *= (1 + coefficient.value);
    }

    final parry = defender.getEffect(EffectID.parryState);
    if (parry.expend()) {
      coeff *= (1 - parry.value);
    }

    return coeff;
  }

  // 获取附魔比例
  double _getEnchantRatio(Energy attacker, Energy defender) {
    final enchanting = attacker.getEffect(EffectID.enchanting);
    return enchanting.expend() ? enchanting.value.clamp(0.0, 1.0) : 0.0;
  }

  // 处理攻击
  int _handleAttack(Energy attacker, Energy defender, double attack,
      int defence, double coeff, bool isMagic) {
    if (attack <= 0) return 0;

    final damage = _handleDamageAddition(
        defender, _calculateDamage(attack, defence, coeff));
    final actualDamage = defender.deductHealth(damage, isMagic);

    message +=
        "${defender.name} 受到 $actualDamage ${isMagic ? '⚡法术' : '🗡️物理'} 伤害, 生命值 ${defender.health}\n";

    if (defender.health <= 0) return 1;

    if (!isMagic) _handleBloodAbsorption(attacker, actualDamage);
    _handleHotDamage(attacker, defender, damage, isMagic);

    return _handleCounterAttack(attacker, defender);
  }

  // 计算伤害
  int _calculateDamage(double attack, int defence, double coeff) {
    final damageDouble = defence > 0
        ? attack * (attack / (attack + defence)) * coeff
        : (attack - defence) * coeff;

    int damage = damageDouble.round();

    message +=
        "⚔️:${attack.toStringAsFixed(1)} 🛡️:$defence ${(coeff * 100).toStringAsFixed(0)}% => 💔:$damage\n";
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

  // 处理吸血效果
  void _handleBloodAbsorption(Energy energy, int damage) {
    final absorbBlood = energy.getEffect(EffectID.absorbBlood);
    if (absorbBlood.expend()) {
      final recovery = (damage * absorbBlood.value).round();
      final actual = energy.recoverHealth(recovery);
      message +=
          "${energy.name} 吸血回复 $actual 生命值❤️‍🩹, 当前生命值 ${energy.health}\n";
    }
  }

  // 处理灼烧效果
  void _handleHotDamage(
      Energy attacker, Energy defender, int damage, bool isMagic) {
    if (isMagic) {
      final hotDamage = attacker.getEffect(EffectID.hotDamage);
      if (hotDamage.expend()) {
        defender.getEffect(EffectID.burnDamage).value +=
            damage * hotDamage.value;
      }
    }
  }

  // 处理反击
  int _handleCounterAttack(Energy attacker, Energy defender) {
    var result = _handleRuggedCounter(attacker, defender);
    if (result != 0) return result;

    return _handleRevengeCounter(attacker, defender);
  }

  // 处理反伤
  int _handleRuggedCounter(Energy attacker, Energy defender) {
    final rugged = defender.getEffect(EffectID.rugged);
    if (!rugged.expend()) return 0;

    final attack = (defender.capacityTotal - defender.health) * rugged.value;
    final defence = _calculateDefenceForCounter();

    return -_handleAttack(
        defender, attacker, attack, defence, rugged.value, false);
  }

  // 处理反击
  int _handleRevengeCounter(Energy attacker, Energy defender) {
    final revenge = defender.getEffect(EffectID.revengeAtonce);
    if (!revenge.expend()) return 0;

    for (var i = 0; i < revenge.value.round(); i++) {
      final result = -_handleCombat(defender, attacker);
      if (result != 0) return result;
    }
    return 0;
  }

  // 计算防御力（用于反击）
  int _calculateDefenceForCounter() {
    final strengthen = source.getEffect(EffectID.strengthen);
    return strengthen.expend()
        ? source.defenceBase * (1 + strengthen.value).round()
        : source.defenceTotal;
  }

  // 处理生命值扣除
  static int handleDeductHealth(
      Energy energy, int damage, bool isMagic, int Function(int) delHealth) {
    // 调整属性
    _adjustByDamage(energy, damage, isMagic);

    // 应用伤害
    final actual = delHealth(damage);

    // 处理免死效果
    if (energy.health <= 0) {
      final exemption = energy.getEffect(EffectID.exemptionDeath);
      if (exemption.expend()) {
        energy.recoverHealth(exemption.value.round());
      }
    }

    // 处理怒气积累
    _handleAngerAccumulation(energy, actual, isMagic);

    return actual;
  }

  // 根据伤害调整属性
  static void _adjustByDamage(Energy energy, int damage, bool isMagic) {
    final adjustEffect = energy.getEffect(EffectID.adjustAttribute);
    if (!adjustEffect.expend()) return;

    final damageRatio = damage / energy.capacityBase;
    final healthRatio = (energy.health + damage) / energy.capacityTotal;

    final adjustValue =
        (energy.defenceBase * damageRatio * pow(healthRatio + 0.3, 6.2))
            .round();

    energy._defenceOffset -= adjustValue;
    energy._attackOffset += (adjustValue * adjustEffect.value).round();

    if (isMagic) {
      final enchanting = energy.getEffect(EffectID.enchanting);
      enchanting.value += damageRatio;
    }
  }

  // 处理怒气积累
  static void _handleAngerAccumulation(
      Energy energy, int damage, bool isMagic) {
    final anger = energy.getEffect(EffectID.accumulateAnger);
    if (!anger.expend()) return;

    final effect = isMagic
        ? energy.getEffect(EffectID.magicAddition)
        : energy.getEffect(EffectID.physicsAddition);

    effect.value += damage * anger.value * (isMagic ? 0.3 : 1.0);
  }

  // 处理生命值恢复
  static int handleRecoverHealth(
      Energy energy, int recovery, int Function(int) addHealth) {
    // 增加容量
    if (energy.health + recovery > energy.capacityTotal) {
      final increase = energy.getEffect(EffectID.increaseCapacity);
      if (increase.expend()) {
        energy._capacityExtra =
            (energy.health + recovery) - energy.capacityTotal;
      }
    }

    // 应用恢复
    final actual = addHealth(recovery);

    // 调整属性
    _adjustByRecovery(energy, actual);

    return actual;
  }

  // 根据恢复调整属性
  static void _adjustByRecovery(Energy energy, int recovery) {
    final adjustEffect = energy.getEffect(EffectID.adjustAttribute);
    if (!adjustEffect.expend()) return;

    final recoveryRatio = recovery / energy.capacityBase;
    final healthRatio = energy.health / energy.capacityTotal;

    final adjustValue =
        (energy.defenceBase * recoveryRatio * pow(healthRatio + 0.3, 6.2))
            .round();

    energy._defenceOffset += adjustValue;
    energy._attackOffset -= (adjustValue * adjustEffect.value).round();
  }
}

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

  late final List<CombatSkill> _skills;
  late final List<CombatEffect> _effects;

  // 初始数值
  static final List<List<int>> _baseAttributes = [
    [128, 32, 32], // metal
    [160, 16, 64], // water
    [256, 32, 16], // wood
    [96, 64, 16], // fire
    [384, 16, 0] // earth
  ];

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
  List<CombatSkill> get skills => _skills;
  List<CombatEffect> get effects => _effects;
  int get level => _level;

  // 初始化属性
  void _initAttributes() {
    List<int> attributes = _baseAttributes[type.index];
    _capacityBase = attributes[0];
    _attackBase = attributes[1];
    _defenceBase = attributes[2];
    restoreAttributes();
  }

  // 初始化技能
  void _initSkills() {
    _skills = SkillCollection.totalSkills[type.index]
        .map((skill) => skill.copyWith())
        .toList();
  }

  // 初始化效果
  void _initEffects() {
    _effects = EffectID.values
        .map((id) =>
            CombatEffect(id: id, type: EffectType.limited, value: 0, times: 0))
        .toList();
  }

  // 还原效果
  void restoreEffects() {
    for (CombatEffect effect in _effects) {
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

  void changeAttackOffset(int value) {
    _attackOffset += value;
  }

  void changeDefenceOffset(int value) {
    _defenceOffset += value;
  }

  void changeCapacityExtra(int value) {
    _capacityExtra = (_capacityExtra + value).clamp(0, capacityBase);
  }

  // 调整生命值
  int _changeHealth(int value) {
    final newHealth = (_health + value).clamp(0, capacityTotal);
    final actualChange = newHealth - _health;
    _health = newHealth;

    return actualChange;
  }

  // 回复生命
  int recoverHealth(int value) {
    return EnergyCombat.handleRecoverHealth(this, value, _changeHealth);
  }

  // 扣除生命
  int deductHealth(int value, bool isMagic) {
    return EnergyCombat.handleDeductHealth(
        this, value, isMagic, (v) => _changeHealth(-v));
  }

  // 升级属性
  void upgradeAttributes(AttributeType attribute) {
    switch (attribute) {
      case AttributeType.hp:
        _capacityBase += 32;
        _changeHealth(32);
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
    if (index >= 0 && index < _skills.length) {
      _skills[index].learned = true;
      _level++;
    }
  }

  // 遭受技能
  void sufferSkill(CombatSkill skill) {
    skill.handler(_skills, _effects);
  }

  // 施加被动技能影响
  void applyPassiveEffect() {
    for (final skill in _skills) {
      if (skill.learned && skill.type == SkillType.passive) {
        if (skill.targetType == SkillTarget.selfFront) {
          sufferSkill(skill);
        }
      }
    }
  }

  // 获取效果
  CombatEffect getEffect(EffectID id) => _effects[id.index];
}

class EnergyCombat {
  final Energy source;
  final Energy target;
  String message = "";
  int record = 0;

  EnergyCombat({required this.source, required this.target});

  void execute() {
    record = _handleExecute(source, target);
  }

  // 处理执行
  int _handleExecute(Energy source, Energy target) {
    //如果有即时效果，处理完退出
    if (_handleInstantEffect(source, target)) return 0;

    // 如果没有，进行战斗
    return _handleCombat(source, target);
  }

  // 处理即时效果
  bool _handleInstantEffect(Energy source, Energy target) {
    CombatEffect effect = target.getEffect(EffectID.restoreLife);
    if (effect.expend()) {
      int recovery = (effect.value * source.capacityTotal).round();
      int actual = target.recoverHealth(recovery);
      message +=
          "${target.name} 回复了 $actual 生命值❤️‍🩹, 当前生命值 ${target.health}\n";
      return true;
    }
    return false;
  }

  // 处理战斗
  int _handleCombat(Energy attacker, Energy defender) {
    int result = 0;

    int combatCount = 1 + _handleHitCount(attacker);

    for (int i = 0; i < combatCount; i++) {
      result = _handleBattle(attacker, defender);
      if (result != 0) return result;
    }
    return result;
  }

  // 处理额外攻击次数
  int _handleHitCount(Energy energy) {
    CombatEffect effect = energy.getEffect(EffectID.multipleHit);
    return effect.expend() ? effect.value.round() : 0;
  }

  // 执行一轮攻击
  int _handleBattle(Energy attacker, Energy defender) {
    int attack = handleAttackEffect(attacker, defender, true);
    int defence = handleDefenceEffect(attacker, defender, true);
    double coeff = _handleCoeffcientEffect(attacker, defender);
    double enchantRatio = _handleEnchantRatio(attacker, defender);

    double physicsAttack = attack * (1 - enchantRatio);
    double magicAttack = attack * enchantRatio;

    CombatEffect physicsAddition = attacker.getEffect(EffectID.physicsAddition);
    if (physicsAddition.expend()) {
      physicsAttack += physicsAddition.value;
      physicsAddition.value = 0;
    }

    CombatEffect magicAddition = attacker.getEffect(EffectID.magicAddition);
    if (magicAddition.expend()) {
      magicAttack += magicAddition.value;
      magicAddition.value = 0;
    }

    int result =
        _handleAttack(attacker, defender, physicsAttack, defence, coeff, false);
    if (result != 0) return result;

    return _handleAttack(attacker, defender, magicAttack, 0, coeff, true);
  }

  // 计算攻击力
  static int handleAttackEffect(Energy attacker, Energy defender, bool expend) {
    int attack = attacker.attackTotal;

    CombatEffect giantKiller = attacker.getEffect(EffectID.giantKiller);
    if (expend ? giantKiller.expend() : giantKiller.check()) {
      attack += (defender.health * giantKiller.value).round();
    }

    CombatEffect strengthen = attacker.getEffect(EffectID.strengthen);
    if (expend ? strengthen.expend() : strengthen.check()) {
      attack += (attacker.attackBase * strengthen.value).round();
    }

    CombatEffect weakenAttack = attacker.getEffect(EffectID.weakenAttack);
    if (expend ? weakenAttack.expend() : weakenAttack.check()) {
      attack -= (attack * weakenAttack.value).round();
    }

    return attack;
  }

  // 计算防御力
  static int handleDefenceEffect(
      Energy attacker, Energy defender, bool expend) {
    int defence = defender.defenceTotal;

    CombatEffect strengthen = defender.getEffect(EffectID.strengthen);
    if (expend ? strengthen.expend() : strengthen.check()) {
      defence += (defender.defenceBase * strengthen.value).round();
    }

    CombatEffect weakenDefence = defender.getEffect(EffectID.weakenDefence);
    if (expend ? weakenDefence.expend() : weakenDefence.check()) {
      defence -= (defence * weakenDefence.value).round();
    }

    return defence;
  }

  // 计算伤害系数
  double _handleCoeffcientEffect(Energy attacker, Energy defender) {
    double coeff = 1.0;

    CombatEffect sacrificing = attacker.getEffect(EffectID.sacrificing);
    if (sacrificing.expend()) {
      int deduction = attacker.health - sacrificing.value.round();
      double increaseCoeff = deduction / attacker.capacityBase;
      coeff *= (1 + increaseCoeff);
      attacker.deductHealth(deduction, true);
      message +=
          "${attacker.name} 对自身造成 $deduction ⚡伤害，伤害系数提高 ${(increaseCoeff * 100).toStringAsFixed(0)}%\n";
    }

    CombatEffect coefficient = attacker.getEffect(EffectID.coeffcient);
    if (coefficient.expend()) {
      coeff *= (1 + coefficient.value);
    }

    CombatEffect parry = defender.getEffect(EffectID.parryState);
    if (parry.expend()) {
      coeff *= (1 - parry.value);
    }

    return coeff;
  }

  // 获取附魔比例
  double _handleEnchantRatio(Energy attacker, Energy defender) {
    double ratio = 0.0;
    CombatEffect enchanting = attacker.getEffect(EffectID.enchanting);
    if (enchanting.expend()) {
      ratio += enchanting.value.clamp(0.0, 1.0);
      if (!enchanting.check()) {
        enchanting.value = 0;
      }
    }

    return ratio;
  }

  // 处理攻击
  int _handleAttack(Energy attacker, Energy defender, double attack,
      int defence, double coeff, bool isMagic) {
    if (attack <= 0) return 0;

    int damage = _handleDamageAddition(
        defender, _calculateDamage(attack, defence, coeff));
    int actualDamage = defender.deductHealth(damage, isMagic);

    message +=
        "${defender.name} 受到 $actualDamage ${isMagic ? '⚡法术' : '🗡️物理'} 伤害, 生命值 ${defender.health}\n";

    if (isMagic) {
      // 如果是法术伤害处理灼烧
      _handleHotDamage(attacker, defender, damage);
    } else {
      // 如果是物理伤害处理吸血
      _handleBloodAbsorption(attacker, actualDamage);
    }

    if (defender.health <= 0) {
      // 决出胜负
      return 1;
    } else {
      // 未决出胜负，处理复仇
      return _handleRevenge(attacker, defender);
    }
  }

  // 计算伤害
  int _calculateDamage(double attack, int defence, double coeff) {
    double damage = defence > 0
        ? attack * (attack / (attack + defence)) * coeff
        : (attack - defence) * coeff;

    int damageRound = damage.round();

    message +=
        "⚔️:${attack.toStringAsFixed(1)} 🛡️:$defence ${(coeff * 100).toStringAsFixed(0)}% => 💔:$damageRound\n";
    return damageRound;
  }

  // 处理伤害加成
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
    CombatEffect absorbBlood = energy.getEffect(EffectID.absorbBlood);
    if (absorbBlood.expend()) {
      int recovery = (damage * absorbBlood.value).round();
      int actual = energy.recoverHealth(recovery);
      message += "${energy.name} 回复 $actual 生命值❤️‍🩹, 当前生命值 ${energy.health}\n";
    }
  }

  // 处理灼烧效果
  void _handleHotDamage(Energy attacker, Energy defender, int damage) {
    CombatEffect hotDamage = attacker.getEffect(EffectID.hotDamage);
    if (hotDamage.expend()) {
      CombatEffect burnDamage = defender.getEffect(EffectID.burnDamage);
      burnDamage.times += 1;
      burnDamage.value += damage * hotDamage.value;
    }
  }

  // 处理复仇
  int _handleRevenge(Energy attacker, Energy defender) {
    int result = _handleRugged(attacker, defender);
    if (result != 0) return result;

    return _handleCounter(attacker, defender);
  }

  // 处理反伤
  int _handleRugged(Energy attacker, Energy defender) {
    CombatEffect rugged = defender.getEffect(EffectID.rugged);
    if (!rugged.expend()) return 0;

    double attack = (defender.capacityTotal - defender.health) * rugged.value;

    int defence = handleDefenceEffect(defender, attacker, true);

    return -_handleAttack(
        defender, attacker, attack, defence, rugged.value, false);
  }

  // 处理反击
  int _handleCounter(Energy attacker, Energy defender) {
    CombatEffect revenge = defender.getEffect(EffectID.revengeAtonce);
    if (!revenge.expend()) return 0;

    for (int i = 0; i < revenge.value.round(); i++) {
      int result = -_handleCombat(defender, attacker);
      if (result != 0) return result;
    }
    return 0;
  }

  // 处理生命值扣除
  static int handleDeductHealth(
      Energy energy, int damage, bool isMagic, int Function(int) delHealth) {
    // 扣除额外上限
    energy.changeCapacityExtra(-damage);

    // 调整属性
    _handleAdjustAttributes(energy, -damage, isMagic);

    // 应用伤害
    int actual = -delHealth(damage);

    // 免死效果
    _handleExemptionDeath(energy);

    // 怒气积累
    _handleAngerAccumulation(energy, actual, isMagic);

    return actual;
  }

  // 处理免死效果
  static void _handleExemptionDeath(Energy energy) {
    if (energy.health <= 0) {
      CombatEffect exemption = energy.getEffect(EffectID.exemptionDeath);
      if (exemption.expend()) {
        energy.recoverHealth(exemption.value.round() - energy.health);
      }
    }
  }

  // 处理怒气积累
  static void _handleAngerAccumulation(
      Energy energy, int damage, bool isMagic) {
    CombatEffect anger = energy.getEffect(EffectID.accumulateAnger);
    if (!anger.expend()) return;

    CombatEffect effect = isMagic
        ? energy.getEffect(EffectID.magicAddition)
        : energy.getEffect(EffectID.physicsAddition);

    effect.times += 1;
    effect.value += damage * anger.value * (isMagic ? 0.3 : 1.0);
  }

  // 处理生命值恢复
  static int handleRecoverHealth(
      Energy energy, int recovery, int Function(int) addHealth) {
    // 增加容量
    _handleIncreaseCapacity(energy, recovery);

    // 应用恢复
    int actual = addHealth(recovery);

    // 调整属性
    _handleAdjustAttributes(energy, recovery, false);

    return actual;
  }

  // 处理增加容量
  static void _handleIncreaseCapacity(Energy energy, int recovery) {
    int overflow = energy.health + recovery - energy.capacityTotal;

    if (overflow > 0) {
      CombatEffect increase = energy.getEffect(EffectID.increaseCapacity);
      if (increase.expend()) {
        energy.changeCapacityExtra(overflow);
      }
    }
  }

  // 处理调整属性
  static void _handleAdjustAttributes(Energy energy, int value, bool isMagic) {
    CombatEffect adjustEffect = energy.getEffect(EffectID.adjustAttribute);
    if (!adjustEffect.expend()) return;

    double valueRatio = value / energy.capacityTotal;
    double healthRatio = energy.health / energy.capacityTotal;

    int adjust =
        (energy.defenceBase * valueRatio * pow(healthRatio + 0.3, 6.2)).round();

    energy.changeDefenceOffset(adjust);
    energy.changeAttackOffset(-(adjust * adjustEffect.value).round());

    if (isMagic) {
      CombatEffect enchanting = energy.getEffect(EffectID.enchanting);
      enchanting.times += 1;
      enchanting.value += valueRatio;
    }
  }
}

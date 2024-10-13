// 效果标识
enum EffectID {
  restoreLife,

  multipleHit,

  giantKiller,

  strengthen,

  weakenAttack,

  weakenDefence,

  sacrificing,

  coeffcient,

  parryState,

  enchanting,

  physicsAddition,

  magicAddition,

  burnDamage,

  adjustAttribute,

  exemptionDeath,

  absorbBlood,

  increaseCapacity,

  accumulateAnger,

  rugged,

  hotDamage,

  revengeAtonce,
}

// 效果类型
enum EffectType {
  limited,
  unlimited,
}

// 效果
class CombatEffect {
  final EffectID id;
  EffectType type;
  double value;
  int times;

  CombatEffect({
    required this.id,
    required this.type,
    required this.value,
    required this.times,
  });

  bool check() {
    return type == EffectType.unlimited || times > 0;
  }

  bool expend() {
    if (type == EffectType.unlimited) {
      return true;
    }
    if (times > 0) {
      times--;
      return true;
    }
    return false;
  }
}

#include <math.h>

#include "combat.h"
#include "custom.h"

// 改变生命值
int addHealth(Energy *energy, int value) {
  energy->health += value;
  if (energy->health > (energy->capacityBase + energy->capacityExtra)) {
    value -= energy->health - (energy->capacityBase + energy->capacityExtra);
    energy->health = (energy->capacityBase + energy->capacityExtra);
  }

  return value;
}

int reduceHealth(Energy *energy, int value) {
  energy->health -= value;
  if (energy->health < 0) {
    value += energy->health;
    energy->health = 0;
  }
  return value;
}

int handleRecoverHealth(Energy *energy, int recovery);
int handleDeductHealth(Energy *energy, int damage, int damageType);

// 处理即时效果
int handleInstantlyEffect(Energy *attacker, Energy *defender) {
  int result = 0;

  CombatEffect *effect = &defender->effects[restoreLife];
  if (expendEffect(effect)) {
    int recovery = round(
        (effect->value * (attacker->capacityBase + attacker->capacityExtra)));

    handleRecoverHealth(defender, recovery);
    customPrintf("%s 回复了 %d 生命值❤️‍🩹, "
                 "当前生命值为 "
                 "%d\n",
                 defender->name, recovery, defender->health);
    result = 1;
  }

  return result;
}

// 处理攻击效果
int handleAttackEffect(Energy *attacker, Energy *defender, int expend) {
  int attack = attacker->attackBase + attacker->attackOffset;
  CombatEffect *effect;

  effect = &attacker->effects[giantKiller];
  if (expend ? expendEffect(effect) : checkEffect(effect)) {
    attack += round(defender->health * effect->value);
  }

  effect = &attacker->effects[strengthen];
  if (expend ? expendEffect(effect) : checkEffect(effect)) {
    attack += round(attack * effect->value);
  }

  effect = &attacker->effects[weakenAttack];
  if (expend ? expendEffect(effect) : checkEffect(effect)) {
    attack -= round(attack * effect->value);
  }
  return attack;
}

// 处理防御效果
int handleDefenceEffect(Energy *attacker, Energy *defender, int expend) {
  int defence = defender->defenceBase + defender->defenceOffset;
  CombatEffect *effect;

  effect = &defender->effects[strengthen];
  if (expend ? expendEffect(effect) : checkEffect(effect)) {
    defence += round(defence * effect->value);
  }

  effect = &defender->effects[weakenDefence];
  if (expend ? expendEffect(effect) : checkEffect(effect)) {
    defence -= round(defence * effect->value);
  }

  return defence;
}

// 处理系数效果
double handleCoeffcientEffect(Energy *attacker, Energy *defender) {
  double coeff = 1.0;

  CombatEffect *effect;

  effect = &attacker->effects[sacrificing];
  if (expendEffect(effect)) {
    int deduction = round(attacker->health - effect->value);
    double increaseCoeff = deduction / (double)attacker->capacityBase;

    coeff *= (1 + increaseCoeff);

    handleDeductHealth(attacker, deduction, 0); // 假设 0 为法术伤害类型

    customPrintf("%s 对自身造成 %d ⚡法术伤害，伤害系数提高 %.0f%% "
                 "， 当前生命值为 %d\n",
                 attacker->name, deduction, (increaseCoeff * 100),
                 attacker->health);
  }

  effect = &attacker->effects[coeffcient];
  if (expendEffect(effect)) {
    coeff *= (1 + effect->value);
    if (!checkEffect(effect)) {
      effect->value = 0;
    }
  }

  effect = &defender->effects[parryState];
  if (expendEffect(effect)) {
    coeff *= (1 - effect->value);
  }

  return coeff;
}

double handleEnchantRatio(Energy *attacker, Energy *defender) {
  CombatEffect *effect;

  double enchantRatio = 0.0;

  effect = &attacker->effects[enchanting];
  if (expendEffect(effect)) {
    if (effect->value > 1) {
      effect->value = 1;
    } else if (effect->value < 0) {
      effect->value = 0;
    }
    enchantRatio = effect->value;

    if (!checkEffect(effect)) {
      effect->value = 0;
    }
  }

  return enchantRatio;
}

// 计算伤害
int handleCalculateDamage(double attack, int defence, double coeff) {
  int damage = 0;

  if (defence > 0) {
    damage = round(attack * (attack / (attack + defence)) * coeff);
  } else {
    damage = round((attack - defence) * coeff);
  }

  customPrintf("⚔️:%.1f 🛡️:%d %0.0f%% => 💔:%d\n", attack, defence, coeff * 100,
               damage);

  return damage;
}

// 处理增加容量效果
void handleIncreaseCapacity(Energy *energy, int recovery) {
  int checkHealth = energy->health + recovery;
  int capacity = energy->capacityBase + energy->capacityExtra;

  if (checkHealth > capacity) {
    CombatEffect *effect = &energy->effects[increaseCapacity];
    if (expendEffect(effect)) {
      energy->capacityExtra += checkHealth - capacity;
    }
  }
}

// 根据恢复生命值调整属性
void handleAdjustByRecovery(Energy *energy, int recovery) {
  CombatEffect *effect = &energy->effects[adjustAttribute];
  if (expendEffect(effect)) {
    double recoveryRatio = recovery / (double)energy->capacityBase;
    double healthRatio = energy->health / (double)energy->capacityBase;

    int adjustValue = round(
        (energy->defenceBase * recoveryRatio * pow(healthRatio + 0.3, 6.2)));

    energy->defenceOffset += adjustValue;
    energy->attackOffset -= round(adjustValue * effect->value);
  }
}

// 回复生命值
int handleRecoverHealth(Energy *energy, int recovery) {

  handleIncreaseCapacity(energy, recovery);

  int ActualRecovery = addHealth(energy, recovery);

  handleAdjustByRecovery(energy, ActualRecovery);

  return ActualRecovery;
}

// 处理伤害转化为生命值效果
void handleDamageToBlood(Energy *energy, int damage) {
  CombatEffect *effect = &energy->effects[absorbBlood];
  if (expendEffect(effect)) {
    int recovery = round(damage * effect->value);
    int actualRecovery = handleRecoverHealth(energy, recovery);
    customPrintf("%s 回复了 %d 生命值❤️‍🩹, "
                 "当前生命值为 "
                 "%d\n",
                 energy->name, actualRecovery, energy->health);
  }
}

// 处理热伤害效果
void handleHotDamage(Energy *attacker, Energy *defender, int damage,
                     int damageType) {
  if (damageType) {
    CombatEffect *effect = &attacker->effects[hotDamage];
    if (expendEffect(effect)) {
      defender->effects[burnDamage].value += round(damage * effect->value);
      defender->effects[burnDamage].times = 1;
    }
  }
}

int handleAttack(Energy *attacker, Energy *defender, double attack, int defence,
                 double coeff, int damageType);

// 处理反击伤害效果
int handleDamageToCounter(Energy *attacker, Energy *defender) {
  int result = 0;

  CombatEffect *effect = &defender->effects[rugged];
  if (expendEffect(effect)) {
    double attack = ((defender->capacityBase + defender->capacityExtra) -
                     defender->health) *
                    effect->value;

    int defence = handleDefenceEffect(defender, attacker, 1);

    result =
        -handleAttack(defender, attacker, attack, defence, effect->value, 0);
    if (result != 0) {
      return result;
    }
  }

  effect = &defender->effects[revengeAtonce];
  if (expendEffect(effect)) {
    int counterCount = round(effect->value);

    for (int i = 0; i < counterCount; ++i) {
      result = -handleCombat(defender, attacker);
      if (result != 0) {
        return result;
      }
    }
  }
  return 0;
}

// 根据伤害调整属性
void handleAdjustByDamage(Energy *energy, int damage, int damageType) {

  CombatEffect *effect = &energy->effects[adjustAttribute];
  if (expendEffect(effect)) {
    int health = energy->health + damage; // 计算受到伤害前的生命值

    double damageRatio = damage / (double)energy->capacityBase;
    double healthRatio = health / (double)energy->capacityBase;

    // 方案0
    // int adjustValue = round(energy->defenceBase * damageRatio *
    //                         pow(healthRatio + sqrt(2) - 1, 4));
    // energy->effects[absorbBlood].value = 0.4;

    // 方案1
    // int adjustValue = round(energy->defenceBase * damageRatio *
    //                         pow(healthRatio + sqrt(2) - 1, 1.75));
    // energy->effects[absorbBlood].value = 0.32;

    // 方案2
    // damage = round(attack * (attack / (attack + (defence * 2))) * coeff);
    // int adjustValue =
    // round(energy->defenceBase * damageRatio * pow(healthRatio + 0.28, 3));
    // energy->effects[adjustAttribute].value = 1;
    // energy->defenceBase = 24;
    // energy->effects[absorbBlood].value = 0.8;
    // energy->effects[accumulateAnger].value = 0.75;

    // 方案3
    // energy->effects[adjustAttribute].value = 0.75;
    // energy->effects[absorbBlood].value = 0.125;
    // int adjustValue = round(energy->defenceBase * damageRatio *
    //                         pow(healthRatio + sqrt(2) - 1, 3.05));

    int adjustValue =
        round(energy->defenceBase * damageRatio * pow(healthRatio + 0.3, 6.2));

    energy->defenceOffset -= adjustValue;
    energy->attackOffset += round(adjustValue * effect->value);

    if (damageType) {
      effect = &energy->effects[enchanting];
      effect->value += damageRatio;
      effect->times += 1;
    }
  }
}

// 处理免疫死亡效果
void handleExemptionDeath(Energy *energy) {
  if (energy->health <= 0) {
    CombatEffect *effect = &energy->effects[exemptionDeath];
    if (expendEffect(effect)) {
      handleRecoverHealth(energy, round(effect->value - energy->health));
    }
  }
}

// 处理伤害附加效果
void handleDamageToAddition(Energy *energy, int damage, int damageType) {
  CombatEffect *effect = &energy->effects[accumulateAnger];
  if (expendEffect(effect)) {
    if (damageType) {
      int addition = round(damage * effect->value * 0.3);
      effect = &energy->effects[magicAddition];
      effect->value += addition;
      effect->times = 1;
    } else {
      int addition = round(damage * effect->value);
      effect = &energy->effects[physicsAddition];
      effect->value += addition;
      effect->times = 1;
    }
  }
}

// 扣除生命值
int handleDeductHealth(Energy *energy, int damage, int damageType) {

  damage = reduceHealth(energy, damage);
  handleAdjustByDamage(energy, damage, damageType);

  handleExemptionDeath(energy);

  energy->capacityExtra -= damage;
  if (energy->capacityExtra < 0) {
    energy->capacityExtra = 0;
  }

  handleDamageToAddition(energy, damage, damageType);

  return damage;
}

// 处理伤害
int handleDamage(Energy *attacker, Energy *defender, int damage,
                 int damageType) {

  int ActualDamage = handleDeductHealth(defender, damage, damageType);

  customPrintf("%s 受到 %d %s 伤害, "
               "当前生命值为 %d\n",
               defender->name, ActualDamage, damageType ? "⚡法术" : "🗡️物理",
               defender->health);

  if (damageType == 0) {
    handleDamageToBlood(attacker, ActualDamage);
  }

  if (defender->health <= 0) {
    return 1;
  } else {
    handleHotDamage(attacker, defender, damage, damageType);
    return handleDamageToCounter(attacker, defender);
  }
}

// 处理攻击
int handleAttack(Energy *attacker, Energy *defender, double attack, int defence,
                 double coeff, int damageType) {
  if (attack > 0) {
    int damage = handleCalculateDamage(attack, defence, coeff);

    return handleDamage(attacker, defender, damage, damageType);
  } else {
    return 0;
  }
}

// 处理战斗
int handleCombat(Energy *attacker, Energy *defender) {
  int result = 0;
  int combatCount = 1;

  result = handleInstantlyEffect(attacker, defender);
  if (result != 0) {
    return 0;
  }

  CombatEffect *effect;

  effect = &attacker->effects[multipleHit];
  if (expendEffect(effect)) {
    combatCount += round(effect->value);
  }

  for (int i = 0; i < combatCount; ++i) {

    int attack = handleAttackEffect(attacker, defender, 1);

    int defence = handleDefenceEffect(attacker, defender, 1);

    double coeff = handleCoeffcientEffect(attacker, defender);

    double enchantRatio = handleEnchantRatio(attacker, defender);

    double physicsAttack = attack * (1 - enchantRatio);
    double magicAttack = attack * enchantRatio;

    effect = &attacker->effects[physicsAddition];
    if (expendEffect(effect)) {
      physicsAttack += effect->value;
      effect->value = 0;
    }

    effect = &attacker->effects[magicAddition];
    if (expendEffect(effect)) {
      magicAttack += effect->value;
      effect->value = 0;
    }

    result = handleAttack(attacker, defender, physicsAttack, defence, coeff, 0);
    if (result != 0) {
      return result;
    }

    result = handleAttack(attacker, defender, magicAttack, 0, coeff, 1);
    if (result != 0) {
      return result;
    }
  }

  return 0;
}
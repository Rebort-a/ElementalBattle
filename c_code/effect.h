#ifndef EFFECT_H
#define EFFECT_H

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
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
  EFFECT_ID_COUNT
} EffectID;

typedef enum { limited, infinite } EffectType;

typedef struct {
  EffectID id;
  EffectType type;
  double value;
  int times;
} CombatEffect;

extern int checkEffect(CombatEffect *effect);
extern int expendEffect(CombatEffect *effect);

#ifdef __cplusplus
}
#endif

#endif // EFFECT_H
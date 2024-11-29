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

int checkEffect(CombatEffect *effect);
int expendEffect(CombatEffect *effect);
#include "effect.h"

typedef struct {
  int health;
  int capacityBase;
  int capacityExtra;
  int attackBase;
  int attackOffset;
  int defenceBase;
  int defenceOffset;
  int level;
  CombatEffect effects[EFFECT_ID_COUNT];
} Energy;
#include "effect.h"

int checkEffect(CombatEffect *effect) {
  return effect->type == infinite || effect->times > 0;
}

int expendEffect(CombatEffect *effect) {
  if (effect->type == infinite) {
    return 1;
  }
  if (effect->times > 0) {
    effect->times--;
    return 1;
  }
  return 0;
}
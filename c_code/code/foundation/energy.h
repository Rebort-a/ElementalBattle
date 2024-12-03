#ifndef ENERGY_H
#define ENERGY_H

#ifdef __cplusplus
extern "C" {
#endif

#include "effect.h"

typedef enum { METAL, WATER, WOOD, FIRE, EARTH, ENERGY_COUNT } EnergyType;
extern const char *energyNames[ENERGY_COUNT];

enum AttributeType { HP, ATK, DEF, ATTRIBUTE_COUNT };

typedef struct {
  char name[32];
  EnergyType type;
  int level;
  int health;
  int capacityBase;
  int capacityExtra;
  int attackBase;
  int attackOffset;
  int defenceBase;
  int defenceOffset;
  CombatEffect effects[EFFECT_ID_COUNT];
} Energy;

extern void printAttributes(const Energy *energy);
extern void printAttributesBattle(const Energy *source, const Energy *target);

#ifdef __cplusplus
}
#endif

#endif // ENERGY_H
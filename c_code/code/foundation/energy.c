#include "energy.h"
#include "custom.h"

const char *energyNames[ENERGY_COUNT] = {"🔩", "🌊", "🪵", "🔥", "🪨"};

const char *attributeNames[6] = {"name",   "energy", "level",
                                 "health", "attack", "defense"};

void printAttributes(const Energy *energy) {
  customPrintf("%s: %s\n", attributeNames[0], energy->name);
  customPrintf("%s: %s\n", attributeNames[1], energyNames[energy->type]);
  customPrintf("%s: %d\n", attributeNames[2], energy->level);
  customPrintf("%s: %d\n", attributeNames[3], energy->health);
  customPrintf("%s: %d\n", attributeNames[4],
               energy->attackBase + energy->attackOffset);
  customPrintf("%s: %d\n", attributeNames[5],
               energy->defenceBase + energy->defenceOffset);

  customPrintf("\n");
}

void printAttributesBattle(const Energy *source, const Energy *target) {

  int width = 15;

  customPrintf("\n");

  customPrintf("%-*s: %-*s %-*s %-*s: %-*s\n", width, attributeNames[0], 10,
               source->name, 5, "->", width, attributeNames[0], width,
               target->name);
  customPrintf("%-*s: %-*s  %-*s: %-*s\n", width, attributeNames[1], width + 2,
               energyNames[source->type], width, attributeNames[1], width + 2,
               energyNames[target->type]);
  customPrintf("%-*s: %-*d  %-*s: %-*d\n", width, attributeNames[2], width,
               source->level, width, attributeNames[2], width, target->level);
  customPrintf("%-*s: %-*d  %-*s: %-*d\n", width, attributeNames[3], width,
               source->health, width, attributeNames[3], width, target->health);
  customPrintf("%-*s: %-*d  %-*s: %-*d\n", width, attributeNames[4], width,
               source->attackBase + source->attackOffset, width,
               attributeNames[4], width,
               target->attackBase + target->attackOffset);
  customPrintf("%-*s: %-*d  %-*s: %-*d\n", width, attributeNames[5], width,
               source->defenceBase + source->defenceOffset, width,
               attributeNames[5], width,
               target->defenceBase + target->defenceOffset);
  customPrintf("\n");
}
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#include "attribute.h"
#include "custom.h"

void restoreAttributes(Energy *energy) {
  energy->capacityExtra = 0;
  energy->attackOffset = 0;
  energy->defenceOffset = 0;
  energy->health = energy->capacityBase;
}

void restoreEffects(Energy *energy) {
  for (int i = 0; i < EFFECT_ID_COUNT; ++i) {
    energy->effects[i].id = i;
    energy->effects[i].type = limited;
    energy->effects[i].value = 0;
    energy->effects[i].times = 0;
  }
}

void getPresetsAttributes(Energy *energy) {
  restoreEffects(energy);
  switch (energy->type) {
  case METAL:
    energy->capacityBase = 128;
    energy->attackBase = 32;
    energy->defenceBase = 32;
    energy->effects[strengthen].value = 0.5;
    energy->effects[strengthen].type = true;
    break;
  case WATER:
    energy->capacityBase = 160;
    energy->attackBase = 16;
    energy->defenceBase = 64;
    energy->effects[adjustAttribute].value = 0.75;
    energy->effects[adjustAttribute].type = true;
    break;
  case WOOD:
    energy->capacityBase = 256;
    energy->attackBase = 32;
    energy->defenceBase = 16;
    energy->effects[absorbBlood].value = 0.25;
    energy->effects[absorbBlood].type = true;
    break;
  case FIRE:
    energy->capacityBase = 96;
    energy->attackBase = 64;
    energy->defenceBase = 16;
    energy->effects[enchanting].value = 1.0;
    energy->effects[enchanting].type = true;
    break;
  case EARTH:
    energy->capacityBase = 384;
    energy->attackBase = 16;
    energy->defenceBase = 0;
    energy->effects[accumulateAnger].value = 0.5;
    energy->effects[accumulateAnger].type = true;
    break;
  default:
    energy->capacityBase = 128;
    energy->attackBase = 32;
    energy->defenceBase = 32;
    energy->effects[strengthen].value = 0.5;
    energy->effects[strengthen].type = true;
    break;
  }

  restoreAttributes(energy);
}

void upgradeAttributes(Energy *energy, enum AttributeType attribute) {
  energy->level++;
  switch (attribute) {
  case HP:
    energy->capacityBase += 32;
    break;
  case ATK:
    energy->attackBase += 8;
    break;
  case DEF:
    energy->defenceBase += 8;
    break;
  case ATTRIBUTE_COUNT:
  default:
    break;
  }
  restoreAttributes(energy);
}

void upgradeRandom(Energy *energy, int times) {
  for (int i = 0; i < times; i++) {
    upgradeAttributes(energy, rand() % ATTRIBUTE_COUNT);
  }
}

void upgradeChoose(Energy *energy) {
  int choice;
  customPrintf("Choose attribute to upgrade:\n");
  customPrintf("%d. Health\n", HP);
  customPrintf("%d. Attack\n", ATK);
  customPrintf("%d. Defense\n", DEF);
  customPrintf("Enter your choice (%d-%d): ", HP, DEF);
  scanf_s("%d", &choice);

  switch (choice) {
  case HP:
    upgradeAttributes(energy, HP);
    customPrintf("Health upgraded!\n");
    break;
  case ATK:
    upgradeAttributes(energy, ATK);
    customPrintf("Attack upgraded!\n");
    break;
  case DEF:
    upgradeAttributes(energy, DEF);
    customPrintf("Defense upgraded!\n");
    break;
  default:
    upgradeAttributes(energy, HP);
    customPrintf("Invalid choice. Default Health.\n");
    break;
  }
}
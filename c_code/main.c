#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "combat.h"
#include "custom.h"
#include "energy.h"

void restoreAttributes(Energy *energy) {
  energy->capacityExtra = 0;
  energy->attackOffset = 0;
  energy->defenceOffset = 0;
  energy->health = energy->capacityBase;
}

void upgradeAttributes(Energy *energy, enum AttributeType attribute) {
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
  energy->level += times;
}

void getPresetsAttribute(Energy *energy) {

  switch (energy->type) {
  case METAL:
    energy->capacityBase = 128;
    energy->attackBase = 32;
    energy->defenceBase = 32;
    energy->effects[strengthen].id = strengthen;
    energy->effects[strengthen].value = 0.5;
    energy->effects[strengthen].type = true;
    break;
  case WATER:
    energy->capacityBase = 160;
    energy->attackBase = 16;
    energy->defenceBase = 64;
    energy->effects[adjustAttribute].id = adjustAttribute;
    energy->effects[adjustAttribute].value = 0.82;
    energy->effects[adjustAttribute].type = true;
    break;
  case WOOD:
    energy->capacityBase = 256;
    energy->attackBase = 32;
    energy->defenceBase = 16;
    energy->effects[absorbBlood].id = absorbBlood;
    energy->effects[absorbBlood].value = 0.4;
    energy->effects[absorbBlood].type = true;
    break;
  case FIRE:
    energy->capacityBase = 96;
    energy->attackBase = 64;
    energy->defenceBase = 16;
    energy->effects[enchanting].id = enchanting;
    energy->effects[enchanting].value = 1.0;
    energy->effects[enchanting].type = true;
    break;
  case EARTH:
    energy->capacityBase = 384;
    ;
    energy->attackBase = 16;
    energy->defenceBase = 0;
    energy->effects[accumulateAnger].id = accumulateAnger;
    energy->effects[accumulateAnger].value = 0.5;
    energy->effects[accumulateAnger].type = true;
    break;
  default:
    energy->capacityBase = 128;
    energy->attackBase = 32;
    energy->defenceBase = 32;
    energy->effects[strengthen].id = strengthen;
    energy->effects[strengthen].value = 0.5;
    energy->effects[strengthen].type = true;
    break;
  }

  restoreAttributes(energy);
}

int handleBattleOut(Energy *player, Energy *enemy) {
  int fightTimes = 0;
  int result = 0;
  while (fightTimes++ < 100) {
    result = handleCombat(player, enemy);
    if (result) {
      return result;
    }
    result = handleCombat(enemy, player);
    if (result) {
      return -result;
    }
  }
  return 0;
}

void printAllResults() {
  printf("result:\n");
  printf("%-10s", " ");
  for (int i = 0; i < ELEMENT_COUNT; ++i) {
    printf("%-12s", energyNames[i]);
  }
  printf("\n");

  for (int i = 0; i < ELEMENT_COUNT; ++i) {
    printf("%-12s", energyNames[i]);
    for (int j = 0; j < ELEMENT_COUNT; ++j) {

      Energy player = {.type = i};
      Energy enemy = {.type = j};
      getPresetsAttribute(&player);
      getPresetsAttribute(&enemy);

      printf("%-10d", handleBattleOut(&player, &enemy));
      // handleBattleOut(&player, &enemy);
      // printf("%-16d", player.health);
    }
    printf("\n");
  }
}

void printAttributes(const Energy *energy) {
  customPrintf("Name: %s\n", energy->name);
  customPrintf("energy: %s\n", energyNames[energy->type]);
  customPrintf("health: %d\n", energy->health);
  customPrintf("attack: %d\n", energy->attackBase + energy->attackOffset);
  customPrintf("defense: %d\n", energy->defenceBase + energy->defenceOffset);

  customPrintf("\n");
}

typedef enum { ATTACK, PARRY, SKILL, ESCAPE, ACTION_COUNT } Action;

Action getPlayerAction() {
  char command;
  customPrintf(
      "Choose your action: a(attack), p(parry), s(skill), e(escape): ");
  scanf_s(" %c", &command);

  switch (command) {
  case 'a':
    return ATTACK;
  case 'p':
    return PARRY;
  case 's':
    return SKILL;
  case 'e':
    return ESCAPE;
  default:
    customPrintf("Invalid command. Default ATTACK.\n");
    return ATTACK;
  }
}

Action getEnemyAction() {
  float rand_num = (float)rand() / RAND_MAX;
  if (rand_num < 0.8) {
    return ATTACK;
  } else if (rand_num < 0.9) {
    return PARRY;
  } else {
    return SKILL;
  }
}

const char *actionToString(Action action) {
  switch (action) {
  case ATTACK:
    return "ATTACK";
  case PARRY:
    return "PARRY";
  case SKILL:
    return "SKILL";
  case ESCAPE:
    return "ESCAPE";
  case ACTION_COUNT:
  default:
    return "UNKNOWN";
  }
}

int handleAction(Energy *source, Energy *target, Action action) {
  return handleCombat(source, target);
  // switch (action) {

  // case ATTACK:
  //   return handleCombat(source, target);
  // case PARRY:
  //   source->combatEffects[PARRY_STATE].effectValue = 0.75;
  //   source->combatEffects[PARRY_STATE].effectTimes += 1;
  //   break;
  // case SKILL:
  //   return handleSkill(source, target);
  // case ESCAPE:
  //   return -2;
  // default:
  //   return 0;
  // }
}

int handleBattle(Energy *player, Energy *enemy) {

  printAttributes(enemy);

  int result = 0;
  int successively = rand() % 2;
  customPrintf("%s got the lead\n", successively ? "Player" : "Enemy");

  Action playerAction;
  Action enemyAction;

  while (result == 0) {
    if (successively) {
      playerAction = getPlayerAction();
      customPrintf("Player chose %s\n", actionToString(playerAction));
      result = handleAction(player, enemy, playerAction);
      if (result) {
        break;
      }
      enemyAction = getEnemyAction();
      customPrintf("Enemy chose %s\n", actionToString(enemyAction));
      result = -handleAction(enemy, player, enemyAction);
      if (result) {
        break;
      }
    } else {
      enemyAction = getEnemyAction();
      customPrintf("Enemy chose %s\n", actionToString(enemyAction));
      result = -handleAction(enemy, player, enemyAction);
      if (result) {
        break;
      }
      playerAction = getPlayerAction();
      customPrintf("Player chose %s\n", actionToString(playerAction));
      result = handleAction(player, enemy, playerAction);
      if (result) {
        break;
      }
    }
  }

  return result;
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

int main(int argc, char **argv) {
  system("chcp 65001");

  if (argc == 1) {
    flag_debug = 0;
    printAllResults();
  } else if (argc == 2) {
    flag_debug = 1;
    Energy player = {.name = "player", .type = atoi(argv[1]), .level = 0};
    getPresetsAttribute(&player);
    printAttributes(&player);

    Energy enemy = {.name = "enemy"};

    char command;
    srand(time(NULL));

    while (1) {
      customPrintf("Enter command: ");
      scanf_s(" %c", &command);

      switch (command) {
      case 's':
        printAttributes(&player);
        break;
      case 'f':
        enemy.type = rand() % ELEMENT_COUNT;
        getPresetsAttribute(&enemy);
        enemy.level = 0;
        upgradeRandom(&enemy, player.level);
        if (handleBattle(&player, &enemy) > 0) {
          customPrintf("YOU WIN!\n");
        } else {
          customPrintf("YOU LOSE!\n");
        }

        break;
      case 'r':
        restoreAttributes(&player);
        customPrintf("Your status has been restored.\n");
        break;
      case 'u':
        upgradeChoose(&player);
        break;
      case 'q':
        customPrintf("Exiting game.\n");
        return 0;
      default:
        customPrintf("Invalid command. Try again.\n");
        break;
      }
    }
  } else if (argc > 2) {
    flag_debug = 1;
    Energy player = {.name = "player", .type = atoi(argv[1]), .level = 0};
    Energy enemy = {.name = "enemy", .type = atoi(argv[2]), .level = 0};
    getPresetsAttribute(&player);
    getPresetsAttribute(&enemy);
    handleBattleOut(&player, &enemy);
  }

  return 0;
}
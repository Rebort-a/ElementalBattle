#include <stdio.h>
#include <stdlib.h>

#include "action.h"
#include "attribute.h"
#include "battle.h"
#include "combat.h"
#include "custom.h"

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

int handleBattleOut(Energy *player, Energy *enemy) {
  int fightTimes = 0;
  int result = 0;
  while (fightTimes++ < 100) {
    result = handleCombat(player, enemy);
    if (result) {
      break;
    }
    result = handleCombat(enemy, player);
    if (result) {
      break;
    }
  }

  if (enemy->health <= 0) {
    return player->health;
  } else {
    return -enemy->health;
  }

  return 0;
}

void printAllResults() {
  printf("result:\n");
  printf("%-10s", " ");
  for (int i = 0; i < ENERGY_COUNT; ++i) {
    printf("%-12s", energyNames[i]);
  }
  printf("\n");

  for (int i = 0; i < ENERGY_COUNT; ++i) {
    printf("%-12s", energyNames[i]);
    for (int j = 0; j < ENERGY_COUNT; ++j) {
      Energy player = {.type = i};
      Energy enemy = {.type = j};
      getPresetsAttributes(&player);
      getPresetsAttributes(&enemy);
      printf("%-10d", handleBattleOut(&player, &enemy));
    }
    printf("\n");
  }
}
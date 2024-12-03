#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "attribute.h"
#include "battle.h"
#include "custom.h"
#include "run.h"

void runSimulation() {
  flag_debug = false;
  printAllResults();
}

void runInteractiveMode(EnergyType playerType) {
  flag_debug = true;
  Energy player = {.name = "player", .type = playerType, .level = 0};
  getPresetsAttributes(&player);
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
      enemy.type = rand() % ENERGY_COUNT;
      getPresetsAttributes(&enemy);
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
      return;
    default:
      customPrintf("Invalid command. Try again.\n");
      break;
    }
  }
}

void runBattle(EnergyType playerType, EnergyType enemyType) {
  flag_debug = true;
  Energy player = {.name = "player", .type = playerType, .level = 0};
  Energy enemy = {.name = "enemy", .type = enemyType, .level = 0};
  getPresetsAttributes(&player);
  getPresetsAttributes(&enemy);
  handleBattleOut(&player, &enemy);
}
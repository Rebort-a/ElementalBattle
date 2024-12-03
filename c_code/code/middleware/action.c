#include <stdio.h>
#include <stdlib.h>

#include "action.h"
#include "combat.h"
#include "custom.h"

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
  printAttributesBattle(source, target);

  return handleCombat(source, target);
  // switch (action) {

  // case ATTACK:
  //   return handleCombat(source, target);
  // case PARRY:
  //   return handleParry(source, target);
  //   break;
  // case SKILL:
  //   return handleSkill(source, target);
  // case ESCAPE:
  //   return -2;
  // default:
  //   return 0;
  // }
}
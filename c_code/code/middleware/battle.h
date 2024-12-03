#ifndef BATTLE_H
#define BATTLE_H

#ifdef __cplusplus
extern "C" {
#endif

#include "energy.h"

extern int handleBattle(Energy *player, Energy *enemy);
extern int handleBattleOut(Energy *player, Energy *enemy);
extern void printAllResults();

#ifdef __cplusplus
}
#endif

#endif // BATTLE_H
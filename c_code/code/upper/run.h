#ifndef BATTLE_H
#define BATTLE_H

#ifdef __cplusplus
extern "C" {
#endif

#include "energy.h"

extern void runSimulation();
extern void runInteractiveMode(EnergyType playerType);
extern void runBattle(EnergyType playerType, EnergyType enemyType);

#ifdef __cplusplus
}
#endif

#endif // BATTLE_H
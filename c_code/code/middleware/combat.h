#ifndef COMBAT_H
#define COMBAT_H

#ifdef __cplusplus
extern "C" {
#endif

#include "energy.h"

extern int handleCombat(Energy *attacker, Energy *defender);

#ifdef __cplusplus
}
#endif

#endif // COMBAT_H
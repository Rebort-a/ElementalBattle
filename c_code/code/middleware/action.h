#ifndef ACTIONS_H
#define ACTIONS_H

#ifdef __cplusplus
extern "C" {
#endif

#include "energy.h"

typedef enum { ATTACK, PARRY, SKILL, ESCAPE, ACTION_COUNT } Action;

extern Action getPlayerAction();
extern Action getEnemyAction();
extern const char *actionToString(Action action);
extern int handleAction(Energy *source, Energy *target, Action action);

#ifdef __cplusplus
}
#endif

#endif // ACTIONS_H
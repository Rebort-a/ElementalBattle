#ifndef ATTRIBUTES_H
#define ATTRIBUTES_H

#ifdef __cplusplus
extern "C" {
#endif

#include "energy.h"

extern void restoreAttributes(Energy *energy);
extern void upgradeAttributes(Energy *energy, enum AttributeType attribute);
extern void upgradeRandom(Energy *energy, int times);
extern void getPresetsAttributes(Energy *energy);
extern void upgradeChoose(Energy *energy);

#ifdef __cplusplus
}
#endif

#endif // ATTRIBUTES_H
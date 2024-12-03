#ifndef CUSTOM_H
#define CUSTOM_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdbool.h>

extern bool flag_debug;
extern int customPrintf(char *fmt, ...);

#ifdef __cplusplus
}
#endif

#endif // CUSTOM_H
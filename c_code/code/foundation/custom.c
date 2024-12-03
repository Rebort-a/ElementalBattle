#include <stdarg.h>
#include <stdio.h>

#include "custom.h"

bool flag_debug = true;

int customPrintf(char *fmt, ...) {

  if (flag_debug) {
    va_list args;
    int count;
    va_start(args, fmt);
    count = vprintf(fmt, args);
    va_end(args);
    return count;
  } else {
    return 0;
  }
}
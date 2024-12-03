#include <stdlib.h>

#include "custom.h"
#include "run.h"

int main(int argc, char **argv) {
  system("chcp 65001");

  if (argc == 1) {
    flag_debug = false;
    runSimulation();
  } else if (argc == 2) {
    flag_debug = true;
    runInteractiveMode(atoi(argv[1]));
  } else if (argc > 2) {
    flag_debug = true;
    runBattle(atoi(argv[1]), atoi(argv[2]));
  }

  return 0;
}
#include <stdlib.h>

#include "run.h"

int main(int argc, char **argv) {
  system("chcp 65001");

  if (argc == 1) {
    runSimulation();
  } else if (argc == 2) {
    runInteractiveMode(atoi(argv[1]));
  } else if (argc > 2) {
    runBattle(atoi(argv[1]), atoi(argv[2]));
  }

  return 0;
}
#include "combat.h"
#include <stdio.h>

// 主函数示例
int main() {
  // 初始化战斗单位
  Energy attacker = {/* 初始化数据 */};
  Energy defender = {/* 初始化数据 */};

  // 开始战斗
  int result = handleCombat(&attacker, &defender);

  // 输出战斗结果
  if (result != 0) {
    printf("Defender has been defeated.\n");
  } else {
    printf("Defender still stands.\n");
  }

  return 0;
}
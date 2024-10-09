import 'package:flutter/material.dart';
import 'dart:math';

import '../foundation/energy.dart';
import '../foundation/skill.dart';
import '../middleware/common.dart';
import '../middleware/rose.dart';

// 战斗行为类型
enum ActionType { attack, parry, skill, escape }

class CombatLogic {
  final _random = Random(); // 随机生成器

  final AlwaysNotifyValueNotifier<void Function(BuildContext)> showPage =
      AlwaysNotifyValueNotifier((BuildContext context) {}); // 供检测是否需要弹出界面

  final ValueNotifier<String> combatMessage =
      ValueNotifier<String>(' '.padRight(100)); // 供消息区域使用

  final PlayerRose player; // 玩家
  final EnemyRose enemy; // 敌人
  final bool offensive; // 先手

  ResultType combatResult = ResultType.continued; // 保存战斗结果

  CombatLogic(
      {required this.player, required this.enemy, required this.offensive}) {
    // 战斗开始前，施加所有已学习的被动技能效果
    _handlePassiveEffect(player.energies[player.current]);
    _handlePassiveEffect(enemy.energies[enemy.current]);
    if (offensive) {
      combatMessage.value += ("\n你获得了先手\n");
    } else {
      combatMessage.value += ("\n敌人获得了先手\n");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleEnemyAction();
      });
    }
  }

  _handlePassiveEffect(Energy energy) {
    for (var skill in energy.skills) {
      if ((skill.type == SkillType.passive) && skill.learned) {
        energy.sufferSkill(skill);
      }
    }
  }

  conductAttack() {
    _handlePlayerAction(ActionType.attack);
  }

  conductParry() {
    _handlePlayerAction(ActionType.parry);
  }

  conductSkill() {
    _handlePlayerAction(ActionType.skill);
  }

  conductEscape() {
    _handlePlayerAction(ActionType.escape);
  }

  _handlePlayerAction(ActionType command) {
    if (combatResult != ResultType.continued) {
      showPage.value = (BuildContext context) {
        _navigateToHomePage(context, combatResult);
      };
    } else {
      combatMessage.value += ('\n玩家选择了$command\n');
      switch (command) {
        case ActionType.attack:
          int result = EnergyCombat(
            source: player.energies[player.current],
            target: enemy.energies[enemy.current],
            message: combatMessage,
          ).result;
          player.updateEnergy();
          enemy.updateEnergy();
          _handleCombatResult(result);
          if (combatResult == ResultType.continued) {
            _handleEnemyAction();
          }
          break;
        case ActionType.parry:
          _handlePlayerSkillTarget(SkillCollection.baseParry);
          break;
        case ActionType.skill:
          showPage.value = (BuildContext context) {
            SelectSkill(
                context: context,
                energy: player.energies[player.current],
                handleSkill: _handlePlayerSkillTarget);
          };
          break;
        case ActionType.escape:
          _handleCombatResult(-2);
          break;
      }
    }
  }

  _handlePlayerSkillTarget(CombatSkill skill) {
    switch (skill.targetType) {
      case SkillTarget.selfFront:
        _handlePlayerSkill(skill, player, player.current);
        break;
      case SkillTarget.selfAny:
        showPage.value = (BuildContext context) {
          SelectEnergy(
              context: context,
              elemental: player,
              onSelected: (int index) {
                _handlePlayerSkill(skill, player, index);
              },
              available: true);
        };
        break;
      case SkillTarget.enemyFront:
        _handlePlayerSkill(skill, enemy, enemy.current);
        break;
      case SkillTarget.enemyAny:
        showPage.value = (BuildContext context) {
          SelectEnergy(
              context: context,
              elemental: enemy,
              onSelected: (int index) {
                _handlePlayerSkill(skill, enemy, index);
              },
              available: true);
        };
        break;
      default:
        break;
    }
  }

  _handlePlayerSkill(CombatSkill skill, Rose targetRose, int targetIndex) {
    int result = 0;
    targetRose.sufferSkill(targetIndex, skill);
    combatMessage.value +=
        ('${player.energies[player.current].name} 施放了 ${skill.name}, ${targetRose.energies[targetIndex].name} 获得效果 ${skill.description}\n');

    if (skill.id == SkillID.parry) {
      player.switchAppoint(targetIndex);
      _handlePassiveEffect(player.energies[player.current]);
      combatMessage.value +=
          '${player.name} 切换为 ${targetRose.energies[targetIndex].name}\n';
    } else if (skill.id == SkillID.woodActive_0) {
      int recovery =
          (targetRose.energies[targetIndex].capacity * 0.125).round();
      targetRose.recoverHealth(targetIndex, recovery);
      combatMessage.value +=
          ('${targetRose.energies[targetIndex].name} 回复了 $recovery 生命值❤️‍🩹, 当前生命值为 ${targetRose.energies[targetIndex].health}\n');
      player.updateEnergy();
    } else if (skill.id == SkillID.fireActive_0) {
      player.switchAppoint(targetIndex);
      _handlePassiveEffect(player.energies[player.current]);
      combatMessage.value +=
          '${player.name} 切换为 ${targetRose.energies[targetIndex].name}\n';

      result = EnergyCombat(
        source: player.energies[player.current],
        target: enemy.energies[enemy.current],
        message: combatMessage,
      ).result;
      player.updateEnergy();
      enemy.updateEnergy();
    }

    _handleCombatResult(result);
    if (combatResult == ResultType.continued) {
      _handleEnemyAction();
    }
  }

  ActionType _getEnemyAction() {
    // 敌方的行为是根据概率随机的
    int randVal = _random.nextInt(1000);
    if (randVal < 50) {
      return ActionType.parry;
    } else {
      return ActionType.attack;
    }
  }

  _handleEnemyAction() {
    ActionType command = _getEnemyAction();
    combatMessage.value += ('敌人选择了$command\n');
    switch (command) {
      case ActionType.attack:
        _handleCombatResult(-EnergyCombat(
          source: enemy.energies[enemy.current],
          target: player.energies[player.current],
          message: combatMessage,
        ).result);
        player.updateEnergy();
        enemy.updateEnergy();
        break;
      case ActionType.parry:
        enemy.sufferSkill(0, SkillCollection.baseParry);
        break;
      case ActionType.skill:
        _handleCombatResult(_handleEnemySkill());
        break;
      case ActionType.escape:
        _handleCombatResult(2);
        break;
    }
  }

  int _handleEnemySkill() {
    int result = 0;
    CombatSkill skill = SkillCollection
        .totalSkills[enemy.energies[enemy.current].type.index][1];
    Energy targetElemental =
        (enemy.energies[enemy.current].type == EnergyType.water)
            ? player.energies[player.current]
            : enemy.energies[enemy.current];
    combatMessage.value +=
        ('${enemy.energies[enemy.current].name} 施放了${skill.name}, $targetElemental 获得效果${skill.description}\n');

    targetElemental.sufferSkill(skill);

    switch (enemy.energies[enemy.current].type) {
      case EnergyType.wood:
        int recovery = (enemy.energies[enemy.current].capacity * 0.125).round();
        combatMessage.value +=
            ('${enemy.energies[enemy.current].name} 回复了 $recovery 生命值❤️‍🩹, 当前生命值为 ${enemy.energies[enemy.current].health}\n');
        enemy.energies[enemy.current].recoverHealth(recovery);
        enemy.updateEnergy();
        break;
      case EnergyType.fire:
        result = EnergyCombat(
          source: enemy.energies[enemy.current],
          target: player.energies[player.current],
          message: combatMessage,
        ).result;
        player.updateEnergy();
        enemy.updateEnergy();
      default:
        break;
    }
    return result;
  }

  switchEnemyNext() {
    enemy.switchNext();
    _handlePassiveEffect(enemy.energies[enemy.current]);
  }

  switchPlayerNext() {
    player.switchNext();
    _handlePassiveEffect(player.energies[player.current]);
  }

  _handleCombatResult(int result) {
    if (result == 1) {
      switchEnemyNext();
      if (enemy.energies[enemy.current].health > 0) {
        result = 0;
        combatMessage.value +=
            '${enemy.name} 切换为 ${energyNames[enemy.energies[enemy.current].type.index]}\n';

        showPage.value = (BuildContext context) {
          SnackBarMessage(context,
              '连一刻都没有为 ${enemy.energies[enemy.current].name} 的死亡哀悼，立刻赶到战场的是${enemy.energies[enemy.current].name}');
        };
      }
    } else if (result == -1) {
      switchPlayerNext();
      if (player.energies[player.current].health > 0) {
        _handlePassiveEffect(player.energies[player.current]);
        result = 0;

        combatMessage.value +=
            '${player.name} 切换为 ${energyNames[player.energies[player.current].type.index]}\n';

        showPage.value = (BuildContext context) {
          SnackBarMessage(
              context, '玩家切换为 ${player.energies[player.current].name}');
        };
      }
    }
    _handleResult(result);
  }

  _handleResult(int result) {
    switch (result) {
      case 1:
        combatResult = ResultType.victory;
        player.experience += 10 + 2 * enemy.level;
        showPage.value = _showResult;
        break;
      case -1:
        combatResult = ResultType.defeat;
        player.experience -= 5;
        showPage.value = _showResult;
        break;
      case -2:
        combatResult = ResultType.escape;
        player.experience -= 2;
        showPage.value = _showResult;
        break;
      case 2:
        combatResult = ResultType.draw;
        showPage.value = _showResult;
        break;
    }
  }

  _showResult(BuildContext context) {
    String title;
    String content;

    switch (combatResult) {
      case ResultType.victory:
        title = '胜利';
        content = '你获得了胜利';
        break;
      case ResultType.defeat:
        title = '失败';
        content = '你失败了';
        break;
      case ResultType.escape:
        title = '逃跑';
        content = '你逃跑了';
        break;
      case ResultType.draw:
        title = '快追';
        content = '敌人逃跑了';
        break;
      default:
        title = '';
        content = '';
        break;
    }

    DiaglogMessage(context, title, content, () => {}, () {
      _navigateToHomePage(context, combatResult);
    });
  }

  _navigateToHomePage(BuildContext context, ResultType combatResult) {
    showPage.value = (BuildContext context) {
      Navigator.pop(context, combatResult);
    };
  }
}

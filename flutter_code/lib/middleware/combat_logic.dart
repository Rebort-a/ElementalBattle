import 'package:flutter/material.dart';
import 'dart:math';

import '../foundation/energy.dart';
import '../foundation/skill.dart';
import 'common.dart';
import 'elemental.dart';
import 'player.dart';

// 战斗行为类型
enum ActionType { attack, parry, skill, escape }

class CombatLogic {
  final _random = Random(); // 随机生成器

  final AlwaysValueNotifier<void Function(BuildContext)> showPage =
      AlwaysValueNotifier((BuildContext context) {}); // 供检测是否需要弹出界面

  final ValueNotifier<String> combatMessage =
      ValueNotifier<String>(' '.padRight(100)); // 供消息区域使用

  final PlayerElemental player; // 玩家
  final EnemyElemental enemy; // 敌人
  final bool offensive; // 先手

  ResultType combatResult = ResultType.continued; // 保存战斗结果

  CombatLogic(
      {required this.player, required this.enemy, required this.offensive}) {
    // 战斗开始前，为当前Energy施加所有已学习的被动技能效果

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePassiveEffect(player);
      _handlePassiveEffect(enemy);
      _handleUpdateAttribute();
      if (offensive) {
        combatMessage.value += ("\n你获得了先手\n");
      } else {
        combatMessage.value += ("\n敌人获得了先手\n");
        _handleEnemyAction();
      }
    });
  }

  void _handlePassiveEffect(Elemental elemental) {
    for (var skill in elemental.energies[elemental.current].skills) {
      if ((skill.type == SkillType.passive) && skill.learned) {
        elemental.sufferSkill(elemental.current, skill);
      }
    }
  }

  void _switchAppoint(Elemental elemental, int index) {
    elemental.switchAppoint(index);
    _handlePassiveEffect(elemental);
    _handleUpdateAttribute();
    combatMessage.value +=
        '${elemental.name} 切换为 ${energyNames[elemental.energies[elemental.current].type.index]}\n';
  }

  int _switchNext(Elemental elemental, int result) {
    String lastName = elemental.energies[elemental.current].name;
    elemental.switchNext();
    _handlePassiveEffect(elemental);
    if (elemental.energies[elemental.current].health > 0) {
      _handleUpdateAttribute();
      combatMessage.value +=
          '${elemental.name} 切换为 ${energyNames[elemental.energies[elemental.current].type.index]}\n';

      showPage.value = (BuildContext context) {
        SnackBarMessage(context,
            '连一刻都没有为 $lastName 的死亡哀悼，立刻赶到战场的是 ${elemental.energies[elemental.current].name}');
      };
      result = 0;
    }
    return result;
  }

  void conductAttack() {
    _handlePlayerAction(ActionType.attack);
  }

  void conductParry() {
    _handlePlayerAction(ActionType.parry);
  }

  void conductSkill() {
    _handlePlayerAction(ActionType.skill);
  }

  void conductEscape() {
    _handlePlayerAction(ActionType.escape);
  }

  void _handlePlayerAction(ActionType command) {
    if (combatResult != ResultType.continued) {
      showPage.value = (BuildContext context) {
        _navigateToHomePage(context, combatResult);
      };
    } else {
      combatMessage.value += ('\n玩家选择了$command\n');
      switch (command) {
        case ActionType.attack:
          _handleCombatResult(
              player.battleWith(enemy, enemy.current, combatMessage));
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

  void _handlePlayerSkillTarget(CombatSkill skill) {
    switch (skill.targetType) {
      case SkillTarget.selfFront:
        _handlePlayerSkill(skill, player, player.current);
        break;
      case SkillTarget.selfAny:
        showPage.value = (BuildContext context) {
          SelectEnergy(
              context: context,
              energies: player.energies,
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
              energies: enemy.energies,
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

  void _handlePlayerSkill(
      CombatSkill skill, Elemental targetElemental, int targetIndex) {
    int result = 0;

    targetElemental.sufferSkill(targetIndex, skill);

    combatMessage.value +=
        ('${player.energies[player.current].name} 施放了 ${skill.name}, ${targetElemental.energies[targetIndex].name} 获得效果 ${skill.description}\n');

    if (skill.id == SkillID.parry) {
      _switchAppoint(targetElemental, targetIndex);
    } else if (skill.id == SkillID.woodActive_0) {
      result = player.battleWith(targetElemental, targetIndex, combatMessage);
    } else if (skill.id == SkillID.fireActive_0) {
      _switchAppoint(targetElemental, targetIndex);
      result = player.battleWith(enemy, enemy.current, combatMessage);
    }

    _handleCombatResult(result);
    if (combatResult == ResultType.continued) {
      _handleEnemyAction();
    }
  }

  ActionType _getEnemyAction() {
    // 敌方的行为是根据概率随机的
    int randVal = _random.nextInt(128);
    if (randVal < 1) {
      return ActionType.escape;
    } else if (randVal < 16) {
      return ActionType.parry;
    } else if (randVal < 32) {
      return ActionType.skill;
    } else {
      return ActionType.attack;
    }
  }

  void _handleEnemyAction() {
    ActionType command = _getEnemyAction();
    combatMessage.value += ('敌人选择了$command\n');
    switch (command) {
      case ActionType.attack:
        _handleCombatResult(
            -enemy.battleWith(player, player.current, combatMessage));
        break;
      case ActionType.parry:
        enemy.sufferSkill(enemy.current, SkillCollection.baseParry);
        combatMessage.value +=
            ('${enemy.energies[enemy.current].name} 施放了${SkillCollection.baseParry.name}, ${enemy.energies[enemy.current].name} 获得效果 ${SkillCollection.baseParry.description}\n');
        break;
      case ActionType.skill:
        _handleEnemySkill();
        break;
      case ActionType.escape:
        _handleCombatResult(2);
        break;
    }
  }

  void _handleEnemySkill() {
    CombatSkill skill = SkillCollection
        .totalSkills[enemy.energies[enemy.current].type.index][1];

    Energy targetEnergy = (skill.targetType == SkillTarget.selfFront)
        ? enemy.energies[enemy.current]
        : player.energies[player.current];

    int result = 0;

    targetEnergy.sufferSkill(skill);

    combatMessage.value +=
        ('${enemy.energies[enemy.current].name} 施放了${skill.name}, ${targetEnergy.name} 获得效果 ${skill.description}\n');

    if (skill.id == SkillID.woodActive_0) {
      result = enemy.battleWith(enemy, enemy.current, combatMessage);
    } else if (skill.id == SkillID.fireActive_0) {
      result = enemy.battleWith(player, player.current, combatMessage);
    }

    _handleCombatResult(-result);
  }

  void _handleUpdateAttribute() {
    int playerAttack = EnergyCombat.handleAttackEffect(
        player.energies[player.current], enemy.energies[enemy.current], false);

    int playerDefence = EnergyCombat.handleDefenceEffect(
        enemy.energies[enemy.current], player.energies[player.current], false);

    int enemyAttack = EnergyCombat.handleAttackEffect(
        enemy.energies[enemy.current], player.energies[player.current], false);

    int enemyDefence = EnergyCombat.handleDefenceEffect(
        player.energies[player.current], enemy.energies[enemy.current], false);

    player.preview.updateInferenceInfo(playerAttack, playerDefence);

    enemy.preview.updateInferenceInfo(enemyAttack, enemyDefence);
  }

  void _handleCombatResult(int result) {
    _handleUpdateAttribute();

    if (result == 1) {
      result = _switchNext(enemy, result);
    } else if (result == -1) {
      result = _switchNext(player, result);
    }
    switch (result) {
      case 1:
        combatResult = ResultType.victory;
        player.experience += 10 + 2 * enemy.level;
        showPage.value = _showCombatResult;
        break;
      case -1:
        combatResult = ResultType.defeat;
        player.experience -= 5;
        showPage.value = _showCombatResult;
        break;
      case -2:
        combatResult = ResultType.escape;
        player.experience -= 2;
        showPage.value = _showCombatResult;
        break;
      case 2:
        combatResult = ResultType.draw;
        showPage.value = _showCombatResult;
        break;
    }
  }

  _showCombatResult(BuildContext context) {
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

    DialogMessage(context, title, content, () {
      return true;
    }, () {
      _navigateToHomePage(context, combatResult);
    }, () => {});
  }

  _navigateToHomePage(BuildContext context, ResultType combatResult) {
    showPage.value = (BuildContext context) {
      Navigator.pop(context, combatResult);
    };
  }
}

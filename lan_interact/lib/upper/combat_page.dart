import 'package:flutter/material.dart';

import '../foundation/energy.dart';

import '../foundation/network.dart';
import '../middleware/game_manager.dart';
import '../middleware/elemental.dart';

class CombatPage extends StatelessWidget {
  final GameManager gameManager;

  const CombatPage({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("战斗"),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return _buildCombat();
  }

  Widget _buildCombat() {
    return Column(
      children: [
        // 弹出页面
        _buildDialog(),
        // 信息区域
        _buildInfoRegion(),
        // 消息区域
        _buildMessageRegion(),
        // 按键区域
        _buildButtonRegion(),
        Expanded(child: _buildMessageList()),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildDialog() {
    return ValueListenableBuilder<void Function(BuildContext)>(
      valueListenable: gameManager.showPage,
      builder: (context, value, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          value(context);
          gameManager.showPage.value = (BuildContext context) {};
        });
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildInfoRegion() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPlayerInfo()),
        Expanded(child: _buildEnemyInfo()),
      ],
    );
  }

  Widget _buildPlayerInfo() {
    return BattleInfoRegion(info: gameManager.player.preview);
  }

  Widget _buildEnemyInfo() {
    return BattleInfoRegion(info: gameManager.enemy.preview);
  }

  Widget _buildMessageRegion() {
    return Expanded(
      child: ValueListenableBuilder<String>(
        valueListenable: gameManager.infoList,
        builder: (context, value, child) {
          return BattleMessageRegion(infoList: value);
        },
      ),
    );
  }

  Widget _buildButtonRegion() {
    return BattleButtonRegion(gameManager: gameManager);
  }

  Widget _buildMessageList() {
    return ValueListenableBuilder<List<NetworkMessage>>(
      valueListenable: gameManager.messageList,
      builder: (context, value, child) {
        return ListView.builder(
          controller: gameManager.scrollController,
          itemCount: value.length,
          itemBuilder: (context, index) {
            return _buildMessageCard(value[index]);
          },
        );
      },
    );
  }

  Widget _buildMessageCard(NetworkMessage message) {
    bool isCurrentUser = (message.clientIdentify == gameManager.playerIdentify);
    bool isNotify = message.type == MessageType.searching;

    AlignmentGeometry alignment = isNotify
        ? Alignment.center
        : isCurrentUser
            ? Alignment.centerRight
            : Alignment.centerLeft;
    Function()? onClick;
    Color backgroundColor = isNotify
        ? Colors.transparent
        : isCurrentUser
            ? Colors.blue
            : Colors.blueGrey;
    Color foregroundColor = isNotify
        ? Colors.brown
        : isCurrentUser
            ? Colors.white
            : Colors.white;
    String textData = isNotify
        ? '${message.source} ${message.content}'
        : isCurrentUser
            ? message.content
            : '${message.source} : ${message.content}';
    IconData? iconData;
    double elevation = isNotify ? 0.0 : 4.0;

    switch (message.type) {
      case MessageType.notify:
        iconData = Icons.notifications;
        break;
      case MessageType.text:
        iconData = null;
        break;
      case MessageType.image:
        iconData = Icons.image;
        break;
      case MessageType.file:
        iconData = Icons.insert_drive_file;
        break;
      default:
        break;
    }

    return Align(
      alignment: alignment,
      child: InkWell(
        onTap: onClick,
        child: Card(
          elevation: elevation,
          color: backgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconData != null)
                  Icon(iconData, color: foregroundColor, size: 20.0),
                const SizedBox(width: 8.0),
                Flexible(
                  child: Text(
                    textData,
                    style: TextStyle(color: foregroundColor),
                  ),
                ),
                // const SizedBox(width: 8.0),
                // Text(
                //   message.timestamp,
                //   style: TextStyle(
                //     color: foregroundColor.withOpacity(0.6),
                //     fontSize: 12.0,
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.attachment),
            onPressed: () {}, // Placeholder for file attachment
          ),
          Expanded(
            child: TextField(
              controller: gameManager.inputController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Type a message',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: gameManager.sendEnter,
          ),
        ],
      ),
    );
  }
}

class BattleInfoRegion extends StatelessWidget {
  final ElementalPreview info;

  const BattleInfoRegion({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildInfoRow(_buildInfoName(), _buildInfoEmoji()),
        _buildInfoRow(_buildInfoLabel('等级'), _buildInfoNotifier(info.level)),
        _buildInfoRow(_buildInfoLabel('生命值'), _buildInfoNotifier(info.health)),
        _buildInfoRow(_buildInfoLabel('攻击力'), _buildInfoNotifier(info.attack)),
        _buildInfoRow(_buildInfoLabel('防御力'), _buildInfoNotifier(info.defence)),
        _buildGlobalStatus(),
      ],
    );
  }

  Widget _buildInfoRow(Widget title, Widget content) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [title],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [content],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoName() {
    return ValueListenableBuilder(
      valueListenable: info.name,
      builder: (context, value, child) {
        return Text(value);
      },
    );
  }

  Widget _buildInfoEmoji() {
    return ValueListenableBuilder(
      valueListenable: info.emoji,
      builder: (context, value, child) {
        return _getCombatEmoji(value);
      },
    );
  }

  static Widget _getCombatEmoji(double emoji) {
    if (emoji < 0.125) {
      return const Text('😢');
    } else if (emoji < 0.25) {
      return const Text('😞');
    } else if (emoji < 0.5) {
      return const Text('😮');
    } else if (emoji < 0.75) {
      return const Text('😐');
    } else if (emoji < 0.875) {
      return const Text('😊');
    } else {
      return const Text('😎');
    }
  }

  Widget _buildInfoLabel(String label) {
    return Text('$label: ');
  }

  Widget _buildInfoNotifier(ValueNotifier<int> notifier) {
    return ValueListenableBuilder<int>(
      valueListenable: notifier,
      builder: (context, value, child) {
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: value.toDouble(), end: value.toDouble()),
          duration: const Duration(milliseconds: 500),
          builder: (context, double value, child) {
            return Text('${value.toInt()}', key: ValueKey<int>(value.toInt()));
          },
        );
      },
    );
  }

  Widget _buildGlobalStatus() {
    return ValueListenableBuilder(
      valueListenable: info.resumes,
      builder: (context, List<EnergyResume> resumes, child) {
        final front = resumes.isNotEmpty
            ? _buildElementBox(resumes.first)
            : const SizedBox.shrink();
        final backend = resumes.length > 1
            ? Wrap(children: resumes.skip(1).map(_buildElementBox).toList())
            : const SizedBox.shrink();

        return Column(children: [front, backend]);
      },
    );
  }

  Widget _buildElementBox(EnergyResume resume) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: resume.health > 0 ? Colors.blue : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(energyNames[resume.type.index]),
    );
  }
}

class BattleMessageRegion extends StatelessWidget {
  final String infoList;

  const BattleMessageRegion({super.key, required this.infoList});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10.0),
      ),
      // 使用SizedBox来限制高度
      child: SizedBox(
        height: 200, // 设置一个固定的高度
        child: SingleChildScrollView(
          reverse: true,
          child: Text(infoList, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class BattleButtonRegion extends StatelessWidget {
  final GameManager gameManager;

  const BattleButtonRegion({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButton("进攻", gameManager.conductAttack),
        _buildButton("格挡", gameManager.conductParry),
        _buildButton("技能", gameManager.conductSkill),
        _buildButton("逃跑", gameManager.conductEscape),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(onPressed: onPressed, child: Text(text));
  }
}

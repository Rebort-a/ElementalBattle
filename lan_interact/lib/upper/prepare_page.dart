import 'package:flutter/material.dart';

import '../middleware/common.dart';
import '../middleware/game_manager.dart';

class PreparePage extends StatelessWidget {
  final RoomInfo roomInfo;
  final String userName;
  late final GameManager gameManager;

  PreparePage({super.key, required this.roomInfo, required this.userName}) {
    gameManager = GameManager(roomInfo: roomInfo, userName: userName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('战斗准备')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ValueListenableBuilder<GameStep>(
      valueListenable: gameManager.gameStep,
      builder: (context, value, _) {
        String statusMessage = _getStatusMessage(value);

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDialog(),
              if (value == GameStep.disconnect || value == GameStep.connected)
                const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(statusMessage),
              const SizedBox(height: 20),
              if (value == GameStep.frontConfig || value == GameStep.rearConfig)
                ElevatedButton(
                  onPressed: () => gameManager.navigateToCastPage(),
                  child: const Text('配置角色'),
                ),
              const SizedBox(height: 20),
              if (value == GameStep.rearConfig)
                ElevatedButton(
                  onPressed: () => gameManager.navigateToStatePage(),
                  child: const Text('查看对手信息'),
                ),
            ],
          ),
        );
      },
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

  String _getStatusMessage(GameStep gameStep) {
    switch (gameStep) {
      case GameStep.disconnect:
        return "等待连接";
      case GameStep.connected:
        return "已连接，等待对手加入...";
      case GameStep.frontConfig:
        return "请配置";
      case GameStep.rearWait:
        return "等待先手配置";
      case GameStep.frontWait:
        return "等待后手配置";
      case GameStep.rearConfig:
        return "请配置或查看对方配置";
      default:
        return "战斗结束";
    }
  }
}

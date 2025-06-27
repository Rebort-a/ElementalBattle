import 'package:flutter/material.dart';

import '../../middleware/back_end.dart';
import '../../middleware/front_end.dart';
import 'chat_manager.dart';

class ChatPage extends StatelessWidget {
  late final ChatManager _chatManager;
  final String userName;
  final RoomInfo roomInfo;

  ChatPage({
    super.key,
    required this.userName,
    required this.roomInfo,
  }) {
    _chatManager = ChatManager(userName: userName, roomInfo: roomInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(roomInfo.name),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _chatManager.networkEngine.leavePage,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.video_call),
          onPressed: () {}, // Placeholder for video call
        ),
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () {}, // Placeholder for audio call
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildDialog(),
        Expanded(child: MessageList(networkEngine: _chatManager.networkEngine)),
        MessageInput(networkEngine: _chatManager.networkEngine),
      ],
    );
  }

  Widget _buildDialog() {
    return ValueListenableBuilder<void Function(BuildContext)>(
      valueListenable: _chatManager.showPage,
      builder: (context, value, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          value(context);
        });
        return const SizedBox.shrink();
      },
    );
  }
}

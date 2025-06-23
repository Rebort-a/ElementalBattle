import 'package:flutter/material.dart';

import '../foundation/models.dart';
import '../middleware/chat_manager.dart';

class ChatPage extends StatelessWidget {
  late final ChatManager _chatManager;
  final RoomInfo roomInfo;
  final String userName;

  ChatPage({super.key, required this.roomInfo, required this.userName}) {
    _chatManager = ChatManager(roomInfo, userName);
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
        onPressed: _chatManager.leaveRoom,
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
        Expanded(
          child: _buildMessageList(),
        ),
        _buildMessageInput(),
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

  Widget _buildMessageList() {
    return ValueListenableBuilder<List<ChatMessage>>(
      valueListenable: _chatManager.messageList,
      builder: (context, value, child) {
        return ListView.builder(
          controller: _chatManager.scrollController,
          itemCount: value.length,
          itemBuilder: (context, index) {
            return _buildMessageCard(value[index]);
          },
        );
      },
    );
  }

  Widget _buildMessageCard(ChatMessage message) {
    bool isCurrentUser =
        (message.uuid == _chatManager.uuid) && (message.source == userName);
    bool isNotify = message.type == MessageType.notify;

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
              controller: _chatManager.textController,
              decoration:
                  const InputDecoration.collapsed(hintText: 'Type a message'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _chatManager.sendEnter,
          ),
        ],
      ),
    );
  }
}

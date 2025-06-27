import 'package:flutter/material.dart';

import '../foundation/network.dart';
import 'back_end.dart';

ThemeData globalTheme = ThemeData(primarySwatch: Colors.blue);

class TemplateDialog {
  static void confirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    required bool Function() before,
    required VoidCallback onTap,
    required VoidCallback after,
  }) {
    if (before()) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              TextButton(
                child: const Text('关闭'),
                onPressed: () {
                  Navigator.of(context).pop();
                  onTap();
                },
              ),
            ],
          );
        },
      ).then((value) {
        after();
      });
    }
  }

  static void inputDialog({
    required BuildContext context,
    required String title,
    required String hintText,
    required String confirmButtonText,
    required Function(String input) onConfirm,
  }) {
    String input = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text(title)),
          content: TextField(
            onChanged: (value) {
              input = value;
            },
            decoration: InputDecoration(hintText: hintText),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(confirmButtonText),
              onPressed: () {
                if (input.isNotEmpty) {
                  Navigator.of(context).pop();
                  onConfirm(input);
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static void optionDialog<T>({
    required BuildContext context,
    required String title,
    required String hintText,
    required String confirmButtonText,
    required List<T> options,
    required Function(String input, T type) onConfirm,
  }) {
    String input = '';
    T selectedOption = options.first; // 默认选择第一个选项

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text(title)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 通用下拉框
              DropdownButtonFormField<T>(
                value: selectedOption,
                onChanged: (T? newValue) {
                  if (newValue != null) {
                    selectedOption = newValue;
                  }
                },
                items: options.map((T option) {
                  return DropdownMenuItem<T>(
                    value: option,
                    child: Text(option.toString().split('.').last),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Select Option',
                ),
              ),
              const SizedBox(height: 16),
              // 输入框
              TextField(
                onChanged: (value) {
                  input = value;
                },
                decoration: InputDecoration(hintText: hintText),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(confirmButtonText),
              onPressed: () {
                if (input.isNotEmpty) {
                  Navigator.of(context).pop();
                  onConfirm(input, selectedOption);
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static void snackBarDialog(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

class RoomDialog {
  static void showCreateRoomDialog({
    required BuildContext context,
    required Function(String roomName, RoomType roomType) onConfirm,
  }) {
    TemplateDialog.optionDialog<RoomType>(
      context: context,
      title: 'Create',
      hintText: 'Enter room name',
      confirmButtonText: 'Create',
      options: RoomType.values,
      onConfirm: onConfirm,
    );
  }

  static void showJoinRoomDialog({
    required BuildContext context,
    required RoomInfo room,
    required Function(RoomInfo room, String userName, BuildContext context)
        onConfirm,
  }) {
    TemplateDialog.inputDialog(
      context: context,
      title: 'Join',
      hintText: 'Enter user name',
      confirmButtonText: 'Join',
      onConfirm: (userName) => onConfirm(room, userName, context),
    );
  }

  static void showLeaveRoomDialog({
    required BuildContext context,
    required RoomInfo room,
    required Function() onConfirm,
  }) {
    TemplateDialog.confirmDialog(
      context: context,
      title: '离开',
      content: '即将退出房间',
      before: () => true,
      onTap: () {
        onConfirm();
      },
      after: () {},
    );
  }
}

class MessageList extends StatelessWidget {
  final NetworkEngine networkEngine;

  const MessageList({
    super.key,
    required this.networkEngine,
  });

  @override
  Widget build(BuildContext context) {
    return _buildMessageList();
  }

  Widget _buildMessageList() {
    return ValueListenableBuilder<List<NetworkMessage>>(
      valueListenable: networkEngine.messageList,
      builder: (context, value, child) {
        return ListView.builder(
          controller: networkEngine.scrollController,
          itemCount: value.length,
          itemBuilder: (context, index) {
            return _buildMessageCard(value[index]);
          },
        );
      },
    );
  }

  Widget _buildMessageCard(NetworkMessage message) {
    bool isCurrentUser = (message.id == networkEngine.identify) &&
        (message.source == networkEngine.userName);
    bool isNotify = message.type == MessageType.notify ||
        message.type == MessageType.searching;

    AlignmentGeometry alignment = isNotify
        ? Alignment.center
        : isCurrentUser
            ? Alignment.centerRight
            : Alignment.centerLeft;

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
      case MessageType.searching:
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
            ],
          ),
        ),
      ),
    );
  }
}

class MessageInput extends StatelessWidget {
  final NetworkEngine networkEngine;

  const MessageInput({super.key, required this.networkEngine});

  @override
  Widget build(BuildContext context) {
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
              controller: networkEngine.textController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Type a message',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: networkEngine.sendInputText,
          ),
        ],
      ),
    );
  }
}

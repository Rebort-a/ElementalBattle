import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/model.dart';
import '../foundation/network.dart';
import '../middleware/common.dart';
import '../middleware/dialog.dart';

class ChatManager {
  final AlwaysNotifier<void Function(BuildContext)> showPage =
      AlwaysNotifier<void Function(BuildContext)>((_) {});

  final ListNotifier<NetworkMessage> messageList = ListNotifier([]);

  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  late final Socket _socket;
  int identify = 0;

  final RoomInfo roomInfo;
  final String userName;

  ChatManager(this.roomInfo, this.userName) {
    messageList.addCallBack(_scrollToBottom);
    _connectToServer();
    _startKeyboard();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _connectToServer() async {
    try {
      _socket = await Socket.connect(roomInfo.address, roomInfo.port);
      _socket.listen(
        _handleSocketData,
        onError: _handleDisconnect,
        onDone: leaveRoom,
      );
    } catch (e) {
      _handleError("Failed to connect to server", e);
    }
  }

  void _startKeyboard() {
    HardwareKeyboard.instance.addHandler(_handleChatKeyboardEvent);
  }

  bool _handleChatKeyboardEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      sendEnter();
      return true;
    }
    return false;
  }

  void sendEnter() {
    final text = textController.text;
    if (text.isEmpty) {
      return;
    }

    _sendNetworkMessage(MessageType.text, text);

    textController.clear();
  }

  void _handleSocketData(List<int> data) {
    try {
      final message = NetworkMessage.fromSocket(data);
      print(
          "${message.source} ${message.id} ${message.type} ${message.content}");
      _processMessage(message);
    } catch (e) {
      _handleError("Failed to parse network message", e);
    }
  }

  void _processMessage(NetworkMessage message) {
    switch (message.type) {
      case MessageType.accept:
        _handleAcceptMessage(message);
        break;
      case MessageType.notify:
      case MessageType.text:
      case MessageType.image:
      case MessageType.file:
        messageList.add(message);
        break;
      default:
        break;
    }
  }

  void _handleAcceptMessage(NetworkMessage message) {
    if (identify == 0) {
      identify = message.id;
      _sendNetworkMessage(MessageType.notify, "join room success");
    }
  }

  void _handleDisconnect(Object e) {
    _handleError("Failed to connect to server", e);
    showPage.value = (context) {
      RoomDialog.showLeaveRoomDialog(
          context: context, room: roomInfo, onConfirm: leaveRoom);
    };
  }

  void leaveRoom() {
    // 断开服务器之前，发送最后一条消息
    _sendNetworkMessage(MessageType.notify, 'leave room');

    showPage.value = (BuildContext context) {
      Navigator.of(context).pop();
    };

    // 停止监控键盘
    _stopKeyboard();

    //关闭 socket
    _socket.destroy();

    // // 销毁控制器
    // textController.dispose();
    // scrollController.dispose();

    // // 移除所有监听器
    // messageList.dispose();
  }

  void _stopKeyboard() {
    HardwareKeyboard.instance.removeHandler(_handleChatKeyboardEvent);
  }

  void _sendNetworkMessage(MessageType type, String content) {
    if (identify == 0) return;

    final message = NetworkMessage(
      id: identify,
      type: type,
      source: userName,
      content: content,
    );

    try {
      _socket.add(message.toSocketData());
    } catch (e) {
      _handleError("Send network message failed", e);
    }
  }

  void _handleError(String note, Object error) {
    debugPrint("$note: $error");
  }
}

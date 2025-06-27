import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/model.dart';
import '../foundation/network.dart';
import 'front_end.dart';

enum RoomType {
  onlyChat,
  animalChess,
  elementalBattle,
}

enum RoomOperation { start, stop }

class RoomInfo {
  final String name;
  final RoomType type;
  final String address;
  final int port;

  RoomInfo({
    required this.name,
    required this.type,
    required this.address,
    required this.port,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.index,
      'address': address,
      'port': port,
    };
  }

  static String getNameFromJson(Map<String, dynamic> json) {
    return json['name'];
  }

  static RoomType getTypeFromJson(Map<String, dynamic> json) {
    return RoomType.values[json['type']];
  }

  static String getAddressFromJson(Map<String, dynamic> json) {
    return json['address'];
  }

  static int getPortFromJson(Map<String, dynamic> json) {
    return json['port'];
  }

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      name: getNameFromJson(json),
      type: getTypeFromJson(json),
      address: getAddressFromJson(json),
      port: getPortFromJson(json),
    );
  }

  static RoomOperation getOperationFromJson(Map<String, dynamic> json) {
    return RoomOperation.values[json['operation']];
  }

  static Map<String, dynamic> configToJson(
      int port, RoomType type, RoomOperation operation) {
    return {
      'port': port,
      'type': type.index,
      'operation': operation.index,
    };
  }

  static String configToString(
      int port, RoomType type, RoomOperation operation) {
    return jsonEncode(configToJson(port, type, operation));
  }

  static RoomOperation getOperationFromString(String data) {
    return getOperationFromJson(jsonDecode(data));
  }

  static int getPortFromString(String data) {
    return getPortFromJson(jsonDecode(data));
  }

  static RoomType getTypeFromString(String data) {
    return getTypeFromJson(jsonDecode(data));
  }
}

class NetworkEngine {
  final ListNotifier<NetworkMessage> messageList = ListNotifier([]);
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  late Socket _socket;
  int identify = 0;

  final String userName;
  final RoomInfo roomInfo;
  final AlwaysNotifier<void Function(BuildContext)> showPage;
  final void Function(NetworkMessage message) processMessage;

  NetworkEngine({
    required this.userName,
    required this.roomInfo,
    required this.showPage,
    required this.processMessage,
  }) {
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
        onDone: leavePage,
      );
    } catch (e) {
      _handleError("Failed to connect to server", e);
    }
  }

  void _handleSocketData(List<int> data) {
    try {
      final message = NetworkMessage.fromSocket(data);

      debugPrint(
          '${message.source} ${message.id} ${message.type} ${message.content}');

      if ((message.type == MessageType.accept) && (identify == 0)) {
        identify = message.id;
        sendNetworkMessage(MessageType.notify, "join room success");
      } else if (message.type.index >= MessageType.notify.index) {
        messageList.add(message);
      }
      processMessage(message);
    } catch (e) {
      _handleError("Failed to parse network message", e);
    }
  }

  void _handleDisconnect(Object e) {
    _handleError("Failed to connect to server", e);
    showPage.value = (context) {
      TemplateDialog.confirmDialog(
        context: context,
        title: "The connection has been disconnected",
        content: 'Coming out of the room soon',
        before: () {
          return true;
        },
        onTap: () {},
        after: () {
          leavePage();
        },
      );
    };
  }

  void _startKeyboard() {
    HardwareKeyboard.instance.addHandler(_handleChatKeyboardEvent);
  }

  void _stopKeyboard() {
    HardwareKeyboard.instance.removeHandler(_handleChatKeyboardEvent);
  }

  bool _handleChatKeyboardEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      sendInputText();
      return true;
    }
    return false;
  }

  void sendInputText() {
    final text = textController.text;
    if (text.isEmpty) return;

    sendNetworkMessage(MessageType.text, text);
    textController.clear();
  }

  void sendNetworkMessage(MessageType type, String content) {
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

  void leavePage() {
    // 断开服务器之前，发送最后一条消息
    sendNetworkMessage(MessageType.notify, 'leave room');

    showPage.value = (BuildContext context) {
      Navigator.of(context).pop();
    };

    // 停止监控键盘
    _stopKeyboard();

    //关闭 socket
    _socket.destroy();

    // // 移除所有监听器
    // gameStep.leavePage();
    // infoList.leavePage();
    // messageList.leavePage();

    // // 销毁控制器
    // textController.leavePage();
    // scrollController.leavePage();
  }
}

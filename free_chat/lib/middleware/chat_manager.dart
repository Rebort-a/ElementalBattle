import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/models.dart';

class ChatManager {
  late final Socket _socket;

  final AlwaysNotifier<void Function(BuildContext)> showPage =
      AlwaysNotifier<void Function(BuildContext)>((BuildContext context) {});

  final ListNotifier<ChatMessage> messageList = ListNotifier([]);

  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  late final String uuid;

  final RoomInfo roomInfo;
  final String userName;

  ChatManager(this.roomInfo, this.userName) {
    uuid = generateUuid();
    messageList.addCallBack(_scrollToBottom);
    _connectToServer();
    _startKeyboard();
  }

  void _connectToServer() async {
    try {
      // 连接到服务器
      _socket = await Socket.connect(roomInfo.address, roomInfo.port);
      // 监听服务器发来的消息
      _socket.listen(
        (data) {
          // 收到消息
          messageList.add(ChatMessage.fromSocket(data));
        },
        onDone: () {
          // 连接关闭
          _stopConnection();
        },
        onError: (error) {
          // 处理错误
          addMessage('Socket connect error: $error');
        },
      );

      // 连接服务器后，发送第一条消息
      sendMessage(MessageType.notify, 'join in room');
    } catch (e) {
      // 处理错误
      addMessage('Failed to connect: $e');
    }
  }

  String generateUuid() {
    var random = Random.secure();
    var values = List<int>.generate(16, (i) => random.nextInt(256));
    var bytes = Uint8List.fromList(values);

    // Set the version to 4 (random)
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set the variant to 10
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    var uuid =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
    return '${uuid.substring(0, 8)}-${uuid.substring(8, 12)}-${uuid.substring(12, 16)}-${uuid.substring(16, 20)}-${uuid.substring(20, 32)}';
  }

  void addMessage(String content) {
    messageList.add(ChatMessage(
        uuid: '',
        timestamp: '',
        source: 'system',
        type: MessageType.notify,
        content: content));
  }

  void sendMessage(MessageType type, String text) {
    ChatMessage message = ChatMessage(
      uuid: uuid,
      timestamp: DateTime.now().toIso8601String(),
      source: userName,
      type: type,
      content: text,
    );

    _socket.add(message.toSocketData());
  }

  void sendEnter() {
    final text = textController.text;
    if (text.isEmpty) {
      return;
    }

    sendMessage(MessageType.text, text);

    textController.clear();
  }

  void leaveRoom() {
    // 断开服务器之前，发送最后一条消息
    sendMessage(MessageType.notify, 'leave room');

    _stopConnection();
  }

  void _stopConnection() {
    _stopKeyboard();
    _socket.destroy();
    showPage.value = (BuildContext context) {
      Navigator.of(context).pop();
    };
  }

  void _startKeyboard() {
    // 添加键盘事件处理器
    HardwareKeyboard.instance.addHandler(_handleHardwareKeyboardEvent);
  }

  void _stopKeyboard() {
    // 移除键盘事件处理器
    HardwareKeyboard.instance.removeHandler(_handleHardwareKeyboardEvent);
  }

  bool _handleHardwareKeyboardEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        sendEnter();
        return true;
      }
    }
    return false;
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
}

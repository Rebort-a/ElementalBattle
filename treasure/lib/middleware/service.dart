import 'dart:io';

import 'package:treasure/middleware/back_end.dart';

import '../foundation/discovery.dart';
import '../foundation/network.dart';

class SocketService {
  final _discovery = Discovery();
  late final ServerSocket _server;

  final Set<Socket> _clients = <Socket>{};

  final String roomName;
  final RoomType roomType;

  SocketService({required this.roomName, required this.roomType});

  int get port => _server.port;

  Future<void> start() async {
    // 使用随机端口创建服务器
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);

    // 监听客户端连接
    _server.listen((Socket clientSocket) {
      int clientId = _clients.length + 1;

      // 客户端发起连接请求时，将其添加到列表
      _clients.add(clientSocket);

      // 发送接受消息
      _sendAcceptMessage(clientSocket, clientId);

      // 监听每个客户端
      clientSocket.listen(
        (data) {
          // 如果有消息，转发消息给所有已连接的客户端
          _broadcastMessage(data);
        },
        onDone: () {
          // 当客户端断开时，从列表中移除
          _clients.remove(clientSocket);
          clientSocket.destroy();
        },
        cancelOnError: true,
      );
    });

    // 开始定时广播房间信息
    _discovery.startSending(
      NetworkMessage(
              id: 0,
              type: MessageType.service,
              source: roomName,
              content:
                  RoomInfo.configToString(port, roomType, RoomOperation.start))
          .toSocketData(),
      const Duration(seconds: 1), // 1秒发送一次
    );
  }

  void _sendAcceptMessage(Socket client, int clientId) {
    client.add(NetworkMessage(
      id: clientId,
      type: MessageType.accept,
      source: roomName,
      content: 'service',
    ).toSocketData());
  }

  void _broadcastMessage(List<int> data) {
    // 遍历所有已连接的客户端
    for (var client in _clients) {
      // 发送消息给客户端
      client.add(data);
    }
  }

  void _closeAllClients() {
    for (var client in _clients) {
      client.close();
    }
    _clients.clear();
  }

  void stop() {
    // 停止定时发送
    _discovery.stopSending();

    // 发送停止信息
    _discovery.sendMessage(NetworkMessage(
            id: 0,
            type: MessageType.service,
            source: roomName,
            content:
                RoomInfo.configToString(port, roomType, RoomOperation.stop))
        .toSocketData());

    // 关闭所有客户端连接
    _closeAllClients();

    // 关闭服务器
    _server.close();
  }
}

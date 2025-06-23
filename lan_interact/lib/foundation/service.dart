import 'dart:io';

import 'discovery.dart';
import 'network.dart';

class SocketService {
  final _discovery = Discovery();
  late final ServerSocket _server;

  final Map<int, Socket> _clients = <int, Socket>{};
  int record = 0;

  late final String roomName;

  SocketService(this.roomName);

  int get port => _server.port;

  Future<void> start() async {
    // 使用随机端口创建服务器
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);

    // 监听客户端连接
    _server.listen((Socket clientSocket) {
      int clientId = record++;

      // 客户端发起连接请求时，将其添加到列表
      _clients[clientId] = clientSocket;

      // 发送接受消息
      _sendAcceptMessage(clientSocket, clientId);

      // 监听每个客户端
      clientSocket.listen(
        (data) {
          // 如果有消息，转发消息给所有已连接的客户端
          _broadcastMessage(data);
        },
        onDone: () {
          _removeClient(clientId);
        },
        cancelOnError: true,
      );
    });

    // 开始定时广播房间信息
    _discovery.startSending(
      NetworkMessage(
              clientIdentify: record,
              type: MessageType.service,
              source: roomName,
              content: '${_server.port}')
          .toSocketData(),
      const Duration(seconds: 1), // 1秒发送一次
    );
  }

  void _sendAcceptMessage(Socket client, int clientId) {
    client.add(NetworkMessage(
      clientIdentify: clientId,
      type: MessageType.accept,
      source: roomName,
      content: 'none',
    ).toSocketData());
  }

  void _broadcastMessage(List<int> data) {
    // 遍历所有已连接的客户端，发送消息
    _clients.forEach((clientId, client) {
      client.add(data);
    });
  }

  void _removeClient(int clientId) {
    _clients.remove(clientId)?.destroy();
  }

  void _closeAllClients() {
    _clients.forEach((_, client) => client.close());
    _clients.clear();
  }

  void stop() {
    // 停止定时发送
    _discovery.stopSending();

    // 发送停止信息
    _discovery.sendMessage(NetworkMessage(
            clientIdentify: record,
            type: MessageType.service,
            source: roomName,
            content: 'stop')
        .toSocketData());

    // 关闭所有客户端连接
    _closeAllClients();

    // 关闭服务器
    _server.close();
  }
}

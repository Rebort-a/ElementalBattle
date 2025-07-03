import 'dart:io';
import 'package:treasure/middleware/back_end.dart';
import '../foundation/discovery.dart';
import '../foundation/network.dart';

class SocketService {
  static const _discoveryInterval = Duration(seconds: 1);

  final Discovery _discovery = Discovery();
  late final ServerSocket _server;
  final Set<Socket> _clients = {};
  int record = 0;

  final String roomName;
  final RoomType roomType;

  SocketService({required this.roomName, required this.roomType});

  int get port => _server.port;

  Future<void> start() async {
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
      _server.listen(_handleClientConnect);

      _startDiscoveryBroadcast();
    } on SocketException catch (e) {
      throw Exception("Failed to start server: ${e.message}");
    }
  }

  void stop() {
    _discovery.stopSending();
    _broadcastRoomOperation(RoomOperation.stop);
    _closeResources();
  }

  void _handleClientConnect(Socket client) {
    record = record + 1;
    _clients.add(client);
    _sendAcceptMessage(client, record);

    client.listen(
      _broadcastMessage,
      onDone: () => _removeClient(client),
      onError: (_) => _removeClient(client),
      cancelOnError: true,
    );
  }

  void _startDiscoveryBroadcast() {
    _discovery.startSending(
      _createRoomInfoMessage(RoomOperation.start).toSocketData(),
      _discoveryInterval,
    );
  }

  void _sendAcceptMessage(Socket client, int id) {
    client.add(NetworkMessage(
      id: id,
      type: MessageType.accept,
      source: roomName,
      content: 'service',
    ).toSocketData());
  }

  void _broadcastMessage(List<int> data) {
    for (final client in _clients.toList()) {
      // 避免并发修改
      try {
        client.add(data);
      } catch (e) {
        _removeClient(client);
      }
    }
  }

  void _removeClient(Socket client) {
    _clients.remove(client);
    client.destroy();
  }

  void _broadcastRoomOperation(RoomOperation operation) {
    _discovery.sendMessage(_createRoomInfoMessage(operation).toSocketData());
  }

  NetworkMessage _createRoomInfoMessage(RoomOperation operation) {
    return NetworkMessage(
      id: _clients.hashCode,
      type: MessageType.service,
      source: roomName,
      content: RoomInfo.configToString(port, roomType, operation),
    );
  }

  void _closeResources() {
    for (final client in _clients) {
      client.destroy();
    }
    _clients.clear();
    _server.close();
  }
}

import 'package:flutter/material.dart';
import 'package:treasure/upper/elemental_battle/upper/combat_page.dart';

import '../foundation/discovery.dart';
import '../foundation/model.dart';
import '../foundation/network.dart';

import '../middleware/back_end.dart';
import '../middleware/service.dart';
import '../middleware/front_end.dart';
import 'elemental_battle_local/upper/map_page.dart';

class CreatedRoomInfo extends RoomInfo {
  final SocketService server;

  CreatedRoomInfo({
    required super.name,
    required super.type,
    required super.address,
    required super.port,
    required this.server,
  });
}

class HomeManager {
  final _discovery = Discovery();

  final AlwaysNotifier<void Function(BuildContext)> showPage =
      AlwaysNotifier((BuildContext context) {});

  final ListNotifier<CreatedRoomInfo> createdRooms = ListNotifier([]);
  final ListNotifier<RoomInfo> othersRooms = ListNotifier([]);

  HomeManager() {
    _discovery.startReceive(_handleReceivedMessage);
  }

  void stop() {
    _discovery.stopReceive();
    stopAllCreatedRooms();
    _clearOtherRooms();
  }

  void _clearOtherRooms() {
    othersRooms.clear();
  }

  void _handleReceivedMessage(String address, List<int> data) {
    NetworkMessage message = NetworkMessage.fromSocket(data);
    if (message.type == MessageType.service) {
      RoomOperation operation =
          RoomInfo.getOperationFromString(message.content);
      int port = RoomInfo.getPortFromString(message.content);

      if (operation == RoomOperation.stop) {
        othersRooms.removeWhere((room) =>
            room.name == message.source &&
            room.address == address &&
            room.port == port);
      } else if (operation == RoomOperation.start) {
        RoomType type = RoomInfo.getTypeFromString(message.content);
        RoomInfo newRoom = RoomInfo(
            name: message.source, type: type, address: address, port: port);
        bool isMyRoom = createdRooms.value.any(
            (room) => room.name == newRoom.name && room.port == newRoom.port);
        bool isOtherRoom = othersRooms.value.any((room) =>
            room.name == newRoom.name &&
            room.address == newRoom.address &&
            room.port == newRoom.port);

        if ((!isMyRoom) && (!isOtherRoom)) {
          othersRooms.add(newRoom);
        }
      }
    }
  }

  void stopAllCreatedRooms() {
    for (var room in createdRooms.value) {
      room.server.stop();
    }
    createdRooms.clear();
  }

  void stopCreatedRoom(int index) {
    var room = createdRooms.value[index];
    room.server.stop();
    createdRooms.removeAt(index);
  }

  Future<void> _createRoom(String roomName, RoomType roomType) async {
    SocketService server =
        SocketService(roomName: roomName, roomType: roomType);

    await server.start();

    createdRooms.add(CreatedRoomInfo(
        name: roomName,
        type: roomType,
        address: 'localhost',
        port: server.port,
        server: server));
  }

  void showCreateRoomDialog() {
    showPage.value = (BuildContext context) {
      RoomDialog.showCreateRoomDialog(context: context, onConfirm: _createRoom);
    };
  }

  void showJoinRoomDialog(RoomInfo room) {
    showPage.value = (BuildContext context) {
      RoomDialog.showJoinRoomDialog(
          context: context, room: room, onConfirm: _joinRoom);
    };
  }

  void _joinRoom(RoomInfo room, String userName, BuildContext context) {
    switch (room.type) {
      case RoomType.onlyChat:
        Navigator.of(context).pushNamed(
          '/chat_room',
          arguments: {
            'userName': userName,
            'roomInfo': room,
          },
        );
        break;
      case RoomType.animalChess:
        break;
      case RoomType.elementalBattle:
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CombatPage(
                  userName: userName,
                  roomInfo: room,
                )));

        // Navigator.of(context).pushNamed(
        //   '/elemental_battle',
        //   arguments: {
        //     'roomInfo': room,
        //     'userName': userName,
        //   },
        // );
        break;
    }
  }

  void navigateToChessPage() {
    showPage.value = (BuildContext context) {
      Navigator.of(context).pushNamed('/animal_chess');
    };
  }

  void navigateToMapPage() {
    showPage.value = (BuildContext context) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => MapPage()));
    };
  }
}

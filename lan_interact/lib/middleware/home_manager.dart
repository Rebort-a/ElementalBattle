import 'package:flutter/material.dart';

import '../foundation/network.dart';
import '../foundation/discovery.dart';
import '../foundation/models.dart';
import '../foundation/service.dart';

import 'common.dart';
import 'elemental.dart';

import '../upper/prepare_page.dart';

class CreatedRoomInfo extends RoomInfo {
  final SocketService server;

  CreatedRoomInfo(
      {required super.name,
      required super.address,
      required super.port,
      required this.server});
}

class HomeManager {
  final _discovery = Discovery();

  final AlwaysNotifier<void Function(BuildContext)> showPage =
      AlwaysNotifier((BuildContext context) {});

  final ListNotifier<CreatedRoomInfo> createdRooms = ListNotifier([]);
  final ListNotifier<RoomInfo> othersRooms = ListNotifier([]);

  final Map<RoomInfo, Elemental> roomMembers = {};

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
      if (message.content == 'stop') {
        othersRooms.removeWhere(
            (room) => room.name == message.source && room.address == address);
      } else {
        int port = int.parse(message.content);
        RoomInfo newRoom =
            RoomInfo(name: message.source, address: address, port: port);
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

  Future<void> _createRoom(String roomName) async {
    SocketService server = SocketService(roomName);

    await server.start();

    createdRooms.add(CreatedRoomInfo(
        name: roomName,
        address: 'localhost',
        port: server.port,
        server: server));
  }

  void showCreateRoomDialog() {
    showPage.value = (BuildContext context) {
      DialogCollection.showCreateRoomDialog(
          context: context, onConfirm: _createRoom);
    };
  }

  void _joinRoom(RoomInfo room, String userName, BuildContext context) {
    if (userName.isNotEmpty) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PreparePage(roomInfo: room, userName: userName),
      ));
    }
  }

  void showJoinRoomDialog(RoomInfo room) {
    showPage.value = (BuildContext context) {
      DialogCollection.showJoinRoomDialog(
          context: context, room: room, onConfirm: _joinRoom);
    };
  }
}

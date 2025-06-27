import 'dart:convert';

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

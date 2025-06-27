import 'dart:convert';

enum MessageType {
  service,
  accept,
  searching,
  roleConfig,
  gameAction,
  notify,
  text,
  image,
  file,
}

class NetworkMessage {
  int id;
  MessageType type;
  String source;
  String content;

  NetworkMessage({
    required this.id,
    required this.type,
    required this.source,
    required this.content,
  });

  factory NetworkMessage.fromJson(Map<String, dynamic> json) {
    return NetworkMessage(
      id: json['id'],
      type: MessageType.values[json['type']],
      source: json['source'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'source': source,
      'content': content,
    };
  }

  factory NetworkMessage.fromSocket(List<int> data) {
    return NetworkMessage.fromJson(jsonDecode(utf8.decode(data)));
  }

  List<int> toSocketData() {
    return utf8.encode(jsonEncode(toJson()));
  }
}

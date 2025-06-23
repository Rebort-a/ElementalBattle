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
  int clientIdentify;
  MessageType type;
  String source;
  String content;

  NetworkMessage({
    required this.clientIdentify,
    required this.type,
    required this.source,
    required this.content,
  });

  factory NetworkMessage.fromJson(Map<String, dynamic> json) {
    return NetworkMessage(
      clientIdentify: json['clientIdentify'],
      type: MessageType.values[json['type']],
      source: json['source'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientIdentify': clientIdentify,
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

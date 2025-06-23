import 'dart:convert';

enum MessageType {
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
  String timestamp;
  MessageType type;
  String source;
  String content;

  NetworkMessage({
    required this.clientIdentify,
    required this.timestamp,
    required this.type,
    required this.source,
    required this.content,
  });

  static NetworkMessage fromJson(Map<String, dynamic> json) {
    return NetworkMessage(
      clientIdentify: json['clientIdentify'],
      timestamp: json['timestamp'],
      type: MessageType.values[json['type']],
      source: json['source'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientIdentify': clientIdentify,
      'timestamp': timestamp,
      'type': type.index,
      'source': source,
      'content': content,
    };
  }

  static NetworkMessage fromSocket(List<int> data) {
    return fromJson(jsonDecode(utf8.decode(data)));
  }

  List<int> toSocketData() {
    return utf8.encode(jsonEncode(toJson()));
  }
}

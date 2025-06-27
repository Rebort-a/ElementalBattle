import 'package:flutter/material.dart';

import '../../foundation/model.dart';
import '../../middleware/back_end.dart';

class ChatManager {
  final AlwaysNotifier<void Function(BuildContext)> showPage =
      AlwaysNotifier((_) {});
  late final NetworkEngine networkEngine;
  ChatManager({required String userName, required RoomInfo roomInfo}) {
    networkEngine = NetworkEngine(
      userName: userName,
      roomInfo: roomInfo,
      showPage: showPage,
      processMessage: (message) {},
    );
  }
}

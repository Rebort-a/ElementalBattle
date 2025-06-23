import 'package:flutter/material.dart';

import '../foundation/models.dart';

class DialogCollection {
  static void showDialogTemplate({
    required BuildContext context,
    required String title,
    required String hintText,
    required String confirmButtonText,
    required Function(String input) onConfirm,
  }) {
    String input = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text(title)),
          content: TextField(
            onChanged: (value) {
              input = value;
            },
            decoration: InputDecoration(hintText: hintText),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(confirmButtonText),
              onPressed: () {
                if (input.isNotEmpty) {
                  Navigator.of(context).pop();
                  onConfirm(input);
                }
              },
            ),
          ],
        );
      },
    );
  }

  static void showCreateRoomDialog({
    required BuildContext context,
    required Function(String roomName) onConfirm,
  }) {
    showDialogTemplate(
      context: context,
      title: 'Create',
      hintText: 'Enter room name',
      confirmButtonText: 'Create',
      onConfirm: onConfirm,
    );
  }

  static void showJoinRoomDialog({
    required BuildContext context,
    required RoomInfo room,
    required Function(RoomInfo room, String userName, BuildContext context)
        onConfirm,
  }) {
    showDialogTemplate(
      context: context,
      title: 'Join',
      hintText: 'Enter user name',
      confirmButtonText: 'Join',
      onConfirm: (userName) => onConfirm(room, userName, context),
    );
  }
}

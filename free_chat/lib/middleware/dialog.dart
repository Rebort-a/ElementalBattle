import 'package:flutter/material.dart';

import 'common.dart';

class TemplateDialog {
  static void confirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    required bool Function() before,
    required VoidCallback onTap,
    required VoidCallback after,
  }) {
    if (before()) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              TextButton(
                child: const Text('关闭'),
                onPressed: () {
                  Navigator.of(context).pop();
                  onTap();
                },
              ),
            ],
          );
        },
      ).then((value) {
        after();
      });
    }
  }

  static void inputDialog({
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
              child: Text(confirmButtonText),
              onPressed: () {
                if (input.isNotEmpty) {
                  Navigator.of(context).pop();
                  onConfirm(input);
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static void snackBarDialog(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

class RoomDialog {
  static void showCreateRoomDialog({
    required BuildContext context,
    required Function(String roomName) onConfirm,
  }) {
    TemplateDialog.inputDialog(
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
    TemplateDialog.inputDialog(
      context: context,
      title: 'Join',
      hintText: 'Enter user name',
      confirmButtonText: 'Join',
      onConfirm: (userName) => onConfirm(room, userName, context),
    );
  }

  static void showLeaveRoomDialog({
    required BuildContext context,
    required RoomInfo room,
    required Function() onConfirm,
  }) {
    TemplateDialog.confirmDialog(
      context: context,
      title: '离开',
      content: '即将退出房间',
      before: () => true,
      onTap: () {
        onConfirm();
      },
      after: () {},
    );
  }
}

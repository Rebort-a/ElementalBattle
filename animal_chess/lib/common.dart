import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RoomInfo {
  final String name;
  final String address;
  final int port;
  RoomInfo({required this.name, required this.address, required this.port});
}

class DialogCollection {
  static void confirmDialogTemplate({
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

  static void inputDialogTemplate({
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

  static void snackBarDialogTemplate(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void showCreateRoomDialog({
    required BuildContext context,
    required Function(String roomName) onConfirm,
  }) {
    inputDialogTemplate(
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
    inputDialogTemplate(
      context: context,
      title: 'Join',
      hintText: 'Enter user name',
      confirmButtonText: 'Join',
      onConfirm: (userName) => onConfirm(room, userName, context),
    );
  }
}

class ScaleButton extends StatefulWidget {
  final Size size;
  final VoidCallback onTap;
  final Widget? icon;
  final Color color;
  final bool press;

  const ScaleButton({
    super.key,
    required this.size,
    required this.onTap,
    this.icon,
    this.color = Colors.blue,
    this.press = true,
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(() {
        setState(() {});
      });

    _animation = Tween<double>(begin: 1.0, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _cancelTimer();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      widget.onTap();
      HapticFeedback.mediumImpact();
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    widget.onTap();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    // HapticFeedback.lightImpact();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _onLongPress() {
    if (widget.press) {
      _controller.forward();
      _startTimer();
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (widget.press) {
      _controller.reverse();
      _cancelTimer();
    }
  }

  void _onLongPressUp() {
    if (widget.press) {
      _controller.reverse();
      _cancelTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: _onLongPress,
      onLongPressUp: _onLongPressUp,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: _onLongPressUp,
      child: Transform.scale(
        scale: _animation.value,
        child: Container(
          width: widget.size.width,
          height: widget.size.height,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5), // 阴影颜色
                spreadRadius: 0, // 阴影扩散半径
                blurRadius: 4, // 阴影模糊半径
                offset: const Offset(0, 4), // 阴影偏移量
              ),
            ],
          ),
          child: Center(child: widget.icon),
        ),
      ),
    );
  }
}

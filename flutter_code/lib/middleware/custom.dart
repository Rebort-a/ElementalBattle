import 'package:flutter/material.dart';

class CustomDirectionButton extends StatefulWidget {
  final Size size;
  final VoidCallback onTap;
  final Widget? icon;
  final Color color;
  final bool enableLongPress;

  const CustomDirectionButton({
    super.key,
    required this.size,
    required this.onTap,
    this.icon,
    this.color = Colors.blue,
    this.enableLongPress = true,
  });

  @override
  State<CustomDirectionButton> createState() => _CustomerDirectionButtonState();
}

class _CustomerDirectionButtonState extends State<CustomDirectionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        setState(() {});
      });
    _animation =
        Tween<double>(begin: 1.0, end: 0.95).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.color,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          _animationController.forward();
          widget.onTap();
        },
        onTapUp: (_) {
          _animationController.reverse();
        },
        onTapCancel: () {
          _animationController.reverse();
        },
        child: Transform.scale(
          scale: _animation.value,
          child: SizedBox.fromSize(size: widget.size),
        ),
      ),
    );
  }
}

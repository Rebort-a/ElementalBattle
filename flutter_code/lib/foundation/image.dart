import 'package:flutter/material.dart';
import 'dart:async';

import 'entity.dart';

class ImageSplitter {
  final String imagePath;
  final int rows;
  final int columns;
  late final Future<ImageInfo> _imageInfoFuture;

  ImageSplitter({
    required this.imagePath,
    required this.rows,
    required this.columns,
  }) {
    _imageInfoFuture = loadImageInfo();
  }

  Future<ImageInfo> loadImageInfo() async {
    final ImageStream stream =
        AssetImage(imagePath).resolve(ImageConfiguration.empty);
    final Completer<ImageInfo> completer = Completer<ImageInfo>();
    ImageStreamListener? listener;

    listener = ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info);
      stream.removeListener(listener!);
    });

    stream.addListener(listener);
    return completer.future;
  }

  Widget getImagePiece(int index) {
    final int totalImages = rows * columns;

    if (index < 0 || index >= totalImages) {
      return const Center(child: Icon(Icons.error, color: Colors.red));
    }

    final int rowIndex = index ~/ columns;
    final int columnIndex = index % columns;

    return FutureBuilder<ImageInfo>(
      future: _imageInfoFuture,
      builder: (BuildContext context, AsyncSnapshot<ImageInfo> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const Center(child: Icon(Icons.error, color: Colors.red));
          }
          final imageInfo = snapshot.data!;
          final pieceWidth = imageInfo.image.width / columns;
          final pieceHeight = imageInfo.image.height / rows;
          return CustomPaint(
            painter: ImageSplitPainter(
              imageInfo: imageInfo,
              rowIndex: rowIndex,
              columnIndex: columnIndex,
              pieceWidth: pieceWidth,
              pieceHeight: pieceHeight,
            ),
            size: Size(pieceWidth, pieceHeight),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class ImageSplitPainter extends CustomPainter {
  final ImageInfo imageInfo;
  final int rowIndex;
  final int columnIndex;
  final double pieceWidth;
  final double pieceHeight;
  final Paint _paint = Paint();

  ImageSplitPainter({
    required this.imageInfo,
    required this.rowIndex,
    required this.columnIndex,
    required this.pieceWidth,
    required this.pieceHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect srcRect = Rect.fromLTWH(
      columnIndex * pieceWidth,
      rowIndex * pieceHeight,
      pieceWidth,
      pieceHeight,
    );

    canvas.drawImageRect(
      imageInfo.image,
      srcRect,
      Rect.fromLTRB(0, 0, size.width, size.height),
      _paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is ImageSplitPainter) {
      return imageInfo != oldDelegate.imageInfo ||
          rowIndex != oldDelegate.rowIndex ||
          columnIndex != oldDelegate.columnIndex ||
          pieceWidth != oldDelegate.pieceWidth ||
          pieceHeight != oldDelegate.pieceHeight;
    }
    return false;
  }
}

class ImageManager {
  static final _instance = ImageManager._internal();

  factory ImageManager() {
    return _instance;
  }

  ImageManager._internal();

  final Map<EntityID, ImageSplitter> _imageSplitters = {};

  Widget _getAssetsImage(
      EntityID id, int iconIndex, int colorIndex, bool fogFlag) {
    _imageSplitters.putIfAbsent(id, () {
      switch (id) {
        case EntityID.player:
          return ImageSplitter(
              imagePath: 'assets/images/player.png', rows: 4, columns: 4);
        default:
          return ImageSplitter(
              imagePath: 'assets/images/road.png', rows: 1, columns: 1);
      }
    });

    return Container(
      color: getColor(id, colorIndex),
      child: Center(
        child: _imageSplitters[id]!.getImagePiece(iconIndex),
      ),
    );
  }

  Widget getWidgetImage(
      EntityID id, int iconIndex, int colorIndex, bool fogFlag) {
    if (fogFlag) {
      return Container(color: Colors.black);
    } else {
      if (id == EntityID.player) {
        return _getAssetsImage(id, iconIndex, colorIndex, fogFlag);
      } else {
        return _getPresetsImage(id, iconIndex, colorIndex, fogFlag);
      }
    }
  }

  static Widget _getPresetsImage(
      EntityID id, int iconIndex, int colorIndex, bool fogFlag) {
    return Container(
      color: getColor(id, colorIndex),
      child: Center(
        child: getIcon(id, iconIndex),
      ),
    );
  }

  static Color getColor(EntityID id, int index) {
    switch (id) {
      case EntityID.road:
        return Colors.blueGrey; // 道路
      case EntityID.wall:
        return Colors.brown; // 墙壁
      case EntityID.exit:
      case EntityID.enter:
        switch (index) {
          case 1:
            return const Color(0xFFC0C0C0);
          case 2:
            return Colors.blue;
          case 3:
            return Colors.lightGreen;
          case 4:
            return Colors.deepOrange;
          case 5:
            return Colors.brown;
          default:
            return Colors.blueGrey;
        }
      case EntityID.train:
      case EntityID.store:
      case EntityID.home:
        return Colors.teal;
      case EntityID.weak:
        return const Color.fromARGB(255, 255, 128, 128);
      case EntityID.opponent:
        return const Color.fromARGB(255, 255, 64, 64);
      case EntityID.strong:
        return const Color.fromARGB(255, 255, 32, 32);
      case EntityID.boss:
        return const Color.fromARGB(255, 255, 0, 0);
      default:
        return Colors.blueGrey; // 道路的背景
    }
  }

  static Widget getIcon(EntityID id, int colorIndex) {
    switch (id) {
      case EntityID.road:
        return Container(); // 道路
      case EntityID.wall:
        return const Text('🧱'); // 墙壁
      case EntityID.player: // 玩家
        switch (colorIndex) {
          case 0:
            return const Text('😢');
          case 1:
            return const Text('😞');
          case 2:
            return const Text('😮');
          case 3:
            return const Text('😐');
          case 4:
            return const Text('😊');
          case 5:
            return const Text('😎');
          default:
            return const Text('😎');
        }
      case EntityID.enter:
        return const Icon(Icons.exit_to_app); // 入口
      case EntityID.exit:
        return const Icon(Icons.door_sliding); // 出口
      case EntityID.train:
        return const Text('🏟️'); // 训练场
      case EntityID.store:
        return const Text('🏦'); // 商店
      case EntityID.home:
        return const Text('🏠'); // 家
      case EntityID.hospital:
        return const Text('💊'); // 药
      case EntityID.sword:
        return const Text('🗡️'); // 剑
      case EntityID.shield:
        return const Text('🛡️'); // 盾
      case EntityID.purse:
        return const Text('💰'); // 钱袋
      case EntityID.weak:
        return const Text('👻'); // 弱鸡
      case EntityID.opponent:
        return const Text('🤡'); // 对手
      case EntityID.strong:
        return const Text('👿'); // 强敌
      case EntityID.boss:
        return const Text('💀'); // 魔王
      default:
        return const Text('❓'); // 未知
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:async';

import '../foundation/entity.dart';

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

  Widget getImage(EntityID id, int iconIndex, int colorIndex, bool fogFlag) {
    if (fogFlag) {
      return Container(color: Colors.black);
    } else {
      return Container(
        color: _getBack(id, colorIndex),
        child: Center(
          child: _getFront(id, iconIndex),
        ),
      );
    }
  }

  Widget _getFront(EntityID id, int iconIndex) {
    switch (id) {
      case EntityID.player:
        return _getAssetsImage(id, iconIndex);
      default:
        return _getPresetsEmoji(id);
    }
  }

  Widget _getAssetsImage(EntityID id, int iconIndex) {
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

    return _imageSplitters[id]!.getImagePiece(iconIndex);
  }

  static Color _getBack(EntityID id, int index) {
    switch (id) {
      case EntityID.wall:
        return Colors.brown; // 墙壁
      case EntityID.exit:
      case EntityID.enter:
        switch (index) {
          case 1:
            return const Color(0xFFC0C0C0);
          default:
            return Colors.blueGrey;
        }
      case EntityID.train:
      case EntityID.gym:
      case EntityID.store:
      case EntityID.home:
        return Colors.teal;
      default:
        return Colors.blueGrey; // 道路的背景
    }
  }

  static Widget _getPresetsEmoji(EntityID id) {
    switch (id) {
      case EntityID.road:
        return const SizedBox.shrink(); // 道路
      case EntityID.wall:
        return const Text('🧱'); // 墙壁
      case EntityID.player: // 玩家
        return const Text('😎');
      case EntityID.enter:
        return const Icon(Icons.exit_to_app); // 入口
      case EntityID.exit:
        return const Icon(Icons.door_sliding); // 出口
      case EntityID.train:
        return const Text('🏟️'); // 训练场
      case EntityID.gym:
        return const Text('💪'); // 健身房
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

  static Widget getCombatEmoji(double emoji) {
    if (emoji < 0.125) {
      return const Text('😢');
    } else if (emoji < 0.25) {
      return const Text('😞');
    } else if (emoji < 0.5) {
      return const Text('😮');
    } else if (emoji < 0.75) {
      return const Text('😐');
    } else if (emoji < 0.875) {
      return const Text('😊');
    } else {
      return const Text('😎');
    }
  }
}

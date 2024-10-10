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
      throw IndexError.withLength(index, totalImages, indexable: 'index');
    }

    final int rowIndex = index ~/ columns;
    final int columnIndex = index % columns;

    return FutureBuilder<ImageInfo>(
      future: _imageInfoFuture,
      builder: (BuildContext context, AsyncSnapshot<ImageInfo> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const Center(
                child: Icon(Icons.error, color: Colors.red, size: 32));
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
      Paint(),
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

  Widget getResource(EntityID entityID, int imageIndex) {
    if (!_imageSplitters.containsKey(entityID)) {
      switch (entityID) {
        case EntityID.player:
          _imageSplitters[entityID] = ImageSplitter(
            imagePath: 'assets/images/player.png',
            rows: 4,
            columns: 4,
          );
          break;

        default:
          _imageSplitters[entityID] = ImageSplitter(
            imagePath: 'assets/images/road.png',
            rows: 1,
            columns: 1,
          );
          break;
      }
    }
    return _imageSplitters[entityID]!.getImagePiece(imageIndex);
  }
}

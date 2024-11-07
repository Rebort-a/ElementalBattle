import 'entity.dart';

const int mapLevel = 6; // 地图级数

enum Direction {
  down,
  left,
  up,
  right,
}

// 地图单元信息
class CellData {
  final EntityID id;
  final int iconIndex;
  final int colorIndex;
  final bool fogFlag;

  CellData({
    required this.id,
    this.iconIndex = 0,
    this.colorIndex = 0,
    this.fogFlag = true,
  });

  CellData copyWith({
    EntityID? id,
    int? iconIndex,
    int? colorIndex,
    bool? fogFlag,
  }) {
    return CellData(
      id: id ?? this.id,
      iconIndex: iconIndex ?? this.iconIndex,
      colorIndex: colorIndex ?? this.colorIndex,
      fogFlag: fogFlag ?? this.fogFlag,
    );
  }
}

// 可移动的实体
class MovableEntity {
  final EntityID id;
  int y, x;
  MovableEntity({required this.id, required this.y, required this.x});

  void updatePosition(int newY, int newX) {
    y = newY;
    x = newX;
  }
}

// 地图栈
class MapDataStack {
  final int y, x; // 地图在父地图的位置
  final MapDataStack? parent; // 父节点
  final List<MapDataStack> children = []; // 子节点列表
  List<List<CellData>> leaveMap = []; // 玩家离开时的地图数据
  List<MovableEntity> entities = []; // 地图上的实体数据

  MapDataStack({required this.y, required this.x, required this.parent});
}

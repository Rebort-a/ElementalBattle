import '../foundation/entity.dart';

const int mapLevel = 6; // 地图级数

// 地图单元信息
class CellData {
  final EntityID id;
  final int index;
  final double proportion;
  final bool fog;

  CellData({
    required this.id,
    this.index = 0,
    this.proportion = 1.0,
    this.fog = true,
  });

  CellData copyWith({
    EntityID? id,
    int? index,
    double? proportion,
    bool? fog,
  }) {
    return CellData(
      id: id ?? this.id,
      index: index ?? this.index,
      proportion: proportion ?? this.proportion,
      fog: fog ?? this.fog,
    );
  }
}

// 可移动的实体
class MovableEntity {
  final EntityID id;
  late int y, x;
  MovableEntity({required this.id, required this.y, required this.x});

  updatePosition(int newY, int newX) {
    y = newY;
    x = newX;
  }
}

// 地图栈
class MapDataStack {
  late final int y, x; // 地图在父地图的位置
  late final MapDataStack? parent; // 父节点
  final List<MapDataStack> children = []; // 子节点列表
  int leaveY = 0, leaveX = 0; // 玩家离开地图时的位置
  List<List<CellData>> leaveMap = []; // 玩家离开时的地图数据
  List<MovableEntity> entities = []; // 地图上的实体数据

  MapDataStack({required this.y, required this.x, required this.parent});
}

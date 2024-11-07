import '../foundation/energy.dart';
import '../foundation/entity.dart';
import '../foundation/map.dart';
import 'elemental.dart';
import 'prop.dart';

class PlayerElemental extends Elemental {
  late final Map<EntityID, MapProp> props;
  late int money;
  late int experience;
  Direction lastDirection = Direction.down;
  int col = 0;
  int row = 0;

  PlayerElemental({required super.id, required super.y, required super.x})
      : super(name: "旅行者", count: EnergyType.values.length, upgradeTimes: 0) {
    money = 20;
    experience = 60;
    props = PropCollection.totalItems;
  }

  void updateDirection(Direction direction) {
    if (direction == lastDirection) {
      row = (row + 1) % 4;
    } else {
      lastDirection = direction;
      row = 0;
      switch (direction) {
        case Direction.down:
          col = 0;
          break;
        case Direction.left:
          col = 4;
          break;
        case Direction.up:
          col = 8;
          break;
        case Direction.right:
          col = 12;
          break;
      }
    }
  }
}

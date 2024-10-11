import '../foundation/energy.dart';
import '../foundation/entity.dart';
import 'elemental.dart';
import 'prop.dart';

class PlayerElemental extends Elemental {
  late final Map<EntityID, MapProp> props;
  late int money;
  late int experience;
  int gained = 0;
  PlayerElemental({required super.id, required super.y, required super.x})
      : super(name: "旅行者", count: EnergyType.values.length, level: 2) {
    money = 20;
    experience = 60;
    props = PropCollection.totalItems;
  }

  addExperience(int num) {
    experience += num;
    gained += num;
    if (gained >= 30) {
      gained -= 30;
      level++;
    }
  }
}

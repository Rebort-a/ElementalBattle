import '../foundation/energy.dart';
import '../foundation/entity.dart';
import 'elemental.dart';
import 'prop.dart';

class PlayerElemental extends Elemental {
  late final Map<EntityID, MapProp> props;
  late int money;
  late int _experience;
  int _gained = 0;
  PlayerElemental({required super.id, required super.y, required super.x})
      : super(name: "旅行者", count: EnergyType.values.length, level: 2) {
    money = 20;
    _experience = 60;
    props = PropCollection.totalItems;
  }

  int get experience => _experience;

  changeExperience(int value) {
    _experience += value;
    if (value > 0) {
      _gained += value;
      if (_gained >= 30) {
        _gained -= 30;
        level++;
        preview.level++;
      }
    }
  }
}

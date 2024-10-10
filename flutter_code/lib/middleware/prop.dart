import 'package:flutter/material.dart';
import '../foundation/entity.dart';

class MapProp {
  late final EntityID id;
  late final String name;
  late final String description;
  late final String icon;
  late final IconData? type;
  late final int price;
  int count = 0;

  MapProp({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.price,
  });
}

class PropCollection {
  static final Map<EntityID, MapProp> totalItems = {
    EntityID.hospital: hospital,
    EntityID.sword: sword,
    EntityID.shield: shield,
    EntityID.scroll: scroll,
  };

  static final Map<EntityID,
          void Function(BuildContext context, void Function(int index) onTap)>
      totalItemHandler = {
    EntityID.hospital: (context, onTap) {},
    EntityID.sword: (context, onTap) {},
    EntityID.shield: (context, onTap) {},
    EntityID.scroll: (context, onTap) {},
  };

  static MapProp emptyItem = MapProp(
    id: EntityID.road,
    name: '',
    description: '',
    icon: '',
    type: null,
    price: 0,
  );

  static MapProp hospital = MapProp(
    id: EntityID.hospital,
    name: '药水',
    description: '生命值+32',
    icon: '💊',
    type: Icons.local_hospital,
    price: 10,
  );

  static MapProp sword = MapProp(
    id: EntityID.sword,
    name: '剑',
    description: '攻击力+8',
    icon: '🗡️',
    type: Icons.colorize,
    price: 10,
  );

  static MapProp shield = MapProp(
    id: EntityID.shield,
    name: '盾',
    description: '防御力+8',
    icon: '🛡️',
    type: Icons.shield,
    price: 10,
  );
  static MapProp scroll = MapProp(
    id: EntityID.scroll,
    name: '回城卷轴',
    description: '随时随地可以回家',
    icon: '📜',
    type: null,
    price: 10,
  );
}

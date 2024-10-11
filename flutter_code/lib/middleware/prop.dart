import 'package:flutter/material.dart';

import '../foundation/energy.dart';
import '../foundation/entity.dart';
import 'common.dart';
import 'elemental.dart';

class MapProp {
  final EntityID id;
  final String name;
  final String description;
  final String icon;
  final IconData? type;
  final int price;
  void Function(BuildContext context, Elemental elemental, MapProp prop)
      handler;
  int count = 0;

  MapProp({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.price,
    required this.handler,
  });
}

class PropCollection {
  static final Map<EntityID, MapProp> totalItems = {
    EntityID.hospital: hospital,
    EntityID.sword: sword,
    EntityID.shield: shield,
    EntityID.scroll: scroll,
  };

  static MapProp emptyItem = MapProp(
    id: EntityID.road,
    name: '',
    description: '',
    icon: '',
    type: null,
    price: 0,
    handler: (context, elemental, prop) {},
  );

  static MapProp hospital = MapProp(
    id: EntityID.hospital,
    name: '药',
    description: '生命值+32',
    icon: '💊',
    type: Icons.local_hospital,
    price: 10,
    handler: (context, elemental, prop) {
      SelectEnergy(
          context: context,
          energies: elemental.energies,
          onSelected: (index) {
            prop.count--;
            elemental.recoverHealth(index, 32);
          },
          available: false);
    },
  );

  static MapProp sword = MapProp(
    id: EntityID.sword,
    name: '剑',
    description: '攻击力+8',
    icon: '🗡️',
    type: Icons.colorize,
    price: 10,
    handler: (context, elemental, prop) {
      SelectEnergy(
          context: context,
          energies: elemental.energies,
          onSelected: (index) {
            prop.count--;
            elemental.upgradeEnergy(index, AttributeType.atk);
          },
          available: false);
    },
  );

  static MapProp shield = MapProp(
    id: EntityID.shield,
    name: '盾',
    description: '防御力+8',
    icon: '🛡️',
    type: Icons.shield,
    price: 10,
    handler: (context, elemental, prop) {
      SelectEnergy(
          context: context,
          energies: elemental.energies,
          onSelected: (index) {
            prop.count--;
            elemental.upgradeEnergy(index, AttributeType.def);
          },
          available: false);
    },
  );
  static MapProp scroll = MapProp(
    id: EntityID.scroll,
    name: '回城卷轴',
    description: '随时随地可以回家',
    icon: '📜',
    type: null,
    price: 10,
    handler: (context, elemental, prop) {},
  );
}

import 'package:flutter/material.dart';

import '../foundation/energy.dart';
import '../middleware/common.dart';
import '../middleware/entity.dart';
import '../middleware/prop.dart';
import 'home_logic.dart';

class PackagePage extends StatefulWidget {
  final HomeLogic homeLogic;
  const PackagePage({super.key, required this.homeLogic});

  @override
  State<PackagePage> createState() => _PackagePageState();
}

class _PackagePageState extends State<PackagePage> {
  MapProp _selectedItem = PropCollection.emptyItem;

  void _onItemTap(MapProp item) {
    setState(() {
      _selectedItem = item;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('背包'),
        centerTitle: true,
        backgroundColor: Colors.brown[100],
      ),
      backgroundColor: Colors.brown[800],
      body: Column(
        children: [
          _buildGoldDisplay(),
          _buildInventoryGrid(),
          _buildSelectedItemInfo(),
        ],
      ),
    );
  }

  Widget _buildGoldDisplay() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.brown[100],
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('金币数量: ${widget.homeLogic.player.money}'),
        ],
      ),
    );
  }

  Widget _buildInventoryGrid() {
    // 过滤出数量大于0的物品
    final filteredItems =
        widget.homeLogic.player.props.values.where((item) => item.count > 0);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.brown[100],
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          padding: const EdgeInsets.all(10),
          children: List.generate(16, (index) {
            final item = filteredItems.length > index
                ? filteredItems.elementAt(index)
                : null;
            return _buildItemTile(item);
          }),
        ),
      ),
    );
  }

  Widget _buildSelectedItemInfo() {
    return Visibility(
      visible: _selectedItem.count > 0,
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.brown[100],
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('名称:${_selectedItem.name}'),
                Text(_selectedItem.description),
              ],
            ),
            ElevatedButton(
              onPressed: _selectedItem.count > 0
                  ? () => setState(() => _useItem())
                  : null,
              child: const Text('使用'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(MapProp? item) {
    return item != null
        ? GestureDetector(
            onTap: () => _onItemTap(item),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: Colors.black.withOpacity(0.3), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                          child: Text(item.icon,
                              style: const TextStyle(fontSize: 24))),
                      _buildItemTypeIcon(item),
                      _buildItemCountBadge(item),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(5),
              border:
                  Border.all(color: Colors.black.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Center(),
          );
  }

  Widget _buildItemTypeIcon(MapProp item) {
    return item.type != null
        ? Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(item.type),
            ),
          )
        : const Center();
  }

  Widget _buildItemCountBadge(MapProp item) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(5),
        ),
        child:
            Text('${item.count}', style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  _useItem() {
    switch (_selectedItem.id) {
      case EntityID.hospital:
        SelectEnergy(
            context: context,
            elemental: widget.homeLogic.player,
            onSelected: (int index) {
              _increasePlayerAttribute(
                  _selectedItem, index, AttributeType.hp, 1);
            },
            available: false);
        break;
      case EntityID.sword:
        SelectEnergy(
            context: context,
            elemental: widget.homeLogic.player,
            onSelected: (int index) {
              _increasePlayerAttribute(
                  _selectedItem, index, AttributeType.atk, 1);
            },
            available: false);
        break;
      case EntityID.shield:
        SelectEnergy(
            context: context,
            elemental: widget.homeLogic.player,
            onSelected: (int index) {
              _increasePlayerAttribute(
                  _selectedItem, index, AttributeType.def, 1);
            },
            available: false);
        break;
      case EntityID.scroll:
        widget.homeLogic.backToMain();
        setState(() {
          _selectedItem.count--;
        });
        Navigator.of(context).pop();
        break;
      default:
        break;
    }
  }

  _increasePlayerAttribute(
      MapProp item, int index, AttributeType attribute, int times) {
    for (int i = 0; i < times; i++) {
      if (attribute == AttributeType.hp) {
        widget.homeLogic.player.recoverHealth(index, 32);
      } else {
        widget.homeLogic.player.upgradeEnergy(index, attribute);
      }
    }
    widget.homeLogic.player.updateEnergy();
    setState(() {
      item.count--;
    });
  }
}

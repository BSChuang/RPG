import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rpg/main.dart';
import 'package:rpg/sprites.dart';

class Inventory extends StatefulWidget {
  @override
  _InventoryState createState() => new _InventoryState();
}

class _InventoryState extends State<Inventory> {
  Map<String, Item> inventory = new Map(); // Item id, personal item fields
  Map<String, Map<dynamic, dynamic>> allDict =
      new Map(); // item name: item fields
  Map<dynamic, dynamic> equipped = new Map();
  List<dynamic> skills = new List();

  dynamic currentItem;

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    getInventory();
    getEquipped();
    return Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage(
                    "assets/images/backgrounds/airadventurelevel1.png"),
                fit: BoxFit.cover)),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(child: buildMain()),
          bottomNavigationBar: BottomNavigationBar(
            onTap: onTabTapped,
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            items: [
              new BottomNavigationBarItem(
                  icon: new Icon(Icons.color_lens), title: new Text('Items')),
              new BottomNavigationBarItem(
                  icon: new Icon(Icons.book), title: new Text('Skills')),
            ],
          ),
        ));
  }

  Widget buildMain() {
    return Row(children: <Widget>[
      buildDescription(),
      buildItems(_currentIndex),
      buildModel(_currentIndex)
    ]);
  }

  Widget buildDescription() {
    if (currentItem == null) {
      return Container(width: 175, color: Colors.black12);
    }

    List<Text> text = new List();
    if (currentItem is Item) {
      // IS ITEM
      Map<dynamic, dynamic> _item = allDict[currentItem.name];

      text.add(Text('Level: ' + currentItem.lvl.toString()));
      text.add(Text('Slot: ' + _item['slot'].toString()));

      if (_item['slot'] == 'weapon') {
        text.add(Text('Damage: ' + _item['damage'].toString()));
        text.add(Text('Critical chance: ' + _item['critChance'].toString()));
        text.add(Text('Critical damage: ' + _item['critDamage'].toString()));
      } else {
        text.add(Text('Armor: ' + _item['armor'].toString()));
        text.add(Text('Armor type: ' + _item['type'].toString()));
      }

      Text description = Text('\n' + _item['description'].toString(),
          style: TextStyle(fontStyle: FontStyle.italic));

      return Container(
          child: Column(
            children: <Widget>[
              Sprites.makeSprite(_item['sprite'], 2),
              ListBody(children: text),
              description,
              FlatButton(
                child: Text('Equip'),
                color: Colors.white70,
                onPressed: () {
                  equipItem(currentItem);
                },
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceAround,
          ),
          width: 175,
          color: Colors.black12);
    } else {
      // IS SKILL
      Map<dynamic, dynamic> _skill = allDict[currentItem];

      text.add(Text('Damage: ' + _skill['damage'].toString()));
      text.add(Text('Cooldown: ' + _skill['cooldown'].toString()));

      Text description = Text('\n' + _skill['description'].toString(),
          style: TextStyle(fontStyle: FontStyle.italic));

      Row row = Row(
        children: <Widget>[
          Flexible(child: ListBody(children: text)),
          Container(
            child: Icon(Icons.android),
            alignment: Alignment.centerLeft,
          )
        ],
      );

      return Container(
          child: Column(
            children: <Widget>[
              Sprites.makeSprite(_skill['sprite'], 2),
              ListBody(children: text),
              description,
              FlatButton(
                child: Text('Equip'),
                color: Colors.white70,
                onPressed: () {
                  chooseSkillSlot();
                },
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceAround,
          ),
          width: 175,
          color: Colors.black12);
    }
  }

  /// Builds a clickable box for each item, then places them in a grid
  Widget buildItems(int page) {
    List<GridTile> tiles = new List();
    Widget image;

    if (page == 0) {
      for (Item item in inventory.values) {
        if (allDict.containsKey(item.name) && item.sprite != null) {
          image = Sprites.makeSprite(allDict[item.name]['sprite'], 2);
        } else {
          image = Icon(Icons.error);
        }

        tiles.add(GridTile(
          child: Container(
              decoration: BoxDecoration(
                  color: Colors.black38,
                  border: Border.all(color: Colors.black54, width: 0.75),
                  borderRadius: BorderRadius.all(Radius.circular(5))),
              child: InkResponse(
                enableFeedback: true,
                child: Center(child: image),
                onTap: () => pressItem(item),
              )),
        ));
      }
    } else {
      for (String skill in skills) {
        if (allDict.containsKey(skill) && allDict[skill]['sprite'] != null) {
          image = Sprites.makeSprite(allDict[skill]['sprite'], 2);
        } else {
          image = Icon(Icons.error);
        }

        tiles.add(GridTile(
          child: Container(
              decoration: BoxDecoration(
                color: Colors.black38,
                  border: Border.all(color: Colors.black54, width: 0.75),
                  borderRadius: BorderRadius.all(Radius.circular(5))),
              child: InkResponse(
                enableFeedback: true,
                child: Center(child: image),
                onTap: () => pressSkill(skill),
              )),
        ));
      }
    }

    if (tiles.length == 0) {
      return Expanded(child: Center(child: Text("Loading...")));
    }

    return Expanded(
        child: GridView.count(
            crossAxisCount: 6,
            padding: EdgeInsets.all(5.0),
            mainAxisSpacing: 4.0,
            crossAxisSpacing: 4.0,
            children: tiles));
  }

  Widget buildModel(int page) {
    List<Widget> items = new List();
    String name;
    Widget sprite;
    if (page == 0) {
      List<String> armorStr = [
        'weapon',
        'head',
        'torso',
        'hands',
        'legs',
        'feet',
      ];

      for (String armor in armorStr) {
        Row row = new Row();;
        if (inventory[equipped[armor]] != null) {
          name = inventory[equipped[armor]].name;
          sprite = Sprites.makeSprite(
              allDict[inventory[equipped[armor]].name]['sprite'], 1.75);

          row = Row(children: <Widget>[
            Container(width: 10),
            sprite,
            Container(width: 10),
            Expanded(
                child: Text(inventory[equipped[armor]].name,
                    style: TextStyle(fontSize: 15)))
          ], mainAxisAlignment: MainAxisAlignment.spaceEvenly);
        }

        items.add(row);
      }
    } else {
      List<String> skillStr = ['skill1', 'skill2', 'skill3', 'skill4'];

      for (String skill in skillStr) {
        Row row = new Row();
        if (equipped[skill] != "" && allDict.containsKey(equipped[skill])) {
          name = equipped[skill];
          sprite = Sprites.makeSprite(allDict[equipped[skill]]['sprite'], 1.75);

          row = Row(children: <Widget>[
            Container(width: 10),
            sprite,
            Container(width: 10),
            Expanded(
                child: Text(equipped[skill], style: TextStyle(fontSize: 15)))
          ], mainAxisAlignment: MainAxisAlignment.spaceEvenly);
        }

        items.add(row);
      }
    }

    return Container(
        child: Column(
            children: items, mainAxisAlignment: MainAxisAlignment.spaceAround),
        width: 150,
        color: Colors.black12);
  }

  /// Gets the specific data from the inventory items. Adds the data to items dict and items list
  Future getInventory() async {
    Map<String, Item> _inventory = new Map();
    QuerySnapshot result = await Firestore.instance
        .collection('players')
        .document(Data.user.uid)
        .collection('inventory')
        .orderBy('lvl')
        .getDocuments();
    for (DocumentSnapshot doc in result.documents) {
      Item _item;
      String _name = doc.data['name'];

      if (!allDict.containsKey(doc.data['name'])) {
        DocumentSnapshot _itemDoc = await Firestore.instance
            .collection('equipment')
            .document(doc.data['name'])
            .get();
        allDict[_name] = _itemDoc.data;
      }

      if (allDict[_name]['slot'] == 'weapon') {
        _item = new Item.weapon(
            doc.documentID,
            doc.data['lvl'],
            doc.data['name'],
            doc.data['properties'],
            allDict[_name]['stat'],
            allDict[_name]['sprite'],
            allDict[_name]['damage'],
            allDict[_name]['critChance'],
            allDict[_name]['critDamage'],
            allDict[_name]['description']);
      } else {
        _item = new Item.armor(
            doc.documentID,
            doc.data['lvl'],
            doc.data['name'],
            doc.data['properties'],
            allDict[_name]['slot'],
            allDict[_name]['stat'],
            allDict[_name]['sprite'],
            allDict[_name]['armor'],
            allDict[_name]['description']);
      }
      _inventory[doc.documentID] = _item;
    }
    DocumentSnapshot playerData = await Firestore.instance
        .collection('players')
        .document(Data.user.uid)
        .get();
    List<dynamic> _skills = playerData.data['knownSkills'];
    for (String skill in _skills) {
      if (!allDict.containsKey(skill)) {
        DocumentSnapshot _itemDoc =
            await Firestore.instance.collection('skills').document(skill).get();
        allDict[skill] = _itemDoc.data;
      }
    }

    setState(() {
      inventory = _inventory;
      skills = _skills;
    });
  }

  /// Gets the items currently equipped
  Future getEquipped() async {
    DocumentSnapshot doc = await Firestore.instance
        .collection('players')
        .document(Data.user.uid)
        .get();
    equipped = doc.data['equipment'];
  }

  /// Whether equipment/skills are pressed
  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// When a box is clicked
  Future<void> pressItem(Item item) async {
    if (!allDict.containsKey(item.name)) {
      DocumentSnapshot doc = await Firestore.instance
          .collection('equipment')
          .document(item.name)
          .get();
      allDict[item.name] = doc.data;
    }
    setState(() {
      currentItem = item;
    });
  }

  Future<void> pressSkill(String skill) async {
    if (!allDict.containsKey(skill)) {
      DocumentSnapshot doc =
          await Firestore.instance.collection('skills').document(skill).get();
      allDict[skill] = doc.data;
    }

    setState(() {
      currentItem = skill;
    });
  }

  Future<void> chooseSkillSlot() {
    String empty(String tempSkill) {
      if (tempSkill == "")
        return 'Empty';
      else
        return tempSkill;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Replace skill with ' + currentItem + '?'),
          actions: <Widget>[
            FlatButton(
              child: Text(empty(equipped['skill1'])),
              onPressed: () {
                Navigator.of(context).pop();
                equipSkill(currentItem, 1);
              },
            ),
            FlatButton(
              child: Text(empty(equipped['skill2'])),
              onPressed: () {
                Navigator.of(context).pop();
                equipSkill(currentItem, 2);
              },
            ),
            FlatButton(
              child: Text(empty(equipped['skill3'])),
              onPressed: () {
                Navigator.of(context).pop();
                equipSkill(currentItem, 3);
              },
            ),
            FlatButton(
              child: Text(empty(equipped['skill4'])),
              onPressed: () {
                Navigator.of(context).pop();
                equipSkill(currentItem, 4);
              },
            ),
          ],
        );
      },
    );
  }

  /// Adds the item to equipped dict
  Widget equipItem(Item item) {
    equipped[allDict[item.name]['slot']] = item.id;
    Firestore.instance
        .collection('players')
        .document(Data.user.uid)
        .updateData({'equipment': equipped});
  }

  /// equips skill
  Widget equipSkill(String skill, int skillNum) {
    equipped['skill' + skillNum.toString()] = skill;
    Firestore.instance
        .collection('players')
        .document(Data.user.uid)
        .updateData({'equipment': equipped});
  }

  // Builds the boxes for the equipped items

}

class Item {
  String id;
  int lvl;
  String name;
  String description;
  String slot;
  String sprite;
  String stat;

  int armor;

  int damage;
  int critChance;
  int critDamage;

  Map<dynamic, dynamic> properties;

  Item(String id, int lvl, String name, Map<dynamic, dynamic> properties) {
    this.id = id;
    this.lvl = lvl;
    this.name = name;
    this.properties = properties;
  }

  Item.armor(String id, int lvl, String name, Map<dynamic, dynamic> properties,
      String slot, String stat, String sprite, int armor, String description) {
    this.id = id;
    this.lvl = lvl;
    this.name = name;
    this.stat = stat;
    this.slot = slot;
    this.sprite = sprite;
    this.properties = properties;
    this.armor = armor;
    this.slot = slot;
    this.description = description;
  }

  Item.weapon(
      String id,
      int lvl,
      String name,
      Map<dynamic, dynamic> properties,
      String stat,
      String sprite,
      int damage,
      int critChance,
      int critDamage,
      String description) {
    this.id = id;
    this.lvl = lvl;
    this.name = name;
    this.stat = stat;
    this.slot = slot;
    this.sprite = sprite;
    this.properties = properties;
    this.armor = armor;
    this.damage = damage;
    this.critChance = critChance;
    this.critDamage = critDamage;
    this.slot = 'weapon';
    this.description = description;
  }

  void setArmor(int armor, String slot) {
    this.armor = armor;
    this.slot = slot;
  }

  void setWeapon(int damage, int critChance, int critDamage) {
    this.damage = damage;
    this.critChance = critChance;
    this.critDamage = critDamage;
    this.slot = 'weapon';
  }
}

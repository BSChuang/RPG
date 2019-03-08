import 'package:flutter/material.dart';
import 'package:rpg/skills.dart';
import 'package:rpg/character.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rpg/battle.dart';
import 'package:rpg/home.dart';
import 'package:rpg/inventory.dart';
import 'package:rpg/main.dart';

class Inventory extends StatefulWidget {
  @override
  _InventoryState createState() => new _InventoryState();
}

class _InventoryState extends State<Inventory> {
  Map<String, Item> inventory = new Map(); // Item id, personal item fields
  Map<String, Map<dynamic, dynamic>> allDict = new Map(); // item name: item fields
  Map<dynamic, dynamic> equipped = new Map();
  List<dynamic> skills = new List();

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;

    getInventory();
    getEquipped();

    if (_currentIndex == 0) {
      page = buildItemsWidget();
    } else {
      page = buildSkillsWidget();
    }

    return Scaffold(
      body: Column(
          children: <Widget>[
            Text('Equipment'),
            page,
            buildEquipped()
          ]),
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          new BottomNavigationBarItem(
              icon: new Icon(Icons.color_lens),
              title: new Text('Equipment')
          ),
          new BottomNavigationBarItem(
              icon: new Icon(Icons.book),
              title: new Text('Skills')
          ),
        ],
      ),
    );
  }

  /// Whether equipment/skills are pressed
  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget buildSkillsWidget() {
    List<GridTile> tiles = new List();
    for (dynamic skill in skills) {
      tiles.add(GridTile(
        child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.black87,
                    width: 0.5
                )
            ),
            child: InkResponse(
              enableFeedback: true,
              child: Center(
                  child: Container(
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: Icon(Icons.android),
                          ),
                          Expanded(
                              child: Text(skill, textAlign: TextAlign.center)
                          )
                        ],
                      )
                  )
              ),
              onTap: () => pressSkill(skill),
            )
        ),
      ));
    }

    return Container(
      height: 250,
        child: GridView.count(
            crossAxisCount: 5,
            padding: EdgeInsets.all(5.0),
            mainAxisSpacing: 4.0,
            crossAxisSpacing: 4.0,
            children: tiles
        )
    );
  }

  /// Builds a clickable box for each item, then places them in a grid
  Widget buildItemsWidget() {
    List<GridTile> tiles = new List();
    for (Item item in inventory.values) {
      Widget image;
      if (allDict.containsKey(item.name) && item.sprite != null) {
        image = Image(fit: BoxFit.none, image: new AssetImage('assets/sprites/' + allDict[item.name]['sprite']));
      } else {
        image = Icon(Icons.android);
      }
      tiles.add(GridTile(
        child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.black87,
                    width: 0.5
                )
            ),
            child: InkResponse(
              enableFeedback: true,
                child: Center(
                    child: Container(
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: image,
                            ),
                            Expanded(
                                child: Text(item.name, textAlign: TextAlign.center)
                            )
                          ],
                        )
                    )
                ),
              onTap: () => pressItem(item),
            )
        ),
      ));
    }

    return Container(
        height: 250.0,
        child: GridView.count(
            crossAxisCount: 5,
            padding: EdgeInsets.all(5.0),
            mainAxisSpacing: 4.0,
            crossAxisSpacing: 4.0,
            children: tiles
        )
    );
  }

  /// Gets the specific data from the inventory items. Adds the data to items dict and items list
  Future getInventory() async {
    Map<String, Item> _inventory = new Map();
    QuerySnapshot result = await Firestore.instance.collection('players').document(Data.user.uid).collection('inventory').orderBy('lvl').getDocuments();
    for (DocumentSnapshot doc in result.documents) {
      Item _item;
      String _name = doc.data['name'];

      if (!allDict.containsKey(doc.data['name'])) {
        DocumentSnapshot _itemDoc = await Firestore.instance.collection('equipment').document(doc.data['name']).get();
        allDict[_name] = _itemDoc.data;
      }

      if (allDict[_name]['slot'] == 'weapon') {
        _item = new Item.weapon(doc.documentID, doc.data['lvl'], doc.data['name'], doc.data['properties'], allDict[_name]['stat'], allDict[_name]['sprite'], allDict[_name]['damage'],
            allDict[_name]['critChance'], allDict[_name]['critDamage'], allDict[_name]['description']);
      } else {
        _item = new Item.armor(doc.documentID, doc.data['lvl'], doc.data['name'], doc.data['properties'], allDict[_name]['slot'], allDict[_name]['stat'], allDict[_name]['sprite'],
            allDict[_name]['armor'], allDict[_name]['description']);
      }
      _inventory[doc.documentID] = _item;
    }
    DocumentSnapshot playerData = await Firestore.instance.collection('players').document(Data.user.uid).get();
    List<dynamic> _skills = playerData.data['knownSkills'];

    setState(() {
      inventory = _inventory;
      skills = _skills;
    });
  }

  /// Gets the items currently equipped
  Future getEquipped() async {
    DocumentSnapshot doc = await Firestore.instance.collection('players').document(Data.user.uid).get();
    equipped = doc.data['equipment'];
  }

  /// When a box is clicked
  Future<void> pressItem(Item item) async {
    List<Text> text = new List();

    if (!allDict.containsKey(item.name)) {
      DocumentSnapshot doc = await Firestore.instance.collection('equipment').document(item.name).get();
      allDict[item.name] = doc.data;
    }

    Map<dynamic, dynamic> _item = allDict[item.name];

    text.add(Text('Level: ' + item.lvl.toString()));
    text.add(Text('Slot: ' + _item['slot'].toString()));

    if (_item['slot'] == 'weapon') {
      text.add(Text('Damage: ' + _item['damage'].toString()));
      text.add(Text('Critical chance: ' + _item['critChance'].toString()));
      text.add(Text('Critical damage: ' + _item['critDamage'].toString()));
    } else {
      text.add(Text('Armor: ' + _item['armor'].toString()));
      text.add(Text('Armor type: ' + _item['type'].toString()));
    }

    Text description = Text('\n' + _item['description'].toString(), style: TextStyle(fontStyle: FontStyle.italic));

    Row row = Row(
      children: <Widget>[
        Flexible(child: ListBody(children: text)),
        Container(child: Icon(Icons.android), alignment: Alignment.centerLeft,)
      ],
    );

    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(item.name),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                row,
                description
              ],
            )
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Equip'),
              onPressed: () {
                equipItem(item);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> pressSkill(String skill) async {
    List<Text> text = new List();

    if (!allDict.containsKey(skill)) {
      DocumentSnapshot doc = await Firestore.instance.collection('skills').document(skill).get();
      allDict[skill] = doc.data;
    }

    Map<dynamic, dynamic> _skill = allDict[skill];

    text.add(Text('Damage: ' + _skill['damage'].toString()));
    text.add(Text('Cooldown: ' + _skill['cooldown'].toString()));

    Text description = Text('\n' + _skill['description'].toString(), style: TextStyle(fontStyle: FontStyle.italic));

    Row row = Row(
      children: <Widget>[
        Flexible(child: ListBody(children: text)),
        Container(child: Icon(Icons.android), alignment: Alignment.centerLeft,)
      ],
    );

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
          title: Text('Replace skill with ' + skill + '?'),
          content: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  row,
                  description
                ],
              )
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(empty(equipped['skill1'])),
              onPressed: () {
                Navigator.of(context).pop();
                equipSkill(skill, 1);
              },
            ),
            FlatButton(
              child: Text(empty(equipped['skill2'])),
              onPressed: () {
                Navigator.of(context).pop();
                equipSkill(skill, 2);
              },
            ),
            FlatButton(
              child: Text(empty(equipped['skill3'])),
              onPressed: () {
                Navigator.of(context).pop();
                equipSkill(skill, 3);
              },
            ),
            FlatButton(
              child: Text(empty(equipped['skill4'])),
              onPressed: () {
                Navigator.of(context).pop();
                equipSkill(skill, 4);
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
    Firestore.instance.collection('players').document(Data.user.uid).updateData({
      'equipment': equipped
    });
  }

  /// equips skill
  Widget equipSkill(String skill, int skillNum) {
    equipped['skill' + skillNum.toString()] = skill;
    Firestore.instance.collection('players').document(Data.user.uid).updateData({
      'equipment': equipped
    });
  }

  // Builds the boxes for the equipped items
  Widget buildEquipped() {
    List<String> armorStr = ['weapon', 'head', 'torso', 'legs', 'feet', 'hands'];
    List<String> skillStr = ['skill1', 'skill2', 'skill3', 'skill4'];
    List<Widget> armors = new List();
    List<Widget> skills = new List();

    for (String armor in armorStr) {
      String armorName = "Empty";
      Image sprite;
      if (inventory[equipped[armor]] != null) {
        armorName = inventory[equipped[armor]].name;
        sprite = Image(fit: BoxFit.none, image: new AssetImage('assets/sprites/' + allDict[inventory[equipped[armor]].name]['sprite']));
      }

      armors.add(GridTile(
        child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.black87,
                    width: 0.5
                )
            ),
            child:Center(
                child: Container(
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: sprite,
                        ),
                        Expanded(
                            child: Text(armorName, textAlign: TextAlign.center)
                        ),
                      ],
                    )
                )
            )
        ),
      ));
    }

    for (String skill in skillStr) {
      String skillName = 'Empty';
      if (equipped[skill] != null && equipped[skill] != "") {
        skillName = equipped[skill];
      }

      skills.add(GridTile(
        child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.black87,
                    width: 0.5
                )
            ),
            child: Center(
                child: Container(
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: Icon(Icons.android),
                        ),
                        Expanded(
                            child: Text(skillName, textAlign: TextAlign.center)
                        )
                      ],
                    )
                )
            )
        ),
      ));
    }

    return Flexible(
      child: Column(
        children: <Widget>[
          Container(
            child: Flexible(
                child: IgnorePointer(
                    child: GridView.count(
                        crossAxisCount: 6,
                        padding: EdgeInsets.all(5.0),
                        mainAxisSpacing: 4.0,
                        crossAxisSpacing: 4.0,
                        children: armors
                    )
                )
            )
          ),
          Flexible(
              child: IgnorePointer(
                  child: GridView.count(
                      crossAxisCount: 4,
                      padding: EdgeInsets.all(5.0),
                      mainAxisSpacing: 4.0,
                      crossAxisSpacing: 4.0,
                      children: skills
                  )
              )
          )
        ],
      ),
    );
  }
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

  Item.armor(String id, int lvl, String name, Map<dynamic, dynamic> properties, String slot, String stat, String sprite, int armor, String description) {
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

  Item.weapon(String id, int lvl, String name, Map<dynamic, dynamic> properties, String stat, String sprite, int damage, int critChance, int critDamage, String description) {
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
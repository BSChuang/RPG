import 'package:flutter/material.dart';
import 'package:rpg/skills.dart';
import 'package:rpg/character.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  List<Item> items = new List();
  Map<String, Item> itemsDict = new Map(); // Item id, personal item fields
  Map<String, Map<dynamic, dynamic>> equipment = new Map(); // item name: item fields
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

    return Flexible(
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
    for (Item item in items) {
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

    return Flexible(
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
    List<Item> _items = new List();
    Map<String, Item> _itemsDict = new Map();
    QuerySnapshot result = await Firestore.instance.collection('players').document(LoadingScreen.user.uid).collection('inventory').orderBy('name').getDocuments();
    for (DocumentSnapshot doc in result.documents) {
      Item _item = new Item(doc.documentID, doc.data['lvl'], doc.data['name'], doc.data['properties']);
      _itemsDict[doc.documentID] = _item;
      _items.add(_item);
    }
    DocumentSnapshot playerData = await Firestore.instance.collection('players').document(LoadingScreen.user.uid).get();
    List<dynamic> _skills = playerData.data['knownSkills'];

    setState(() {
      items = _items;
      itemsDict = _itemsDict;
      skills = _skills;
    });
  }

  /// Gets the items currently equipped
  Future getEquipped() async {
    DocumentSnapshot doc = await Firestore.instance.collection('players').document(LoadingScreen.user.uid).get();
    equipped = doc.data['equipment'];
  }

  /// When a box is clicked
  Future<void> pressItem(Item item) async {
    List<Text> text = new List();

    if (!equipment.containsKey(item.name)) {
      DocumentSnapshot doc = await Firestore.instance.collection('equipment').document(item.name).get();
      equipment[item.name] = doc.data;
    }

    Map<dynamic, dynamic> _item = equipment[item.name];

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
      barrierDismissible: false, // user must tap button!
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
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('Equip'),
              onPressed: () {
                setEquip(item);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> pressSkill(String skill) async {
    
  }

  /// Adds the item to equipped dict
  Widget setEquip(Item item) {
    equipped[equipment[item.name]['slot']] = item.id;
    Firestore.instance.collection('players').document(LoadingScreen.user.uid).updateData({
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
      if (itemsDict[equipped[armor]] != null) {
        armorName = itemsDict[equipped[armor]].name;
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
                          child: Icon(Icons.android),
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
                            child: Text('test', textAlign: TextAlign.center)
                        ),
                        Expanded(
                            child: Text('test', textAlign: TextAlign.center)
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
                child: GridView.count(
                    crossAxisCount: 6,
                    padding: EdgeInsets.all(5.0),
                    mainAxisSpacing: 4.0,
                    crossAxisSpacing: 4.0,
                    children: armors
                )
            )
          ),
          Flexible(
              child: GridView.count(
                  crossAxisCount: 4,
                  padding: EdgeInsets.all(5.0),
                  mainAxisSpacing: 4.0,
                  crossAxisSpacing: 4.0,
                  children: skills
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
  Map<dynamic, dynamic> properties;

  Item(String id, int lvl, String name, Map<dynamic, dynamic> properties) {
    this.id = id;
    this.lvl = lvl;
    this.name = name;
    this.properties = properties;
  }
}
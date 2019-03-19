import 'package:flutter/material.dart';
import 'package:rpg/skills.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rpg/main.dart';
import 'package:rpg/sprites.dart';
import 'dart:math';

class Battle extends StatefulWidget {
  @override
  _BattleState createState() => new _BattleState();
}

class _BattleState extends State<Battle> {
  Map<String, dynamic> allies = new Map();
  Map<String, dynamic> enemies = new Map();

  Map<String, dynamic> useSkill = new Map();

  String midText = "";

  bool finishTurn = false;
  int remaining = -1;
  int turn = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage(
                    "assets/images/backgrounds/airadventurelevel4.png"),
                fit: BoxFit.cover)),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
                child: StreamBuilder(
                    stream: Firestore.instance
                        .collection('battles')
                        .document(Data.battleID)
                        .snapshots(),
                    builder: (con, snap) => buildScreen(snap)))));
  }

  Widget buildScreen(AsyncSnapshot snap) {
    DocumentSnapshot _temp = snap.data;
    Map<String, dynamic> data;
    if (!snap.hasData) {
      return Text('Loading...');
    } else {
      data = _temp.data;
    }

    checkQueue();

    if (turn != data['turn']) {
      turn = data['turn'];
      getAllUnits();
    }

    Container botContainer = Container(
      child: Column(
        children: <Widget>[
          Container(
              child: Center(
                  child: Text(
                "Turn $turn\n" + midText,
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              )),
              color: Colors.black12),
          Container(height: 10),
          useSkill.containsKey('skill') ? buildTargetButtons() : buildSkills()
        ],
        mainAxisAlignment: MainAxisAlignment.start,
      ),
      height: 160,
    );

    return Column(
      children: <Widget>[buildBattle(), botContainer],
      mainAxisAlignment: MainAxisAlignment.spaceAround,
    );
  }

  Widget buildBattle() {
    if (allies.length == 0) {
      getAllUnits();
    }

    return Row(children: <Widget>[buildAllies(), buildEnemies()]);
  }

  Widget buildAllies() {
    Widget main = Container(
        child: Center(child: buildUnit(Data.user.uid, 70)));
    List<Widget> units = new List();
    for (String unit in allies.keys) {
      if (unit != Data.user.uid) {
        units.add(buildUnit(unit, (70 - allies.length * 2).toDouble()));
      }
    }

    /* for (int i = 0; i < 19; i++) {
      units.add(buildUnit(Data.user.uid, (70 - allies.length * 2).toDouble()));
    } */

    return Expanded(
        child: Row(
      children: <Widget>[
        (units.length == 0
            ? Container(height: 0, width: 0)
            : Expanded(child: buildUnitGrid(units))),
        main
      ],
      mainAxisAlignment: MainAxisAlignment.spaceAround,
    ));
  }

  Widget buildEnemies() {
    List<Widget> units = new List();
    for (String enemy in enemies.keys) {
      units.add(buildUnit(enemy, (80 - enemies.length * 2).toDouble()));
    }

    return Expanded(child: buildUnitGrid(units));
  }

  Widget buildUnitGrid(List<Widget> units) {
    if (units.length == 0) {
      return new Container(height: 0, width: 0);
    }
    int width = sqrt(units.length).ceil();
    List<Widget> heightList = List();

    List<Widget> widthList = new List();
    for (int i = 0; i < units.length; i++) {
      if (i % width == 0) {
        heightList.add(Row(
            children: widthList,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly));
        widthList = new List();
      }

      widthList.add(units[i]);

      if (i + 1 == units.length) {
        heightList.add(Row(
            children: widthList,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly));
        break;
      }
    }

    return Column(
        children: heightList, mainAxisAlignment: MainAxisAlignment.spaceEvenly);
  }

  Widget buildUnit(String id, double size) {
    //size = 30;
    Widget sprite;
    if (allies.containsKey(id)) {
      sprite = Sprites.makeSprite(allies[id]['anim']['idle'], size - 10);
    } else if (enemies.containsKey(id)) {
      sprite = Sprites.makeSprite(enemies[id]['anim']['idle'], size - 10);
    }

    BoxDecoration decoration;
    decoration = BoxDecoration(color: Colors.black12);
    if (useSkill.containsKey('targets') && useSkill['targets'].contains(id)) {
      if (allies.containsKey(id)) {
        decoration = BoxDecoration(
            color: Colors.black26,
            border: Border.all(width: 3, color: Colors.green));
      } else {
        decoration = BoxDecoration(
            color: Colors.black26,
            border: Border.all(width: 3, color: Colors.redAccent));
      }
    }

    Widget unit = GestureDetector(
        child: Container(
            child: Center(child: sprite),
            height: size,
            width: size,
            decoration: decoration),
        onTap: () {
          pressUnit(id);
        });

    double ap = 0;
    double hp = 0;
    if (allies.containsKey(id)) {
      ap = size * allies[id]['armor'] / allies[id]['maxArmor'];
      hp = size * allies[id]['hp'] / allies[id]['maxHP'];
    } else if (enemies.containsKey(id)) {
      ap = size * enemies[id]['armor'] / enemies[id]['maxArmor'];
      hp = size * enemies[id]['hp'] / enemies[id]['maxHP'];
    }

    Widget apBar = Row(
      children: <Widget>[
        Container(height: 7, width: (ap < 0 ? 0 : ap), color: Colors.grey),
        Container(height: 7, width: (size - ap), color: Colors.black54)
      ],
    );
    Widget hpBar = Row(
      children: <Widget>[
        Container(height: 7, width: (hp < 0 ? 0 : hp), color: Colors.lightGreenAccent),
        Container(height: 7, width: (size - hp), color: Colors.black54)
      ],
      mainAxisAlignment: MainAxisAlignment.start,
    );
    return Column(
      children: <Widget>[apBar, hpBar, unit],
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }

  void pressUnit(String id) {
    if (!useSkill.containsKey('skill')) {
      return;
    }

    if (useSkill['targets'].length < useSkill['skill']['targets'] &&
        !useSkill['targets'].contains(id)) {
      useSkill['targets'].add(id);
    } else if (useSkill['targets'].contains(id)) {
      useSkill['targets'].remove(id);
    }

    setState(() {
      useSkill = useSkill;
    });
  }

  Widget buildSkills() {
    if (!allies.containsKey(Data.user.uid)) {
      return Text("Loading...");
    }

    Map<dynamic, dynamic> skills = allies[Data.user.uid]['skills'];

    Row buttonRow1 = Row(children: <Widget>[
      buildSkillButton(skills['skill1']),
      Container(width: 15),
      buildSkillButton(skills['skill2'])
    ], mainAxisAlignment: MainAxisAlignment.center);

    Row buttonRow2 = Row(
      children: <Widget>[
        buildSkillButton(skills['skill3']),
        Container(width: 15),
        buildSkillButton(skills['skill4'])
      ],
      mainAxisAlignment: MainAxisAlignment.center,
    );

    return Container(
        child: Column(
      children: <Widget>[buttonRow1, Container(height: 5), buttonRow2],
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
    ));
  }

  Widget buildSkillButton(Map skill) {
    Row buttonChild = Row(children: <Widget>[
      Sprites.makeSprite(skill['sprite'], 1.25),
      Container(width: 10),
      Text(skill['name'])
    ], mainAxisAlignment: MainAxisAlignment.start);

    return Container(
        child: RaisedButton(
          child: buttonChild,
          onPressed: finishTurn
              ? null
              : () {
                  pressSkill(skill);
                },
          color: typeColor(skill['type']),
          disabledColor: Colors.white24,
        ),
        width: 200);
  }

  void pressSkill(Map currentSkill) {
    setState(() {
      midText =
          "Choose up to ${currentSkill['targets']} target${currentSkill['targets'] == 1 ? '' : 's'}.";
      useSkill = {'skill': currentSkill, 'targets': []};
    });
  }

  Widget buildTargetButtons() {
    return Row(children: <Widget>[
      FlatButton(
        child: Text("Confirm"),
        onPressed:
            (useSkill.containsKey('targets') && useSkill['targets'].length != 0)
                ? confirm
                : null,
        color: Colors.white,
        disabledColor: Colors.white24,
      ),
      Container(width: 25),
      FlatButton(child: Text("Cancel"), onPressed: cancel, color: Colors.white)
    ], mainAxisAlignment: MainAxisAlignment.center);
  }

  void confirm() {
    Firestore.instance
        .collection('battles')
        .document(Data.battleID)
        .collection('queue')
        .document(Data.user.uid)
        .setData({
      'skill': useSkill['skill']['name'],
      'targets': useSkill['targets']
    });

    setState(() {
      useSkill = new Map();
      finishTurn = true;
    });

    checkQueue();
  }

  void cancel() {
    setState(() {
      useSkill = new Map();
    });
  }

  void checkQueue() async {
    QuerySnapshot queueDocs = await Firestore.instance
        .collection('battles')
        .document(Data.battleID)
        .collection('queue')
        .getDocuments();

    bool finished = false;
    List<String> notDone = allies.keys.toList();
    for (DocumentSnapshot doc in queueDocs.documents) {
      if (notDone.contains(doc.documentID)) {
        notDone.remove(doc.documentID);
      }
      if (doc.documentID == Data.user.uid) {
        finished = true;
      }
    }

    for (int i = 0; i < notDone.length; i++) {
      notDone[i] = allies[notDone[i]]['name'];
    }

    if (remaining != notDone.length) {
      setState(() {
        remaining = notDone.length;
        finishTurn = finished;
        midText =
            "Waiting${notDone.length == 0 ? '...' : ' for: ' + notDone.join(", ")}";
      });
    }
  }

  Future<void> getAllUnits() async {
    QuerySnapshot allyDocs = await Firestore.instance
        .collection('battles')
        .document(Data.battleID)
        .collection('allies')
        .getDocuments();

    Map<String, dynamic> _allies = new Map();
    for (DocumentSnapshot doc in allyDocs.documents) {
      _allies[doc.documentID] = doc.data;
    }

    QuerySnapshot enemyDocs = await Firestore.instance
        .collection('battles')
        .document(Data.battleID)
        .collection('enemies')
        .getDocuments();

    Map<String, dynamic> _enemies = new Map();
    for (DocumentSnapshot doc in enemyDocs.documents) {
      _enemies[doc.documentID] = doc.data;
    }

    setState(() {
      allies = _allies;
      enemies = _enemies;
    });
  }

  Future<void> getUnits(bool ally, String id) async {
    if (ally) {
      DocumentSnapshot doc = await Firestore.instance
          .collection('battles')
          .document(Data.battleID)
          .collection('enemies')
          .document(id)
          .get();
      setState(() {
        allies[id] = doc;
      });
    } else {
      DocumentSnapshot doc = await Firestore.instance
          .collection('battles')
          .document(Data.battleID)
          .collection('allies')
          .document(id)
          .get();
      setState(() {
        enemies[id] = doc;
      });
    }
  }

  Color typeColor(String type) {
    switch (type) {
      case "air":
        {
          return Colors.white70;
        }
      case "earth":
        {
          return Colors.green;
        }
      case "fire":
        {
          return Colors.deepOrange;
        }
      case "water":
        {
          return Colors.blue;
        }
      case "bludgeon":
        {
          return Colors.black12;
        }
      case "pierce":
        {
          return Colors.amber;
        }
      case "slash":
        {
          return Colors.redAccent;
        }
      case "":
        {
          return Colors.grey;
        }
    }
  }
}

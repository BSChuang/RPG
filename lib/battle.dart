import 'package:flutter/material.dart';
import 'package:rpg/skills.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rpg/main.dart';
import 'package:rpg/sprites.dart';
import 'dart:math' as Math;

class Battle extends StatefulWidget {
  @override
  _BattleState createState() => new _BattleState();
}

class _BattleState extends State<Battle> {
  Map<String, dynamic> allies = new Map();
  Map<String, dynamic> enemies = new Map();

  Map<String, dynamic> useSkill = new Map();
  int alliesPage = 0;
  int enemiesPage = 0;

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

    if (turn != data['turn']) {
      turn = data['turn'];
      getAllUnits();
      checkQueue();
    }

    Container botContainer = Container(
      child: Column(
        children: <Widget>[
          buildMid(),
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

    return Expanded(
        child: Row(children: <Widget>[buildAllies(), buildEnemies()]));
  }

  Widget buildAllies() {
    Widget main = Column(
      children: <Widget>[buildUnit(Data.user.uid, 80)],
      mainAxisAlignment: MainAxisAlignment.center,
    );
    List<Widget> units = new List();
    List<String> ids = allies.keys.toList();
    if (ids.contains(Data.user.uid)) {
      ids.remove(Data.user.uid);
    }
    int count = (ids.length < (alliesPage + 1) * 20)
        ? ids.length - enemiesPage * 20
        : 20;

    for (int i = 0; i < 20; i++) {
      if (alliesPage * 20 + i == ids.length) {
        break;
      }
      units.add(
          buildUnit(ids[alliesPage * 20 + i], (80 - count * 2).toDouble()));
    }

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
    List<String> ids = enemies.keys.toList();
    int count = (ids.length < (enemiesPage + 1) * 20)
        ? ids.length - enemiesPage * 20
        : 20;

    for (int i = 0; i < 20; i++) {
      if (enemiesPage * 20 + i == ids.length) {
        break;
      }
      units.add(
          buildUnit(ids[enemiesPage * 20 + i], (80 - (count * 2)).toDouble()));
    }

    return Expanded(child: buildUnitGrid(units));
  }

  Widget buildUnitGrid(List<Widget> units) {
    if (units.length == 0) {
      return new Container(height: 0, width: 0);
    }
    int width = Math.sqrt(units.length).ceil();
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
        onTap: () => pressUnit(id));

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
        Container(height: 4, width: Math.max(ap, 0), color: Colors.grey),
        Container(height: 4, width: Math.min(size - ap, size), color: Colors.black54)
      ],
    );
    Widget hpBar = Row(
      children: <Widget>[
        Container(
            height: 4,
            width: Math.max(hp, 0),
            color: Colors.lightGreenAccent),
        Container(height: 4, width: Math.min(size - hp, size), color: Colors.black54)
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

  Widget buildMid() {
    return Container(
        child: Row(children: <Widget>[
          buildScrollButtons(ScrollEnum.allyLeft, ScrollEnum.allyRight),
          Container(
              child: Text(
                "Turn $turn\n" + midText,
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              width: 250),
          buildScrollButtons(ScrollEnum.enemyLeft, ScrollEnum.enemyRight),
        ], mainAxisAlignment: MainAxisAlignment.center),
        color: Colors.black26);
  }

  Widget buildScrollButtons(ScrollEnum left, ScrollEnum right) {
    bool leftEnable = ((left == ScrollEnum.allyLeft && alliesPage > 0) ||
        left == ScrollEnum.enemyLeft && enemiesPage > 0); // Enable left if there's more to scroll
    bool rightEnable = ((right == ScrollEnum.allyRight && // Enable right if there's more to scroll
            alliesPage < ((allies.length - 1) / 20).floor()) ||
        (right == ScrollEnum.enemyRight &&
            enemiesPage < ((enemies.length - 1) / 20).floor()));
    return Row(children: <Widget>[
      Container(
        child: FlatButton(
            child: Icon(
              Icons.chevron_left,
              color: leftEnable ? Colors.white : Colors.white30,
            ),
            onPressed: leftEnable ? (() => scrollPage(left)) : null),
        width: 50,
      ),
      Container(
          child: FlatButton(
              child: Icon(
                Icons.chevron_right,
                color: rightEnable ? Colors.white : Colors.white30,
              ),
              onPressed: rightEnable ? (() => scrollPage(right)): null),
          width: 50)
    ], mainAxisAlignment: MainAxisAlignment.center);
  }

  void scrollPage(ScrollEnum scrollEnum) {
    setState(() {
      switch (scrollEnum) {
        case ScrollEnum.allyLeft:
          alliesPage--;
          break;
        case ScrollEnum.allyRight:
          alliesPage++;
          break;
        case ScrollEnum.enemyLeft:
          enemiesPage--;
          break;
        case ScrollEnum.enemyRight:
          enemiesPage++;
          break;
        default:
      }
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
      checkQueue();
    });
  }

  void checkQueue() async {
    await Firestore.instance
        .collection('battles')
        .document(Data.battleID)
        .collection('queue')
        .getDocuments()
        .then((queueDocs) {
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

      setState(() {
        if (remaining != notDone.length) {
          remaining = notDone.length;
          finishTurn = finished;
        }
        midText =
            "Waiting${notDone.length == 0 ? '...' : ' for: ' + notDone.length.toString() + ' player'}${notDone.length <= 1 ? '' : 's'}";
      });
    });
  }

  void getAllUnits() {
    getAllies();
    getEnemies();
  }

  Future<void> getAllies() async {
    await Firestore.instance
        .collection('battles')
        .document(Data.battleID)
        .collection('allies')
        .getDocuments()
        .then((allyDocs) {
      Map<String, dynamic> _allies = new Map();
      for (DocumentSnapshot doc in allyDocs.documents) {
        _allies[doc.documentID] = doc.data;
      }
      setState(() {
        allies = _allies;
      });
    });
  }

  Future<void> getEnemies() async {
    await Firestore.instance
        .collection('battles')
        .document(Data.battleID)
        .collection('enemies')
        .getDocuments()
        .then((enemyDocs) {
      Map<String, dynamic> _enemies = new Map();
      for (DocumentSnapshot doc in enemyDocs.documents) {
        _enemies[doc.documentID] = doc.data;
      }

      setState(() {
        enemies = _enemies;
      });
    });
  }

  Future<void> getUnits(bool ally, String id) async {
    if (ally) {
      await Firestore.instance
          .collection('battles')
          .document(Data.battleID)
          .collection('allies')
          .document(id)
          .get()
          .then((doc) {
        setState(() {
          allies[id] = doc;
        });
      });
    } else {
      await Firestore.instance
          .collection('battles')
          .document(Data.battleID)
          .collection('enemies')
          .document(id)
          .get()
          .then((doc) {
        setState(() {
          enemies[id] = doc;
        });
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

enum ScrollEnum { allyLeft, enemyLeft, allyRight, enemyRight }

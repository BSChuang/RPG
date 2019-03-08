import 'package:flutter/material.dart';
import 'package:rpg/skills.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rpg/main.dart';
import 'package:rpg/sprites.dart';

class BattleScreen extends StatefulWidget {
  @override
  _BattleScreenState createState() => new _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>{
  Map<String, Map<String, dynamic>> units = new Map();
  List<String> alliesID = List();
  List<String> enemiesID = List();

  Map<String, String> skills = new Map();

  Map<String, Color> unitBorder = new Map();
  String combatLog = "";
  Color enemyBorder = Colors.white70;
  Color allyBorder = Colors.white70;

  String skillToUseName = "";
  int targetCount = 0;
  List<String> targets = new List();

  int buttonSectionPage = 0;
  String confirmText = "";
  bool confirmDisabled = true;
  int currTurn = 0;
  Widget buttonSection, buttonSection1, buttonSection2, allyWidget, enemyWidget, battleSection, logSection;

  Widget buildSkillTooltip(String skillName, Widget button) {
    String tooltip = "";
    for (String key in Skills.skills[skillName].keys) {
      tooltip += key + ": " + Skills.skills[skillName][key].toString() + "\n";
    }
    return Tooltip(
        message: tooltip,
        child: button
    );
  }

  void unitInfo(context, String unitID) {
    String infoLeft = "";
    for (String key in units[unitID].keys) {
      infoLeft += key.toString() + ": " + units[unitID][key].toString() + "\n";
    }
    showModalBottomSheet(
        context: context,
        builder: (BuildContext builder) {
          return Container(
              child: Wrap(
                  children: [
                    Row(
                        children: [
                          Text(
                              infoLeft,
                              style: TextStyle(fontSize: 20)
                          ),
                        ]
                    )
                  ]
              )
          );
        }
    );
  }

  Widget buildSkillButton(String skillName) {
    Map skill = Skills.skills[skillName];
    Widget button = new Container(
      decoration: new BoxDecoration(
        color: Colors.white30,
        border: new Border.all(color: typeColor(skill['type']), width: 2.0),
        borderRadius: new BorderRadius.circular(10.0)
      ),
        child: new FlatButton(
            textColor: Colors.black87,

            child: new Text(skillName),
            onPressed: () {
              skillToUseName = skillName;
              targetCount = skill['targets'];
              targets.clear();
              setConfirmCancel(1);
              if (targetCount == 1) {
                setConfirmText("Choose 1 target to use " + skillName + " on.");
              } else if (targetCount > 1) {
                setConfirmText("Choose " + targetCount.toString() + " targets to use " + skillName + " on.");
              }
            })
    );


    return buildSkillTooltip(skillName, button);
  }

  Widget buildButtonSection(String skill1, String skill2) {
    if (skills.containsKey('skill1') && skills.containsKey('skill2') && skills.containsKey('skill3') && skills.containsKey('skill4')) {
      return Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildSkillButton(skills[skill1]),
              buildSkillButton(skills[skill2]),
            ],
          )
      );
    }
    return StreamBuilder(
        stream: Firestore.instance.collection('players')
            .document(Data.user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Text('Loading...');
          skills[skill1] = snapshot.data['equipment'][skill1].toString();
          skills[skill2] = snapshot.data['equipment'][skill2].toString();
          return Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildSkillButton(snapshot.data['equipment'][skill1].toString()),
                  buildSkillButton(snapshot.data['equipment'][skill2].toString()),
                ],
              )
          );
        });
  }

  void buildBattle() {
    allyWidget = StreamBuilder(
        stream: Firestore.instance.collection('battles').document(Data.battleID).collection('allies').snapshots(),
        builder: (cont, snap) {
          if (!snap.hasData) return const Text('Loading...');

          List<Row> unitWidgets = new List();
          alliesID.clear();

          for (DocumentSnapshot unit in snap.data.documents) {
            units[unit.documentID] = unit.data;
            alliesID.add(unit.documentID);
            if (!unitBorder.containsKey(unit.documentID))
              unitBorder[unit.documentID] = Colors.white70;
            Row unitWidget = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: FlatButton(
                        onPressed: () => unitInfo(context, unit.documentID),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(unit['name'].toString()),
                            Container(child: Text('AP: ' + shortInt(unit['armor']) + "/" + shortInt(unit['maxArmor']))),
                            Container(child: Text('HP: ' + shortInt(unit['hp']) + "/" + shortInt(unit['maxHP']))),
                          ],
                        )
                    )),
                GestureDetector(
                    onTap: (){
                      if ((skillToUseName != "" && targetCount > 0) || targets.contains(unit.documentID)) {
                        selectUnit(unit.documentID);
                      }
                    },
                    child: Container(
                        margin: const EdgeInsets.all(15.0),
                        padding: const EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                            border: Border.all(width: 3, color: unitBorder[unit.documentID])
                        ),
                        child: Sprites.makeSprite(unit['anim']['idle'], 50)
                    )
                )
              ],
            );
            unitWidgets.add(unitWidget);
          }

          return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: unitWidgets
          );
        }
    );

    enemyWidget = StreamBuilder(
        stream: Firestore.instance.collection('battles').document(Data.battleID).collection('enemies').snapshots(),
        builder: (cont, snap) {
          if (!snap.hasData) return const Text('Loading...');

          List<Row> unitWidgets = new List();
          enemiesID.clear();

          for (DocumentSnapshot unit in snap.data.documents) {
            units[unit.documentID] = unit.data;
            enemiesID.add(unit.documentID);
            if (!unitBorder.containsKey(unit.documentID))
              unitBorder[unit.documentID] = Colors.white70;
            Row unitWidget = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                    onTap: (){
                      if ((skillToUseName != "" && targetCount > 0) || targets.contains(unit.documentID)) {
                        selectUnit(unit.documentID);
                      }
                    },
                    child: Container(
                        margin: const EdgeInsets.all(0.0),
                        padding: const EdgeInsets.all(0.0),
                        decoration: BoxDecoration(
                            border: Border.all(width: 3, color: unitBorder[unit.documentID])
                        ),

                        child: Icon(Icons.image)//Sprites.makeSprite(unit['anim']['idle'], 50)//
                    )
                ),
                Container(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: FlatButton(
                        onPressed: () => unitInfo(context, unit.documentID),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(child: Text(unit['name'].toString())),
                            Container(child: Text('AP: ' + shortInt(unit['armor']) + "/" + shortInt(unit['maxArmor']))),
                            Container(child: Text('HP: ' + shortInt(unit['hp']) + "/" + shortInt(unit['maxHP']))),
                          ],
                        )
                    )),
                //Icon(Icons.insert_emoticon, color: Colors.black87),
              ],
            );
            unitWidgets.add(unitWidget);
          }

          return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: unitWidgets
          );
        }
    );

    battleSection = Container(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                  child: allyWidget
              ),
              Expanded(
                  child: enemyWidget
              ),
            ]
        )
    );

    buttonSection1 = buildButtonSection('skill1', 'skill2');
    buttonSection2 = buildButtonSection('skill3', 'skill4');

    logSection = getLog();

    if (buttonSectionPage == 0) {
      buttonSection = Column(
          children: [
            buttonSection1,
            buttonSection2
          ]
      );
    } else if (buttonSectionPage == 1){
      buttonSection = Column(
          children: [
            Container(
                child: Text('$confirmText', style: TextStyle(fontSize: 16))
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RaisedButton(
                    color: Colors.deepOrange,
                    textColor: Colors.white,
                    child: new Text('Confirm'),
                    onPressed: confirmDisabled ? null : () => confirm()
                ),
                RaisedButton(
                    color: Colors.deepOrange,
                    textColor: Colors.white,
                    child: new Text('Cancel'),
                    onPressed: () => cancel()
                )
              ],
            )
          ]
      );
    } else {
      buttonSection = Text('Waiting for other players...', style: TextStyle(fontSize: 16), textAlign: TextAlign.center);
    }
  }


  @override
  Widget build(BuildContext context) {

    buildBattle();
    return MaterialApp(
        title: 'RPG',
        home: Scaffold(
          backgroundColor: Colors.white,
          body:
          ListView(
            children: [
              battleSection,
              buttonSection,
              logSection
            ],
          ),
        ));
  }

  Widget getLog() {
    return StreamBuilder(
        stream: Firestore.instance.collection('battles')
            .document(Data.battleID)
            .snapshots(),
        builder: (con, snap) {
          if (!snap.hasData) return const Text('Loading...');
          String finLog = '';
          int turn = snap.data['turn'];
          Map<dynamic, dynamic> log = snap.data['log'];
          List<dynamic> order = snap.data['order'];
          if (currTurn != turn && log.isNotEmpty) {
            currTurn = turn;
            for (int i = 0; i < order.length; i++) {
              dynamic entries = log[order[i]];
              for (dynamic entry in entries) {
                finLog += entry + '\n';
              }
            }
          }
          return Text(finLog, style: TextStyle(fontSize: 14));
        });
  }

  String shortInt(dynamic num) {
    double dub = num.toDouble();
    String str = '';
    if (dub.abs() > 1000000) {
      dub /= 100000;
      str = (dub.round()/10).toString() + 'M';
    } else if (dub.abs() > 1000) {
      dub /= 100;
      str = (dub.round()/10).toString() + 'K';
    } else {
      str = dub.round().toString();
    }
    return str;
  }

  void setConfirmCancel(int page) {
    setState(() {
      buttonSectionPage = page;
    });
  }

  void setConfirmText(String text) {
    setState(() {
      confirmDisabled = true;
      confirmText = text;
    });
  }

  void confirm() {
    Firestore.instance.collection('battles').document(Data.battleID).collection('queue').document(Data.user.uid).setData({
      'skill': skillToUseName,
      'targets': targets
    });

    skillToUseName = "";
    setConfirmCancel(0);
    deSelectAll();
  }

  void cancel() {
    skillToUseName = "";
    targets.clear();
    setConfirmCancel(0);
    deSelectAll();
  }

  void selectUnit(String unitID) {
    Color color;

    if (!targets.contains(unitID)) {
      targets.add(unitID);
      targetCount--;
      if (alliesID.contains(unitID)) {
        color = Colors.green;
      } else {
        color = Colors.redAccent;
      }
    } else {
      targets.remove(unitID);
      targetCount++;
      color = Colors.white70;
    }

    setState(() {
      confirmDisabled = (targetCount != 0);
      unitBorder[unitID] = color;
    });
  }

  void deSelectAll() {
    setState(() {
      unitBorder.forEach((key, val) => (unitBorder[key] = Colors.white70));
    });
  }

  Color typeColor(String type) {
    switch (type) {
      case "air": {return Colors.white70;}
      case "earth": {return Colors.green;}
      case "fire": {return Colors.deepOrange;}
      case "water": {return Colors.blue;}
      case "bludgeon": {return Colors.black12;}
      case "pierce": {return Colors.amber;}
      case "slash": {return Colors.redAccent;}
      case "": {return Colors.grey;}
    }
  }
}
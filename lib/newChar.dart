import 'package:flutter/material.dart';
import 'package:rpg/skills.dart';
import 'package:rpg/character.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rpg/battle.dart';
import 'package:rpg/main.dart';

class NewChar extends StatefulWidget {
  @override
  _NewCharState createState() => new _NewCharState();
}

class _NewCharState extends State<NewChar> {
  Map<String, int> stats = new Map();
  int pointsAvailable = 0;
  final myController = TextEditingController();
  String _radioValue = "knight";
  String classDescription = "Higher armor, good for 1v1.";

  @override
  Widget build(BuildContext context) {
    initStats();

    return MaterialApp(
      title: 'RPG',
      home: Scaffold(
          appBar: AppBar(
            title: Text('New Character'),
          ),
          body: new Column(
            children: <Widget>[
              Text(classDescription),
              classChooser(),
              Text('Points Available: ' + pointsAvailable.toString()),
              statRow('Charisma'),
              statRow('Constitution'),
              statRow('Dexterity'),
              statRow('Intelligence'),
              statRow('Strength'),
              statRow('Wisdom'),
              nameField(),
              MaterialButton(
                child: Text('Finish'),
                color: Colors.blueAccent,
                onPressed: () => submit(),
              )
            ],
          )
      ),
    );
  }

  void submit() {
    Firestore.instance.collection('players').document(Data.user.uid).setData({
      'new': {
        'name': myController.text,
        'class': _radioValue,
        'stats': stats
      }
    });

    Navigator.of(context).pushNamed('/mainMenu');
  }

  void _handleRadioValueChange(String value) {
    setState(() {
      _radioValue = value;

      switch(value) {
        case "knight":
          classDescription = "Higher armor, good for 1v1.";
          break;
        case "wizard":
          classDescription = "More fragile, but high damage and good versus multiple enemies.";
          break;
        case "rogue":
          classDescription = "High crit chance, good utility skills.";
          break;
      }
    });
    print(value);
  }

  Widget classChooser() {
    return Row(
      children: <Widget>[
        Radio(
          value: "knight",
          groupValue: _radioValue,
          onChanged: _handleRadioValueChange,
        ),
        Text('Knight'),
        Radio(
          value: "wizard",
          groupValue: _radioValue,
          onChanged: _handleRadioValueChange,
        ),
        Text('Wizard'),
        Radio(
          value: "rogue",
          groupValue: _radioValue,
          onChanged: _handleRadioValueChange,
        ),
        Text('Rogue'),
      ],
    );
  }

  Widget nameField() {
    return Row(
      children: <Widget>[
        Text('Username: '),
        Expanded(
          child: TextField(
              controller: myController,
              decoration: InputDecoration(
                  hintText: 'Enter name'
              )
          ),
        )
      ],
    );
  }

  Widget statRow(String stat) {
    return Container(
      child: new Row(
        children: <Widget>[
          Container(
            child: MaterialButton(
              height: 40.0,
              minWidth: 40.0,
              child: new Icon(Icons.arrow_back_ios),
              onPressed: () => changeStat(stat.toLowerCase(), false),
            ),
          ),
          Container(
            child: Text(stats[stat.toLowerCase()].toString()),
          ),
          Container(
            child: MaterialButton(
              height: 40.0,
              minWidth: 40.0,
              child: new Icon(Icons.arrow_forward_ios),
              onPressed: () => changeStat(stat.toLowerCase(), true),
            ),
          ),
          Container(
            child: Text(stat),
          ),
        ],
      ),
    );
  }

  void changeStat(String stat, bool increment) {
    if (stats[stat] == 1 && !increment) {
      return;
    }

    setState(() {
      if (increment) {
        if (pointsAvailable > 0) {
          stats[stat]++;
          pointsAvailable--;
        } else {
          print('Not enough points!');
        }
      } else {
        stats[stat]--;
        pointsAvailable++;
      }
    });
  }

  void initStats() {
    List<String> statKeys = ['charisma', 'constitution', 'dexterity', 'intelligence', 'strength', 'wisdom'];
    for (String stat in statKeys) {
      if (!stats.containsKey(stat)) {
        stats[stat] = 10;
      }
    }
  }

}
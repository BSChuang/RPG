import 'package:flutter/material.dart';
import 'package:rpg/skills.dart';
import 'package:rpg/character.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rpg/battle.dart';

Map<String, int> stats = new Map();
int pointsAvailable = 0;

class NewChar extends StatefulWidget {
  @override
  _NewCharState createState() => new _NewCharState();
}

class _NewCharState extends State<NewChar> {
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
              Text(pointsAvailable.toString()),
              statRow('Charisma'),
              statRow('Constitution'),
              statRow('Dexterity'),
              statRow('Intelligence'),
              statRow('Strength'),
              statRow('Wisdom'),
            ],
          )
      ),
    );
  }

  Widget statRow(String stat) {
    return Container(
      child: new Row(
        children: <Widget>[
          Container(
            child: RaisedButton(
              child: new Icon(Icons.arrow_back_ios),
              onPressed: () => changeStat(stat.toLowerCase(), false),
            ),
          ),
          Container(
            child: Text(stats[stat.toLowerCase()].toString()),
          ),
          Container(
            child: RaisedButton(
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
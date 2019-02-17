import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rpg/main.dart';

class ChooseBattle extends StatefulWidget {
  @override
  _ChooseBattleState createState() => new _ChooseBattleState();
}

class _ChooseBattleState extends State<ChooseBattle> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        RaisedButton(
          child: Text('Random Battle'),
          onPressed: random,
        )
      ],
    );
  }

  void random() {
    Firestore.instance.collection('players').document(Data.user.uid).updateData({
      'battle': {'level': 1, 'type': 'random'}
    });
  }
}
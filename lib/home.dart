import 'package:flutter/material.dart';
import 'package:rpg/skills.dart';
import 'package:rpg/character.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:rpg/main.dart';
import 'package:rpg/battle.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => new _HomeState();
}

class _HomeState extends State<Home> {
  List<dynamic> friends = new List();
  Map<String, List<String>> friendsData = new Map();


  @override
  Widget build(BuildContext context) {

    Widget partyWidget = buildParty();
    // TODO: implement build

    List<Widget> colList = new List();
    if (partyWidget != null) {
      colList.add(partyWidget);
    }

    colList.add(RaisedButton(
      child: Text('Invite to Party'),
      onPressed: openFriends,
    ));
    colList.add(RaisedButton(
      child: Text('Battle'),
      onPressed: toBattle,
    ));

    return Column(
      children: colList
    );
  }

  Widget buildParty() {
    //DocumentSnapshot doc = await Firestore.instance.collection('players').document(Data.user.uid).get();

    return StreamBuilder(
        stream: Firestore.instance.collection('players')
            .document(Data.user.uid)
            .snapshots(),
        builder: (con, snap) {
          if (!snap.hasData) return const Text('Loading...');

          friends = snap.data['friends'];
          List<Widget> members = new List();
          List<dynamic> partyIDs = snap.data['party'];

          for (dynamic partyID in partyIDs) {
            if (!friendsData.containsKey(partyID)) {
              getFriendInfo(partyID);
            }

            String name = "";
            if (friendsData.containsKey(partyID)) {
              name = friendsData[partyID][0];
            }

            members.add(GridTile(
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
                              Container(
                                height: 25,
                                  child: Text(name, textAlign: TextAlign.center)
                              ),
                            ],
                          )
                      )
                  )
              ),
            ));
          }
          return Container(
            height: 110.0,
              child: GridView.count(
                  crossAxisCount: 4,
                  padding: EdgeInsets.all(5.0),
                  mainAxisSpacing: 4.0,
                  crossAxisSpacing: 4.0,
                  children: members
              )
          );
        });
  }

  // Gets friend's name and level
  Future<void> getFriendInfo(String uid) async {
    DocumentSnapshot doc = await Firestore.instance.collection('players').document(uid).get();
    List<String> pData = new List();
    pData.add(doc.data['name'].toString());

    setState(() {
      friendsData[uid] = pData;
    });
  }

  Future<void> openFriends() async {
    List<Widget> friendWidgets = new List();
    for (dynamic friend in friends) {
      friendWidgets.add(new Row(
        children: <Widget>[
          Text(friendsData[friend.toString()][0] + '          '),
          RaisedButton(
            color: Colors.blue,
            child: Text('Invite'),
            onPressed: inviteToParty,
          )
        ],
      ));
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Friends'),
          content: SingleChildScrollView(
              child: Column(
                children: friendWidgets,
              )
          )
        );
      },
    );
  }

  void inviteToParty() {


    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text("Sending invite"),
    ));
  }

  Future toBattle() async {
    DocumentSnapshot playerData = await Firestore.instance.collection('players').document(Data.user.uid).get();
    if (playerData.data['currentBattle'] != null) {
      Data.battleID = playerData.data['currentBattle'];
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BattleScreen())
      );
    } else {

    }
  }
}
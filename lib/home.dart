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
  Map<String, List<String>> playerData = new Map();
  bool ready = false;
  @override
  Widget build(BuildContext context) {
    return buildParty();
  }

  Widget buildParty() {
    return StreamBuilder(
        stream: Firestore.instance.collection('players')
            .document(Data.user.uid)
            .snapshots(),
        builder: (con, snap) {
          if (!snap.hasData) return const Text('Loading...');

          List<dynamic> friends = snap.data['friends'];
          List<Widget> members = new List();
          Map<dynamic, dynamic> party = snap.data['party'];

          if (!playerData.containsKey(Data.user.uid)) {
            getPlayerInfo(Data.user.uid);
          }

          for (dynamic member in party.keys) {
            if (!playerData.containsKey(member.toString())) {
              getPlayerInfo(member.toString());
            }
          }

          for (dynamic friend in friends) {
            if (!playerData.containsKey(friend.toString())) {
              getPlayerInfo(friend.toString());
            }
          }

          for (dynamic partyID in party.keys) {
            String name = "";
            if (playerData.containsKey(partyID)) {
              name = playerData[partyID][0];
            }

            Icon icon = (party[partyID] == true ? Icon(Icons.arrow_upward) : Icon(Icons.android));

            members.add(GridTile(
              child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.black87,
                          width: 1
                      )
                  ),
                  child:Center(
                      child: Container(
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: icon,
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

          Widget partyWidget = Container(
              height: 110.0,
              child: GridView.count(
                  crossAxisCount: 4,
                  padding: EdgeInsets.all(5.0),
                  mainAxisSpacing: 4.0,
                  crossAxisSpacing: 4.0,
                  children: members
              )
          );

          List<Widget> colList = new List();

          if (partyWidget != null) {
            colList.add(partyWidget);
          }

          colList.add(RaisedButton(
            child: Text('Invite to Party'),
            onPressed: openFriends,
          ));
          colList.add(RaisedButton(
            child: Text('Party Invites'),
            onPressed: partyInvites,
          ));
          colList.add(RaisedButton(
            child: Text('Leave Party'),
            onPressed: leaveParty,
          ));

          colList.add(RaisedButton(
            child: Text(!ready ? "Ready" : "Cancel"),
            onPressed: readyUp,
          ));

          return Column(
              children: colList
          );
        });


  }

  // Gets friend's name and level
  Future<void> getPlayerInfo(String uid) async {
    DocumentSnapshot doc = await Firestore.instance.collection('players').document(uid).get();
    List<String> pData = new List();
    pData.add(doc.data['name'].toString());

    setState(() {
      playerData[uid] = pData;
    });
  }

  Future<void> openFriends() async {
    List<Widget> friendWidgets = new List();
    for (dynamic friend in playerData.keys) {
      if (friend == Data.user.uid) {
        continue;
      }

      friendWidgets.add(new Row(
        children: <Widget>[
          Text(playerData[friend.toString()][0] + '          '),
          RaisedButton(
            color: Colors.blue,
            child: Text('Invite'),
            onPressed: () {
              inviteToParty(friend.toString());
            },
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

  Future<void> partyInvites() async {
    DocumentSnapshot doc = await Firestore.instance.collection('players').document(Data.user.uid).get();
    Map<dynamic, dynamic> invites = doc.data['invites'];
    List<Widget> widgets = new List();

    for (dynamic invite in invites.keys) {

      widgets.add(new Row(
        children: <Widget>[
          Text(playerData[invite.toString()][0] + '          '),
          RaisedButton(
            color: Colors.blue,
            child: Text('Accept'),
            onPressed: () {
              acceptInvite(invite.toString());
            }
          )
        ],
      ));
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('Invites'),
            content: SingleChildScrollView(
                child: Column(
                  children: widgets,
                )
            )
        );
      },
    );
  }

  void readyUp() {
    Firestore.instance.collection('players').document(Data.user.uid).updateData({
      'ready': !ready
    });

    setState(() {
      ready = !ready;
    });
  }

  void leaveParty() {
    Firestore.instance.collection('players').document(Data.user.uid).updateData({
      'acceptInvite': 'leave'
    });

    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text("Leaving party..."),
    ));
  }

  void acceptInvite(String uid) {
    Firestore.instance.collection('players').document(Data.user.uid).updateData({
      'acceptInvite': uid
    });

    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text("Joining party..."),
    ));
  }

  void inviteToParty(String uid) {
    Firestore.instance.collection('players').document(Data.user.uid).updateData({
      'sendInvite': uid
    });

    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text("Sending invite..."),
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
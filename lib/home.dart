import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rpg/main.dart';
import 'package:rpg/battle.dart';
import 'package:rpg/sprites.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => new _HomeState();
}

class _HomeState extends State<Home> {
  Map<String, Map<dynamic, dynamic>> playerData = new Map();
  bool ready = false;
  @override
  Widget build(BuildContext context) {
    return buildParty();
  }

  Widget buildParty() {
    return StreamBuilder(
        stream: Firestore.instance
            .collection('players')
            .document(Data.user.uid)
            .snapshots(),
        builder: (con, snap) {
          if (!snap.hasData) return const Text('Loading...');

          List<dynamic> friends = snap.data['friends'];

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

          List<Widget> partyRowWidgets = new List();
          Row partyRow = new Row();
          List<Widget> partyColumn = new List();
          int partyLength = 0;
          for (dynamic partyID in party.keys) {
            partyLength++;
            if (playerData.containsKey(partyID)) {
              Text nameText = Text(playerData[partyID]['name']);

              if (party[partyID]) {
                nameText = Text(playerData[partyID]['name'],
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold));
              }
              Widget character =
                  Sprites.makeSprite(playerData[partyID]['anim']['idle'], 50);

              Widget playerWidget = Container(
                  margin: EdgeInsets.all(10),
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: <Widget>[character, nameText],
                  ));

              partyRowWidgets.add(playerWidget);
              if (partyRowWidgets.length == 4 || partyLength == party.length) {
                partyRow = new Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: partyRowWidgets);
                partyColumn.add(partyRow);
              }
            }
          }

          Widget partyWidget = Column(
            children: partyColumn,
          );

          List<Widget> colList = new List();

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
            onPressed: toBattle,
          ));

          if (partyWidget != null) {
            colList.add(partyWidget);
          }

          return Column(children: colList);
        });
  }

  // Gets friend's name and level
  Future<void> getPlayerInfo(String uid) async {
    DocumentSnapshot doc =
        await Firestore.instance.collection('players').document(uid).get();

    setState(() {
      playerData[uid] = doc.data;
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
          Text(playerData[friend.toString()]['name'] + '          '),
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
            )));
      },
    );
  }

  Future<void> partyInvites() async {
    DocumentSnapshot doc = await Firestore.instance
        .collection('players')
        .document(Data.user.uid)
        .get();
    Map<dynamic, dynamic> invites = doc.data['invites'];
    List<Widget> widgets = new List();

    for (dynamic invite in invites.keys) {
      widgets.add(new Row(
        children: <Widget>[
          Text(playerData[invite.toString()]['name'] + '          '),
          RaisedButton(
              color: Colors.blue,
              child: Text('Accept'),
              onPressed: () {
                acceptInvite(invite.toString());
              })
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
            )));
      },
    );
  }

  void readyUp() {
    Firestore.instance
        .collection('players')
        .document(Data.user.uid)
        .updateData({'ready': !ready});

    setState(() {
      ready = !ready;
    });
  }

  void leaveParty() {
    Firestore.instance
        .collection('players')
        .document(Data.user.uid)
        .updateData({'acceptInvite': 'leave'});

    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text("Leaving party..."),
    ));
  }

  void acceptInvite(String uid) {
    Firestore.instance
        .collection('players')
        .document(Data.user.uid)
        .updateData({'acceptInvite': uid});

    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text("Joining party..."),
    ));
  }

  void inviteToParty(String uid) {
    Firestore.instance
        .collection('players')
        .document(Data.user.uid)
        .updateData({'sendInvite': uid});

    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text("Sending invite..."),
    ));
  }

  Future toBattle() async {
    DocumentSnapshot data = await Firestore.instance
        .collection('players')
        .document(Data.user.uid)
        .get();
    if (data.data['currentBattle'] != null) {
      Data.battleID = data.data['currentBattle'];
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => BattleScreen()));
    } else {}
  }
}

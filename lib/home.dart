import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rpg/main.dart';
import 'package:rpg/battle.dart';
import 'package:rpg/sprites.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => new _HomeState();
}

class _HomeState extends State<Home> {
  Map<String, Map<dynamic, dynamic>> playerData = new Map();
  Map<dynamic, dynamic> party;
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

          party = snap.data['party'];

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

          List<Widget> colList = partyButtons();

          Widget partyWidget = buildCharacters();

          if (partyWidget != null) {
            colList.add(partyWidget);
          }

          return Center(
              child: Column(
                  children: colList,
                  crossAxisAlignment: CrossAxisAlignment.center));
        });
  }

  List<Widget> partyButtons() {
    print("here");
    List<Widget> colList = new List<Widget>();

    Widget invite = MaterialButton(
      child: Text('Friends'),
      onPressed: openFriends,
      color: Colors.white10,
      height: 40,
      minWidth: 100,
    );
    Widget invites = MaterialButton(
      child: Text('Party Invites'),
      onPressed: partyInvites,
      color: Colors.white10,
      height: 40,
      minWidth: 100,
    );
    Widget leave = MaterialButton(
      child: Text('Leave Party'),
      onPressed: leaveParty,
      color: Colors.white10,
      height: 40,
      minWidth: 100,
    );

    colList.add(new Container(height: 25));

    colList.add(Row(children: <Widget>[invite, invites, leave], mainAxisAlignment: MainAxisAlignment.spaceEvenly));

    colList.add(MaterialButton(
      child: Text(!ready ? "Ready" : "Cancel"),
      onPressed: toBattle,
      color: Colors.white10,
      height: 40,
      minWidth: 60,
    ));

    return colList;
  }

  Widget buildCharacters() {
    List<Widget> partyRowList = new List();
    List<Widget> partyColumnList = new List();
    Row partyRow = new Row();
    int partyLength = 0;

    if (playerData.containsKey(Data.user.uid)) {
      // build player character first
      Widget character =
          Sprites.makeSprite(playerData[Data.user.uid]['anim']['idle'], 100);
      partyColumnList.add(character);
    }

    for (dynamic partyID in party.keys) {
      // build everyone else
      if (partyID == Data.user.uid) {
        continue;
      }

      partyLength++;
      if (playerData.containsKey(partyID)) {
        Widget character = Sprites.makeSprite(
            playerData[partyID]['anim']['idle'], 75.0 - 2 * party.length);

        partyRowList.add(character);
        if (partyRowList.length == 4 || partyLength == party.length) {
          partyRow = new Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: partyRowList);
          partyColumnList.add(partyRow);
        }
      }
    }

    return Container(
        child: Column(
            children: partyColumnList,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center));
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
    } else {
      //Navigator.push(
      //context, MaterialPageRoute(builder: (context) => BattleScreen()));
    }
  }
}

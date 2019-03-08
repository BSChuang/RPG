import 'package:flutter/material.dart';
import 'package:rpg/skills.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rpg/mainmenu.dart';
import 'package:rpg/battle.dart';
import 'package:rpg/newChar.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn();
final FirebaseAuth _auth = FirebaseAuth.instance;


void main() {
  //debugPaintSizeEnabled = true;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      home: new LoadingScreen(),
      routes: <String, WidgetBuilder> {
        '/mainMenu': (BuildContext context) => new MainMenu(),
        '/newChar': (BuildContext context) => new NewChar(),
        '/battle': (BuildContext context) => new BattleScreen(),
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Skills();

    return MaterialApp(
        title: 'RPG',
        home: Scaffold(
          appBar: AppBar(
            title: Text('Loading'),
          ),
          body: RaisedButton(
              color: Colors.black45,
              textColor: Colors.white70,
              child: new Text('Login'),
              onPressed: () => _handleSignIn(context)
            )
          ),
        );
  }

  Future<FirebaseUser> _handleSignIn(BuildContext context) async {
    GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    AuthCredential _credential = GoogleAuthProvider.getCredential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken
    );
    Data.user = await _auth.signInWithCredential(_credential);

    DocumentSnapshot docSnap = await Firestore.instance.collection('players').document(Data.user.uid).get();
    if (docSnap.exists) {
      Navigator.of(context).pushNamed('/mainMenu');
    } else {
      Navigator.of(context).pushNamed('/newChar');
    }

    return Data.user;
  }
}

class Data {
  static FirebaseUser user;
  static String battleID;
}

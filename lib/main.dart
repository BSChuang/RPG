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
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Heroes of Aur',
      theme: ThemeData(
          fontFamily: 'DisposableDroid BB',
          textTheme: TextTheme(
              headline: TextStyle(fontSize: 30),
              title: TextStyle(fontSize: 20),
              body1: TextStyle(fontSize: 20),
              button: TextStyle(fontSize: 20))),
      home: new LoadingScreen(),
      routes: <String, WidgetBuilder>{
        '/mainMenu': (BuildContext context) => new MainMenu(),
        '/newChar': (BuildContext context) => new NewChar(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Skills();

    return Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/images/backgrounds/airadventurelevel2.png"),
                fit: BoxFit.cover)),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
                child: RaisedButton(
                    color: Colors.black45,
                    textColor: Colors.white70,
                    child: new Text('Login'),
                    onPressed: () => _handleSignIn(context)))));
  }

  Future<FirebaseUser> _handleSignIn(BuildContext context) async {
    GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    AuthCredential _credential = GoogleAuthProvider.getCredential(
        idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);
    Data.user = await _auth.signInWithCredential(_credential);

    DocumentSnapshot docSnap = await Firestore.instance
        .collection('players')
        .document(Data.user.uid)
        .get();
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

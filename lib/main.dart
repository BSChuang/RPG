// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:rpg/skills.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rpg/mainmenu.dart';
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
        // MAKE TEST SCREEN
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  static FirebaseUser user;
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
    user = await _auth.signInWithCredential(_credential);

    DocumentSnapshot docSnap = await Firestore.instance.collection('players').document(user.uid).get();
    if (docSnap.exists) {
      Navigator.of(context).pushNamed('/mainMenu');
    } else {
      Navigator.of(context).pushNamed('/newChar');
    }

    return user;
  }
}

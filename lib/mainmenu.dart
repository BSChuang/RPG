import 'package:flutter/material.dart';
import 'package:rpg/skills.dart';
import 'package:rpg/character.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rpg/battle.dart';



class MainMenu extends StatefulWidget {
  @override
  _MainMenuState createState() => new _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {


  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
        title: 'RPG',
        home: Scaffold(
            appBar: AppBar(
              title: Text('Main Menu'),
            ),
            body: Row(
              children: [
                RaisedButton(
                    color: Colors.black45,
                    textColor: Colors.white70,
                    child: new Text('Sign in'),
                    onPressed: () => signIn()
                ),
              ]
            )
        )
    );
  }

  void signIn() {
    print('signed in ');
  }


}
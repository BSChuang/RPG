import 'package:flutter/material.dart';
import 'package:rpg/skills.dart';
import 'package:rpg/character.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rpg/battle.dart';
import 'package:rpg/home.dart';
import 'package:rpg/chooseBattle.dart';
import 'package:rpg/inventory.dart';

class MainMenu extends StatefulWidget {
  @override
  _MainMenuState createState() => new _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int _currentIndex = 0;
  final List<Widget> _children =[Home(), ChooseBattle(), Inventory(), Inventory(), Home()];

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: 'RPG',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Main Menu'),
        ),
        body: _children[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          onTap: onTabTapped,
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          items: [
            new BottomNavigationBarItem(
                icon: new Icon(Icons.build),
                title: new Text('Home')
            ),
            new BottomNavigationBarItem(
                icon: new Icon(Icons.map),
                title: new Text('Map')
            ),
            new BottomNavigationBarItem(
                icon: new Icon(Icons.storage),
                title: new Text('Inventory')
            ),
            new BottomNavigationBarItem(
                icon: new Icon(Icons.home),
                title: new Text('Store')
            ),
            new BottomNavigationBarItem(
                icon: new Icon(Icons.person),
                title: new Text('Profile')
            )
          ],
        ),
      )
    );

  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
import 'package:flutter/material.dart';
import 'package:rpg/home.dart';
import 'package:rpg/chooseBattle.dart';
import 'package:rpg/inventory.dart';

class MainMenu extends StatefulWidget {
  @override
  _MainMenuState createState() => new _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int _currentIndex = 0;
  final List<Widget> _children = [
    Home(),
    ChooseBattle(),
    Inventory(),
    Inventory(),
    Home()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          new BottomNavigationBarItem(
              icon: new Icon(Icons.build), title: new Text('Home')),
          new BottomNavigationBarItem(
              icon: new Icon(Icons.map), title: new Text('Map')),
          new BottomNavigationBarItem(
              icon: new Icon(Icons.storage), title: new Text('Inventory')),
          new BottomNavigationBarItem(
              icon: new Icon(Icons.home), title: new Text('Store')),
          new BottomNavigationBarItem(
              icon: new Icon(Icons.person), title: new Text('Profile'))
        ],
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}

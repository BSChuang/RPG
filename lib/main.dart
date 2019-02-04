// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:rpg/skills.dart';
import 'package:rpg/character.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rpg/battle.dart';

void main() {
  //debugPaintSizeEnabled = true;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      home: new MainScreen(),
      routes: <String, WidgetBuilder> {
        '/mainmenu': (BuildContext context) => new BattleScreen()
        // MAKE TEST SCREEN
      },
    );
  }
}

class MainScreen extends StatelessWidget {
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
              child: new Text('Enter'),
              onPressed: () => Navigator.of(context).pushNamed('/mainmenu')
            )
          )
        );
  }
}

import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => new _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return RaisedButton(
      child: Text('Battle'),
      onPressed: toBattle,
    );
  }

  void toBattle() {
    Navigator.of(context).pushNamed('/battle');
  }
}
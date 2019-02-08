import 'package:flutter/material.dart';

class Inventory extends StatefulWidget {
  @override
  _InventoryState createState() => new _InventoryState();
}

class _InventoryState extends State<Inventory> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return RaisedButton(
      child: Text('Inventory'),
    );
  }
}
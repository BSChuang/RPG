import 'package:flutter/material.dart';
import 'package:rpg/skills.dart';
import 'package:rpg/character.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class Skills {
  static Map<String, Map> skills = new Map();

  Skills() {
    initSkills();
  }

  Future initSkills() async {
    skills.clear();
    QuerySnapshot result = await Firestore.instance.collection('skills').getDocuments();
    for (DocumentSnapshot doc in result.documents) {
      skills[doc.documentID] = doc.data;
    }
  }
}
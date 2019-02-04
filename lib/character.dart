import 'package:rpg/skills.dart';

class Character {
  String id;
  String name;
  double hp;
  double armor;
  Map<String, int> skills;
  double standing;

  Character(String id, String name, double hp, double armor, double standing, Map<String, int> skills) {
    this.id = id;
    this.name = name;
    this.hp = hp;
    this.armor = armor;
    this.skills = skills;
  }
}

enum Armor {
  light, medium, heavy
}

enum Schools {
  abjuration, conjuration, divination, enchantment, evocation, illusion, necromancy, transmutation, universal
}

enum WeaponProperties {
  ammunition, finesse, heavy, light, loading, range, reach, special, thrown, twoHanded, versatile, improvised, silvered
}

enum Races {
  human, elf, dwarf, ogre, orc, goblin, kobold
}
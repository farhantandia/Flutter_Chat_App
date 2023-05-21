import 'dart:convert';

import 'package:flutter_chat_app/model/person.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static Future<Person> getPerson() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    Person? person;
    try {
      String? personString = pref.getString('person');
      if (personString != null) {
        print(personString);
        Map<String, dynamic> personJson = json.decode(personString);
        person = Person.fromMap(personJson);
      }
    } catch (e) {
      print(e);
    }

    return person!;
  }

  static void setPerson(Person person) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setString('person', person.toJson());
  }
}

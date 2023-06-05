
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_app/model/person.dart';

class EventContact {
  static void addContact({String? myUid, Person? person}) async{
    try {
     await FirebaseFirestore.instance
          .collection('person')
          .doc(myUid)
          .collection('contact')
          .doc(person?.uid)
          .set(person!.toMap())
          .then((value) => print)
          .catchError((onError) => print(onError));
    } catch (e) {
      print(e);
    }
  }

  static Future<void> deleteContact({String? myUid, String? personUid}) async{
    try {
    await  FirebaseFirestore.instance
          .collection('person')
          .doc(myUid)
          .collection('contact')
          .doc(personUid)
          .delete()
          .then((value) => null)
          .catchError((onError) => print(onError));
    } catch (e) {
      print(e);
    }
  }

  static Future<bool> checkIsMyContact({String myUid ='', String personUid=''}) async {
    bool isMyContact = false;
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('person')
          .doc(myUid)
          .collection('contact')
          .where('uid', isEqualTo: personUid)
          .get()
          .catchError((onError) => print(onError));
      if (querySnapshot.docs.length > 0) {
        isMyContact = true;
      }
    } catch (e) {
      print(e);
    }
    return isMyContact;
  }
}

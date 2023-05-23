import 'package:cloud_firestore/cloud_firestore.dart';

class EventChatRoom {
  
  static deleteChatRoom({
    String myUid='',
    String personUid='',
  }) {
    try {
      FirebaseFirestore.instance
          .collection('person')
          .doc(myUid)
          .collection('room')
          .doc(personUid)
          .delete()
          .then((value) => null)
          .catchError((onError) => print(onError));
      FirebaseFirestore.instance
          .collection('person')
          .doc(myUid)
          .collection('room')
          .doc(personUid)
          .collection('chat')
          .get()
          .then((querySnapshot) {
        for (var docChat in querySnapshot.docs) {
          docChat.reference.delete();
        }
      }).catchError((onError) => print(onError));
    } catch (e) {
      print(e);
    }
  }
}
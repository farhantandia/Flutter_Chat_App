import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';

class EventStorage {
  static Future<void> editPhoto({String oldUrl = "", File? filePhoto, String uid = ""}) async {
    if (oldUrl != "") {
      await deleteOldFile(oldUrl);
    }
    try {
      String fileName = basename(filePhoto!.path);
      TaskSnapshot taskSnapshot = await FirebaseStorage.instance.ref().child('$uid/$fileName').putFile(filePhoto);
      String newUrl = await taskSnapshot.ref.getDownloadURL();
      FirebaseFirestore.instance
          .collection('person')
          .doc(uid)
          .update({'photo': newUrl})
          .then((value) => null)
          .catchError((onError) => print(onError));
    } catch (e) {
      print(e);
    }
  }

  static Future<void> deleteOldFile(String oldUrl) async {
    try {
      String urlFile = FirebaseStorage.instance.refFromURL(oldUrl).fullPath;
      await FirebaseStorage.instance.ref(urlFile).delete();
    } catch (e) {}
  }

  static Future<String> uploadMessageImageAndGetUrl({String myUid = "", File? filePhoto, String personUid = ""}) async {
    try {
      String fileName = basename(filePhoto!.path);
      TaskSnapshot taskSnapshot = await FirebaseStorage.instance.ref().child('$myUid/$personUid/$fileName').putFile(filePhoto);
      String newUrl = await taskSnapshot.ref.getDownloadURL();
      return newUrl;
    } catch (e) {
      print(e);
      return '';
    }
  }
}

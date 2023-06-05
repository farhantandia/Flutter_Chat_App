// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_app/event/event_person.dart';

import 'package:flutter_chat_app/model/person.dart';
import 'package:flutter_chat_app/page/login.dart';
import 'package:flutter_chat_app/utils/prefs.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class EditProfile extends StatefulWidget {
  final Person? person;
  const EditProfile({
    Key? key,
    required this.person,
  }) : super(key: key);

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  // var _controllerOldEmail = TextEditingController();
  var _controllerPassword = TextEditingController();
  var _controllerName = TextEditingController();
  var _controllerNewEmail = TextEditingController();
  var _formKey = GlobalKey<FormState>();
  var _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<bool> changeEmail() async {
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: widget.person!.email, password: _controllerPassword.text);
    if (userCredential != null) {
      await userCredential.user!.updateEmail(_controllerNewEmail.text);
      await userCredential.user!.sendEmailVerification();
      return true;
    } else {
      return false;
    }
  }

  void updateToFirestore() {
    Map<String, dynamic> newData = {
      'email': _controllerNewEmail.text,
      'name': _controllerName.text,
    };

    // update in person
    FirebaseFirestore.instance
        .collection('person')
        .doc(widget.person!.uid)
        .update(newData)
        .then((value) => null)
        .catchError((onError) => print(onError));
    // update in contact
    FirebaseFirestore.instance.collection('person').get().then((value) {
      for (var docPerson in value.docs) {
        docPerson.reference.collection('contact').where('uid', isEqualTo: widget.person!.uid).get().then((snapshotContact) {
          for (var docContact in snapshotContact.docs) {
            docContact.reference.update(newData);
          }
        });
      }
    }).catchError((onError) => print(onError));
    // update in room
    FirebaseFirestore.instance.collection('person').get().then((value) {
      for (var docPerson in value.docs) {
        docPerson.reference.collection('room').where('uid', isEqualTo: widget.person!.uid).get().then((snapshotContact) {
          for (var docRoom in snapshotContact.docs) {
            docRoom.reference.update(newData);
          }
        });
      }
    }).catchError((onError) => print(onError));
  }

  void showNotifSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void deleteProfile() async {
    EasyLoading.show(status: "Loading...");
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(email: widget.person!.email, password: _controllerPassword.text);
      if (userCredential != null) {
        await userCredential.user!.delete().then((value) async => {await EventPerson.deleteAccount(widget.person!.uid)});

        EasyLoading.dismiss();
        Prefs.clear();
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Login()));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showNotifSnackBar('User not found');
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        showNotifSnackBar('Wrong password');
        print('Wrong password provided for that user.');
      } else if (e.code == 'network-request-failed') {
        showNotifSnackBar('Network is unavailable');
      }

      EasyLoading.showError("Delete account failed");
    }
  }

  void updateProfile() {
    if (_controllerNewEmail.text != widget.person!.email) {
      changeEmail().then((success) {
        if (success) {
          updateToFirestore();
          EasyLoading.showSuccess('Success Change Email & Update Profile');
        } else {
          EasyLoading.showError('Failed Change Email & Update Profile');
        }
      });
    } else {
      updateToFirestore();
      EasyLoading.showSuccess('Succes Update Name');
    }
    EventPerson.getPerson(widget.person!.uid).then((person) {
      Prefs.setPerson(person!);
    });
  }

  @override
  void initState() {
    _controllerName.text = widget.person!.name;
    _controllerNewEmail.text = widget.person!.email;
    // _controllerPassword.text = widget.person!.email;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text('Profile Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _controllerName,
                validator: (value) => value == '' ? "Don't Empty" : null,
                decoration: const InputDecoration(
                  hintText: 'Name',
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
                textAlignVertical: TextAlignVertical.center,
              ),
              TextFormField(
                controller: _controllerNewEmail,
                validator: (value) => value == '' ? "Don't Empty" : null,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                textAlignVertical: TextAlignVertical.center,
              ),
              TextFormField(
                controller: _controllerPassword,
                validator: (value) => value == '' ? "Don't Empty" : null,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                textAlignVertical: TextAlignVertical.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        deleteProfile();
                      }
                    },
                    icon: Icon(Icons.delete_forever),
                    label: Text('Delete Account'),
                  ),
                  ElevatedButton.icon(
                    // style: ElevatedButton.styleFrom(
                    // ba: Colors.blue,
                    // textColor: Colors.white,),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        updateProfile();
                      }
                    },
                    icon: Icon(Icons.check),
                    label: Text('Update '),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

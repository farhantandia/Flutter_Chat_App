// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/event/event_contact.dart';
import 'package:flutter_chat_app/event/event_person.dart';

import 'package:flutter_chat_app/model/person.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ProfilePerson extends StatefulWidget {
  Person? person;
  String? myUid;
  ProfilePerson({
    Key? key,
    required this.person,
    required this.myUid,
  }) : super(key: key);

  @override
  State<ProfilePerson> createState() => _ProfilePersonState();
}

class _ProfilePersonState extends State<ProfilePerson> {
  bool _isContact = false;

  Future<void> checkContact() async {
    _isContact = await EventContact.checkIsMyContact(myUid: widget.myUid!, personUid: widget.person!.uid);
    setState(() {});

    EasyLoading.dismiss();
  }

  Future<void> deleteContact() async {
    await EventContact.deleteContact(myUid: widget.myUid!, personUid: widget.person!.uid);
  }

  Future<void> addContact() async {
    await EventPerson.getPerson(widget.person!.uid).then((person) => EventContact.addContact(myUid: widget.myUid!, person: widget.person!));
  }

  @override
  void initState() {
    EasyLoading.show(status: "Loading profile...");
    // TODO: implement initState
    checkContact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
              radius: 80,
              child: ClipOval(
                child: widget.person!.photo.isNotEmpty
                    ? Image.network(
                        widget.person!.photo,
                        fit: BoxFit.cover,
                        width: 150,
                        height: 150,
                      )
                    : Image.asset(
                        'assets/user-pic.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
              )),
          const SizedBox(
            height: 20,
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Name'),
            subtitle: Text(widget.person!.name),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(widget.person!.email),
          ),
          const Divider(
            height: 15,
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _isContact ? Colors.redAccent : Colors.teal),
            onPressed: () async {
              if (_isContact) {
                await deleteContact();
                EasyLoading.showSuccess("Contact deleted");
              } else {
                await addContact();
                EasyLoading.showSuccess("Contact added");
              }
              checkContact();
            },
            child: Text(_isContact ? 'Delete Contact' : 'Add Contact'),
          )
        ],
      ),
    );
  }
}

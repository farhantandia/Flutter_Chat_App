import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_app/event/event_contact.dart';
import 'package:flutter_chat_app/event/event_person.dart';
import 'package:flutter_chat_app/model/person.dart';
import 'package:flutter_chat_app/model/room.dart';
import 'package:flutter_chat_app/page/chat_room.dart';
import 'package:flutter_chat_app/page/profile_person.dart';
import 'package:flutter_chat_app/utils/prefs.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ListContact extends StatefulWidget {
  const ListContact({super.key});

  @override
  State<ListContact> createState() => _ListContactState();
}

class _ListContactState extends State<ListContact> {
  var _controllerEmail = TextEditingController();
  Person? _myPerson;
  Stream<QuerySnapshot>? _streamContact;

  @override
  void initState() {
    // TODO: implement initState
    getMyPerson();
    super.initState();
  }

  void getMyPerson() async {
    Person? person = await Prefs.getPerson();
    setState(() {
      _myPerson = person;
    });
    _streamContact =
        FirebaseFirestore.instance.collection('person').doc(_myPerson!.uid).collection('contact').snapshots(includeMetadataChanges: true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _streamContact,
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data != null && snapshot.data!.docs.isNotEmpty) {
              List<QueryDocumentSnapshot> listContact = snapshot.data!.docs;
              return ListView.separated(
                itemCount: listContact.length,
                separatorBuilder: (context, index) {
                  return const Divider(thickness: 1, height: 1);
                },
                itemBuilder: (context, index) {
                  Map<String, dynamic> mapData = listContact[index].data() as Map<String, dynamic>;
                  Person person = Person.fromJson(mapData);
                  return itemContact(person);
                },
              );
            } else {
              return const Center(child: Text('Empty'));
            }
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              addNewContact();
            },
          ),
        ),
      ],
    );
  }

  void addNewContact() async {
    var value = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SimpleDialog(
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          contentPadding: const EdgeInsets.all(16),
          title: const Text('Add Contact'),
          children: [
            TextField(
              controller: _controllerEmail,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'email@gmail.com',
              ),
              textAlignVertical: TextAlignVertical.bottom,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () => Navigator.pop(context, true),
            ),
            OutlinedButton(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        );
      },
    );
    if (value) {
      if (_controllerEmail.text != _myPerson!.email) {
        EasyLoading.show(status: "loading...");
        String personUid = await EventPerson.checkEmail(_controllerEmail.text);
        if (personUid != '') {
          EventPerson.getPerson(personUid).then((person) {
            EventContact.addContact(myUid: _myPerson!.uid, person: person);
          });

          EasyLoading.showSuccess("Contact added!");
        } else {
          EasyLoading.showError("Contact not found!");
        }
      }else{
        
          EasyLoading.showError("Invalid Contact");
      }
    }
    _controllerEmail.clear();
  }

  Widget itemContact(Person person) {
    return ListTile(
      leading: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePerson(
                person: person,
                myUid: _myPerson!.uid,
              ),
            ),
          );
        },
        child: SizedBox(
          width: 40,
          height: 40,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: FadeInImage(
              placeholder: const AssetImage('assets/logo_flikchat.png'),
              image: NetworkImage(person.photo),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              imageErrorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/user-pic.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        ),
      ),
      title: Text(person.name),
      subtitle: Text(person.email),
      trailing: IconButton(
        icon: const Icon(Icons.message),
        onPressed: () {
          Room room = Room(
            email: person.email,
            inRoom: false,
            lastChat: '',
            lastDateTime: 0,
            lastUid: '',
            name: person.name,
            photo: person.photo,
            type: '',
            uid: person.uid,
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatRoom(room: room)),
          );
        },
      ),
    );
  }
}

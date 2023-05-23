// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_app/model/chat.dart';
import 'package:flutter_chat_app/model/person.dart';

import 'package:flutter_chat_app/model/room.dart';
import 'package:flutter_chat_app/utils/prefs.dart';

class ChatRoom extends StatefulWidget {
  final Room room;
  const ChatRoom({
    Key? key,
    required this.room,
  }) : super(key: key);

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  Person? _myPerson;
  Stream<QuerySnapshot>? _streamChat;
  @override
  void initState() {
    // TODO: implement initState
    getMyPerson();
    super.initState();
  }

  void getMyPerson() async {
    Person person = await Prefs.getPerson();
    setState(() {
      _myPerson = person;
    });
    _streamChat = FirebaseFirestore.instance
        .collection('person')
        .doc(_myPerson!.uid)
        .collection('room')
        .doc(widget.room.uid)
        .collection('chat')
        .snapshots(includeMetadataChanges: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: FadeInImage(
                placeholder: AssetImage('assets/user-pic.png'),
                image: NetworkImage(widget.room.photo),
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                imageErrorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/user-pic.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ),
          SizedBox(width: 10,),
          Text(widget.room.name ,style: TextStyle(fontSize: 18),),
        ],
      )),
      body: StreamBuilder<QuerySnapshot>(
        stream: _streamChat,
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
                Chat chat = Chat.fromJson(mapData);
                return itemChat(chat);
              },
            );
          } else {
            return const Center(child: Text('Empty'));
          }
        },
      ),
    );
  }

  Widget itemChat(Chat chat) {
    if (chat.type == 'text') {
      return Text('message');
    }
    return Container(height: 20, width: 100, color: Colors.teal,);
  }
}

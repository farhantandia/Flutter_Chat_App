import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_app/event/event_chat_room.dart';
import 'package:flutter_chat_app/model/chat.dart';
import 'package:flutter_chat_app/model/person.dart';
import 'package:flutter_chat_app/model/room.dart';
import 'package:flutter_chat_app/page/chat_room.dart';
import 'package:flutter_chat_app/page/profile_person.dart';
import 'package:flutter_chat_app/utils/prefs.dart';
import 'package:intl/intl.dart';

class ListChatRoom extends StatefulWidget {
  const ListChatRoom({super.key});

  @override
  State<ListChatRoom> createState() => _ListChatRoomState();
}

class _ListChatRoomState extends State<ListChatRoom> {
  Person? _myPerson;
  Stream<QuerySnapshot>? _streamRoom;
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
    _streamRoom = FirebaseFirestore.instance.collection('person').doc(_myPerson!.uid).collection('room').snapshots(includeMetadataChanges: true);
  }

  void deleteChatRoom(String personUid) async {
    var value = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SimpleDialog(
          children: [
            ListTile(
              onTap: () => Navigator.pop(context, 'delete'),
              title: const Text('Delete Chat Room'),
            ),
            ListTile(
              onTap: () => Navigator.pop(context),
              title: const Text('Close'),
            ),
          ],
        );
      },
    );
    if (value == 'delete') {
      EventChatRoom.deleteChatRoom(myUid: _myPerson!.uid, personUid: personUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _streamRoom,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data != null && snapshot.data!.docs.isNotEmpty) {
          List<QueryDocumentSnapshot> listRoom = snapshot.data!.docs;
          return ListView.separated(
            itemCount: listRoom.length,
            separatorBuilder: (context, index) {
              return const Divider(thickness: 1, height: 1);
            },
            itemBuilder: (context, index) {
              Map<String, dynamic> mapData = listRoom[index].data() as Map<String, dynamic>;
              Room room = Room.fromJson(mapData);
              return itemRoom(room);
            },
          );
        } else {
          return const Center(child: Text('Empty'));
        }
      },
    );
  }

  Widget itemRoom(Room room) {
    String today = DateFormat('yyyy/MM/dd').format(DateTime.now());
    String yesterday = DateFormat('yyyy/MM/dd').format(DateTime.now().subtract(const Duration(days: 1)));
    DateTime roomDateTime = DateTime.fromMicrosecondsSinceEpoch(room.lastDateTime);
    String stringLastDateTime = DateFormat('yyyy/MM/dd').format(roomDateTime);
    String time = '';
    if (stringLastDateTime == today) {
      time = DateFormat('HH:mm').format(roomDateTime);
    } else if (stringLastDateTime == yesterday) {
      time = 'Yesterday';
    } else {
      time = DateFormat('yyyy/MM/dd').format(roomDateTime);
    }
    return Material(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatRoom(room: room)),
          );
        },
        onLongPress: () {
          deleteChatRoom(room.uid);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Person person = Person(
                    email: room.email,
                    name: room.name,
                    photo: room.photo,
                    token: '',
                    uid: room.uid,
                  );
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: FadeInImage(
                    placeholder: const AssetImage('assets/logo_flikchat.png'),
                    image: NetworkImage(room.photo),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/logo_flikchat.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          child: room.type == 'image' ? Icon(Icons.image, size: 15, color: Colors.grey[700]) : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          room.type == 'text'
                              ? room.lastChat.length > 15
                                  ? room.lastChat.substring(0, 15) + '...'
                                  : room.lastChat
                              : ' <Image>',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$time',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  countUnreadMessage(room.uid, room.lastDateTime),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget countUnreadMessage(String personUid, int lastDateTime) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('person')
          .doc(_myPerson!.uid)
          .collection('room')
          .doc(personUid)
          .collection('chat')
          .snapshots(includeMetadataChanges: true),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const SizedBox();
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }
        if (snapshot.data == null) {
          return const SizedBox();
        }
        List<QueryDocumentSnapshot> listChat = snapshot.data!.docs;
        // for (var element in listChat) {
        //   print(element.data());
        // }
        QueryDocumentSnapshot lastChat =
            listChat.where((element) => (element.data() as Map<String, dynamic>)['lastDateTime'] == lastDateTime).toList()[0];

        Map<String, dynamic> mapData = lastChat.data() as Map<String, dynamic>;
        Chat lastDataChat = Chat.fromJson(mapData);

        if (lastDataChat.uidSender == _myPerson!.uid) {
          return Icon(
            Icons.check,
            size: 20,
            color: lastDataChat.isRead ? Colors.blue : Colors.grey,
          );
        } else {
          int unRead = 0;
          for (var doc in listChat) {
            
            Map<String, dynamic> mapData = doc.data() as Map<String, dynamic>;
            Chat docChat = Chat.fromJson(mapData);
            if (!docChat.isRead && docChat.uidSender == personUid) {
              unRead = unRead + 1;
            }
          }
          if (unRead == 0) {
            return const SizedBox();
          } else {
            return Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(4),
              child: Text(
                unRead.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            );
          }
        }
      },
    );
  }
  
}

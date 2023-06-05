// ignore_for_file: public_member_api_docs, sort_constructors_first, deprecated_member_use
import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_chat_app/event/event_chat_room.dart';
import 'package:flutter_chat_app/event/event_person.dart';
import 'package:flutter_chat_app/event/event_storage.dart';
import 'package:flutter_chat_app/model/chat.dart';
import 'package:flutter_chat_app/model/person.dart';

import 'package:flutter_chat_app/model/room.dart';
import 'package:flutter_chat_app/page/profile_person.dart';
import 'package:flutter_chat_app/utils/image_controller.dart';
import 'package:flutter_chat_app/utils/notif_controller.dart';
import 'package:flutter_chat_app/utils/prefs.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatRoom extends StatefulWidget {
  final Room room;
  const ChatRoom({
    Key? key,
    required this.room,
  }) : super(key: key);

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> with WidgetsBindingObserver {
  Person? _myPerson;
  Stream<QuerySnapshot>? _streamChat;
  String _inputMessage = '';
  TextEditingController _controllerMessage = TextEditingController();
  Chat? _selectedChat;

  void getSelectedDefault() {
    setState(() {
      _selectedChat = Chat(lastDateTime: 0, isRead: false, message: "", type: "", uidReceiver: "", uidSender: "");
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    getMyPerson();
    getSelectedDefault();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    EventChatRoom.setMeOutRoom(_myPerson!.uid, widget.room.uid);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
        print('App inactive-------------------------');
        break;
      case AppLifecycleState.resumed:
        EventChatRoom.setMeInRoom(_myPerson!.uid, widget.room.uid);
        print('App resume-------------------------');
        break;
      case AppLifecycleState.paused:
        EventChatRoom.setMeOutRoom(_myPerson!.uid, widget.room.uid);
        print('App paused-------------------------');
        break;
      case AppLifecycleState.detached:
        print('App detached-------------------------');
        break;
      default:
        print('Default------------------');
        break;
    }
  }

  void getMyPerson() async {
    Person? person = await Prefs.getPerson();
    setState(() {
      _myPerson = person;
    });

    EventChatRoom.setMeInRoom(_myPerson!.uid, widget.room.uid);
    _streamChat = FirebaseFirestore.instance
        .collection('person')
        .doc(_myPerson!.uid)
        .collection('room')
        .doc(widget.room.uid)
        .collection('chat')
        .snapshots(includeMetadataChanges: true);
  }

  sendMessage(String type, String message) async {
    if (type == 'text') _controllerMessage.clear();
    var dateTime = DateTime.now().microsecondsSinceEpoch;

    Chat chat = Chat(lastDateTime: dateTime, isRead: false, message: message, type: type, uidReceiver: widget.room.uid, uidSender: _myPerson!.uid);

    bool personInRoom = await EventChatRoom.checkIsPersonInRoom(
      myUid: _myPerson!.uid,
      personUid: widget.room.uid,
    );
    Room roomSender = Room(
        email: _myPerson!.email,
        inRoom: true,
        lastChat: message,
        lastDateTime: chat.lastDateTime,
        lastUid: _myPerson!.uid,
        name: _myPerson!.name,
        photo: _myPerson!.photo,
        type: type,
        uid: _myPerson!.uid);
    Room roomReceiver = Room(
        email: widget.room.email,
        inRoom: personInRoom,
        lastChat: message,
        lastDateTime: chat.lastDateTime,
        lastUid: widget.room.uid,
        name: widget.room.name,
        photo: widget.room.photo,
        type: type,
        uid: widget.room.uid);

    // Sender Room
    bool isSenderRoomExist = await EventChatRoom.checkRoomIsExist(
      isSender: true,
      myUid: _myPerson!.uid,
      personUid: widget.room.uid,
    );
    if (isSenderRoomExist) {
      EventChatRoom.updateRoom(
        isSender: true,
        myUid: _myPerson!.uid,
        personUid: widget.room.uid,
        room: roomSender,
      );
    } else {
      EventChatRoom.addRoom(
        isSender: true,
        myUid: _myPerson!.uid,
        personUid: widget.room.uid,
        room: roomSender,
      );
    }
    EventChatRoom.addChat(
      chat: chat,
      isSender: true,
      myUid: _myPerson!.uid,
      personUid: widget.room.uid,
    );

    // Receiver Room
    bool isReceiverRoomExist = await EventChatRoom.checkRoomIsExist(
      isSender: false,
      myUid: _myPerson!.uid,
      personUid: widget.room.uid,
    );
    if (isReceiverRoomExist) {
      EventChatRoom.updateRoom(
        isSender: false,
        myUid: _myPerson!.uid,
        personUid: widget.room.uid,
        room: roomReceiver,
      );
    } else {
      EventChatRoom.addRoom(
        isSender: false,
        myUid: _myPerson!.uid,
        personUid: widget.room.uid,
        room: roomReceiver,
      );
    }
    EventChatRoom.addChat(
      chat: chat,
      isSender: false,
      myUid: _myPerson!.uid,
      personUid: widget.room.uid,
    );

    String token = await EventPerson.getPersonToken(widget.room.uid);
    if (token != '') {
      await NotifController.sendNotification(
        myLastChat: message,
        myName: _myPerson!.name,
        myUid: _myPerson!.uid,
        personToken: token,
        photo: _myPerson!.photo,
        type: type,
      );
    }
    print(token);

    if (personInRoom) {
      EventChatRoom.updateChatIsRead(
        chatId: chat.lastDateTime.toString(),
        isSender: true,
        myUid: _myPerson!.uid,
        personUid: widget.room.uid,
      );
      EventChatRoom.updateChatIsRead(
        chatId: chat.lastDateTime.toString(),
        isSender: false,
        myUid: _myPerson!.uid,
        personUid: widget.room.uid,
      );
    }
  }

  setImage({String fullPath = ''}) async {
    EasyLoading.show(status: "loading...");
    var imgUrl = await EventStorage.uploadMessageImageAndGetUrl(myUid: _myPerson!.uid, filePhoto: File(fullPath), personUid: widget.room.uid);
    if (imgUrl.isNotEmpty) {
      await sendMessage('image', imgUrl);
    }

    EasyLoading.dismiss();
  }

  onDeleteMessage() async {
    if (_selectedChat!.type == 'image') {
      await EventStorage.deleteOldFile(_selectedChat!.message);
    }
    await EventChatRoom.deleteMessage(
        isSender: true, myUid: _myPerson!.uid, personUid: widget.room.uid, chatId: _selectedChat!.lastDateTime.toString());
    await EventChatRoom.deleteMessage(
        isSender: false, myUid: _myPerson!.uid, personUid: widget.room.uid, chatId: _selectedChat!.lastDateTime.toString());
    getSelectedDefault();
  }

  void showNotifSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          actions: [
            SizedBox(
                child: _selectedChat!.message.isNotEmpty && _selectedChat!.uidSender == _myPerson!.uid
                    ? IconButton(
                        onPressed: () async {
                          onDeleteMessage();
                        },
                        icon: const Icon(Icons.delete))
                    : null),
            if (_selectedChat!.message.isNotEmpty && _selectedChat!.type == 'text')
              IconButton(
                  onPressed: () async {
                    FlutterClipboard.copy(_selectedChat!.message);
                    showNotifSnackBar('Message copied');
                  },
                  icon: const Icon(Icons.copy))
          ],
          title: GestureDetector(
            onTap: () {
              Person person = Person(
                    email: widget.room.email,
                    name: widget.room.name,
                    photo: widget.room.photo,
                    token: '',
                    uid: widget.room.uid,
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
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: widget.room.photo.isNotEmpty
                        ? FadeInImage(
                            placeholder: const AssetImage('assets/user-pic.png'),
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
                          )
                        : Image.asset(
                            'assets/user-pic.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Flexible(
                  child: Text(
                    widget.room.name,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _streamChat,
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data != null && snapshot.data!.docs.isNotEmpty) {
                List<QueryDocumentSnapshot> listChat = snapshot.data!.docs;
                return GroupedListView<QueryDocumentSnapshot, String>(
                  elements: listChat,
                  groupBy: (element) {
                    Chat chat = Chat.fromJson(element.data() as Map<String, dynamic>);
                    DateTime chatDateTime = DateTime.fromMicrosecondsSinceEpoch(chat.lastDateTime);
                    String dateTime = DateFormat('yyyy/MM/dd').format(chatDateTime);
                    return dateTime;
                  },
                  groupSeparatorBuilder: (value) {
                    String group = '';
                    String today = DateFormat('yyyy/MM/dd').format(DateTime.now());
                    String yesterday = DateFormat('yyyy/MM/dd').format(DateTime.now().subtract(const Duration(days: 1)));
                    if (value == today) {
                      group = 'Today';
                    } else if (value == yesterday) {
                      group = 'Yesterday';
                    } else {
                      group = value;
                    }
                    return Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: 30,
                        width: 100,
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          group,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                  itemComparator: (item1, item2) => item1.id.compareTo(item2.id),
                  useStickyGroupSeparators: true,
                  floatingHeader: true,
                  reverse: true,
                  order: GroupedListOrder.DESC,
                  indexedItemBuilder: (context, element, index) {
                    final reverseIndex = listChat.length - 1 - index;
                    Chat chat = Chat.fromJson(listChat[reverseIndex].data() as Map<String, dynamic>);
                    return GestureDetector(
                      onLongPress: () {
                        if (chat.message != '') {
                          setState(() {
                            _selectedChat = chat;
                          });
                        }
                      },
                      onTap: () {
                        getSelectedDefault();
                      },
                      child: Container(
                        margin: EdgeInsets.only(
                          bottom: reverseIndex == listChat.length - 1 ? 80 : 0,
                        ),
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          2,
                          16,
                          2,
                        ),
                        color: _selectedChat!.lastDateTime == chat.lastDateTime ? Colors.teal.withOpacity(0.5) : Colors.transparent,
                        child: itemChat(chat),
                      ),
                    );
                  },
                );
              } else {
                return const Center(child: Text('Empty'));
              }
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.teal,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  onPressed: () async {
                    EasyLoading.show(status: 'Loading');
                    await ImageController.pickAndCropImage(setImage, 'chattingPic_${DateTime.now().microsecondsSinceEpoch}', context);
                  },
                  icon: const Icon(Icons.image),
                  color: Colors.white,
                ),
                Expanded(
                    child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: _controllerMessage,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                        hintText: 'Text Message',
                        border: InputBorder.none,
                        hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.grey)),
                    onChanged: (value) {
                      setState(() {
                        _inputMessage = value;
                      });
                    },
                  ),
                )),
                IconButton(
                  onPressed: () {
                    if (_controllerMessage.text.isNotEmpty) {
                      sendMessage('text', _controllerMessage.text);
                    }
                  },
                  icon: const Icon(Icons.send),
                  color: Colors.white,
                ),
              ]),
            ),
          )
        ],
      ),
    );
  }

  Widget itemChat(Chat chat) {
    DateTime chatDateTime = DateTime.fromMicrosecondsSinceEpoch(chat.lastDateTime);
    String dateTime = DateFormat('HH:mm').format(chatDateTime);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: chat.uidSender == _myPerson!.uid ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        SizedBox(
          child: chat.uidSender == _myPerson!.uid ? Icon(chat.isRead ? Icons.done_all : Icons.check, size: 20, color: Colors.teal) : null,
        ),
        const SizedBox(width: 4),
        SizedBox(
          child: chat.uidSender == _myPerson!.uid ? Text(dateTime, style: const TextStyle(fontSize: 12)) : null,
        ),
        const SizedBox(width: 4),
        chat.type == 'text' || chat.message == '' ? messageText(chat) : messageImage(chat),
        const SizedBox(width: 4),
        SizedBox(
          child: chat.uidSender == widget.room.uid ? Text(dateTime, style: const TextStyle(fontSize: 12)) : null,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget messageText(Chat chat) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: BoxDecoration(
        color: chat.message == ''
            ? Colors.teal.withOpacity(0.3)
            : chat.uidSender == _myPerson!.uid
                ? Colors.teal
                : Colors.teal[800],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            chat.uidSender == _myPerson!.uid ? 10 : 0,
          ),
          topRight: Radius.circular(
            chat.uidSender == _myPerson!.uid ? 0 : 10,
          ),
          bottomLeft: const Radius.circular(10),
          bottomRight: const Radius.circular(10),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: ParsedText(
        text: chat.message == '' ? 'message was deleted' : chat.message,
        style: TextStyle(color: chat.message == '' ? Colors.grey[600] : Colors.white, fontSize: 15),
        parse: [
          MatchText(
              type: ParsedType.EMAIL,
              style: const TextStyle(
                color: Colors.yellow,
              ),
              onTap: (url) {
                launch("mailto:" + url);
              }),
          MatchText(
              type: ParsedType.URL,
              style: const TextStyle(
                color: Colors.yellow,
              ),
              onTap: (url) async {
                var a = await canLaunch(url.contains('http') ? url : 'https://$url');

                if (a) {
                  try {
                    launch(url.contains('http') ? url : 'https://$url');
                  } catch (e) {
                    EasyLoading.showError("Invalid Link");
                  }
                } else {
                  EasyLoading.showError("Invalid Link");
                }
              }),
          MatchText(
              type: ParsedType.PHONE,
              style: const TextStyle(
                color: Colors.yellow,
              ),
              onTap: (url) {
                launch("tel:" + url);
              }),
        ],
      ),
    );
  }

  Widget messageImage(Chat chat) {
    return GestureDetector(
      onTap: () => showImageFull(chat.message),
      child: Container(
        decoration: BoxDecoration(
          color: chat.uidSender == _myPerson!.uid ? Colors.teal : Colors.teal[800],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(
              chat.uidSender == _myPerson!.uid ? 10 : 0,
            ),
            topRight: Radius.circular(
              chat.uidSender == _myPerson!.uid ? 0 : 10,
            ),
            bottomLeft: const Radius.circular(10),
            bottomRight: const Radius.circular(10),
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(
              chat.uidSender == _myPerson!.uid ? 10 : 0,
            ),
            topRight: Radius.circular(
              chat.uidSender == _myPerson!.uid ? 0 : 10,
            ),
            bottomLeft: const Radius.circular(10),
            bottomRight: const Radius.circular(10),
          ),
          child: chat.message.isNotEmpty
              ? FadeInImage(
                  placeholder: const AssetImage('assets/logo_flikchat.png'),
                  image: NetworkImage(chat.message),
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: MediaQuery.of(context).size.width * 0.5,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/logo_flikchat.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    );
                  },
                )
              : Image.asset(
                  'assets/logo_flikchat.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }

  void showImageFull(String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        children: [
          PhotoView(
            enableRotation: true,
            imageProvider: NetworkImage(imageUrl),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.black.withOpacity(0.5),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

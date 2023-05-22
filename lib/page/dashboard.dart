import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/event/event_person.dart';
import 'package:flutter_chat_app/event/event_storage.dart';
import 'package:flutter_chat_app/model/person.dart';
import 'package:flutter_chat_app/page/forgot_password.dart';
import 'package:flutter_chat_app/page/fragment/list_chat_room.dart';
import 'package:flutter_chat_app/page/fragment/list_contact.dart';
import 'package:flutter_chat_app/page/login.dart';
import 'package:flutter_chat_app/utils/prefs.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_cropping/constant/strings.dart';
import 'package:image_cropping/image_cropping.dart';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String? myPhotoLink = "";

  Person? _myPerson = Person(email: "", name: "", photo: "", token: "", uid: "");
  int indexFragment = 0;
  List<Widget> listFragment = [ListChatRoom(), ListContact()];
  @override
  void initState() {
    // TODO: implement initState
    getMyPerson();
  }

  void showLoader() {
    if (EasyLoading.isShow) {
      return;
    }
    EasyLoading.show(status: "loading...");
  }

  /// To hide loader
  void hideLoader() {
    EasyLoading.dismiss();
  }

  void pickAndCropPhoto() async {
    Uint8List? imageBytes;
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 25);

    if (image != null) {
      imageBytes = await image.readAsBytes();
      // ignore: use_build_context_synchronously
      final croppedBytes = await ImageCropping.cropImage(
          context: context,
          imageBytes: imageBytes,
          onImageDoneListener: (data) {
            setState(
              () {
                imageBytes = data;
              },
            );
          },
          customAspectRatios: [
            const CropAspectRatio(
              ratioX: 4,
              ratioY: 5,
            ),
          ],
          onImageStartLoading: showLoader,
          onImageEndLoading: hideLoader,
          visibleOtherAspectRatios: true,
          squareBorderWidth: 2,
          isConstrain: false,
          squareCircleColor: Colors.red,
          defaultTextColor: Colors.black,
          selectedTextColor: Colors.orange,
          colorForWhiteSpace: Colors.white,
          makeDarkerOutside: true,
          outputImageFormat: OutputImageFormat.jpg,
          encodingQuality: 10);

      if (croppedBytes != null) {
        showLoader();
        String dir = (await getApplicationDocumentsDirectory()).path;
        String fullPath = '$dir/personPhoto.png';
        print("local file full path ${fullPath}");
        File file = File(fullPath);
        await file.writeAsBytes(croppedBytes);
        await EventStorage.editPhoto(filePhoto: File(fullPath), oldUrl: myPhotoLink!, uid: _myPerson!.uid);
        EasyLoading.showSuccess('Profile picture changed');
      } else {
        hideLoader();
      }
      EventPerson.getPerson(_myPerson!.uid).then((person) {
        Prefs.setPerson(person);
        getMyPerson();
      });
    } else {
      hideLoader();
    }
    setState(() {});
  }

  void getMyPerson() async {
    Person person = await Prefs.getPerson();
    setState(() {
      _myPerson = person;
      myPhotoLink = _myPerson!.photo;
    });
  }

  void logout() async {
    var value = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Confirm Log out'),
              content: Text('Are you sure want to log out?'),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel')),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: Text('Yes'))
              ],
            )).then((value) async {
      if (value) {
        Prefs.clear();
        await FirebaseAuth.instance.signOut();

        Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat App'),
          backgroundColor: Colors.teal,
          bottom: TabBar(tabs: [
            Tab(
              text: 'Chat',
            ),
            Tab(
              text: 'Contact',
            )
          ]),
        ),
        drawer: menuDrawer(),
        body: TabBarView(
          children: listFragment,
        ),
      ),
    );
  }

  Widget menuDrawer() {
    return Drawer(
      child: ListView(children: [
        DrawerHeader(
            decoration: const BoxDecoration(color: Colors.teal),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Dashboard()),
                    );
                  },
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: myPhotoLink!.isEmpty
                          ? const FadeInImage(
                              placeholder: AssetImage('assets/logo_flikchat.png'),
                              image: AssetImage('assets/user-pic.png'),
                              width: 100,
                            )
                          : FadeInImage(
                              placeholder: const AssetImage('assets/logo_flikchat.png'),
                              image: NetworkImage(_myPerson!.photo),
                              width: 100,
                              imageErrorBuilder: (context, error, stackTrace) => Image.asset(
                                'assets/user-pic.png',
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            )),
                ),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_myPerson!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20)),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        _myPerson!.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                )
              ],
            )),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Edit Profile'),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Reset Password'),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.image),
          title: const Text('Edit Photo'),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {
            Navigator.pop(context);
            pickAndCropPhoto();
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {
            logout();
          },
        )
      ]),
    );
  }
}

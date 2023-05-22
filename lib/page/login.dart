import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_chat_app/event/event_person.dart';
import 'package:flutter_chat_app/page/dashboard.dart';
import 'package:flutter_chat_app/page/forgot_password.dart';
import 'package:flutter_chat_app/page/register.dart';
import 'package:flutter_chat_app/utils/notif_controller.dart';
import 'package:flutter_chat_app/utils/prefs.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _controllerEmail = TextEditingController();
  final _controllerPassword = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
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

  void loginWithEmailAndPassword() async {
    FocusScope.of(context).unfocus();
    showLoader();

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );

      if (userCredential.user!.uid != null) {
        if (userCredential.user!.emailVerified) {
          String token = await NotifController.getTokenFromDevice();
          await EventPerson.updatePersonToken(userCredential.user!.uid, token);
          await EventPerson.getPerson(userCredential.user!.uid).then((person) {
            print(person);
            Prefs.setPerson(person);
          });

          showNotifSnackBar('Login success');
          await Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Dashboard()),
            );
          });
          _controllerEmail.clear();
          _controllerPassword.clear();
        } else {
          print('not verified');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Email not verified'),
              action: SnackBarAction(
                label: 'Send Verif',
                onPressed: () async {
                  await userCredential.user!.sendEmailVerification();
                },
              ),
            ),
          );
        }
      } else {
        showNotifSnackBar('Failed');
        print('failed');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showNotifSnackBar('User not found');
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        showNotifSnackBar('Wrong password');
        print('Wrong password provided for that user.');
      }
    }
    hideLoader();
  }

  void showNotifSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            Positioned(
              bottom: 16,
              right: 0,
              left: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Not have account?'),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Register()),
                      );
                    },
                    child: const Text(
                      'Register',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/logo_flikchat.png',
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: _controllerEmail,
                          validator: (value) => value == '' ? "Don't Empty" : null,
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          textAlignVertical: TextAlignVertical.center,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _controllerPassword,
                          validator: (value) => value == '' ? "Don't Empty" : null,
                          decoration: const InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                          ),
                          textAlignVertical: TextAlignVertical.center,
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPassword(),
                              ),
                            );
                          },
                          child: const Text('Forgot Pasword?'),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                loginWithEmailAndPassword();
                              }
                            },
                            child: const Text(
                              'Login',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

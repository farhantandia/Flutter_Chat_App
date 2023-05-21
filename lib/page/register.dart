import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/event/event_person.dart';
import 'package:flutter_chat_app/model/person.dart';

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {


  var _formKey = GlobalKey<FormState>();
  var _controllerName = TextEditingController();
  var _controllerEmail = TextEditingController();
  var _controllerPassword = TextEditingController();
  var _scaffoldKey = GlobalKey<ScaffoldState>();

  void registerAccount() async {
    if (await EventPerson.checkEmail(_controllerEmail.text) == '') {
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _controllerEmail.text,
          password: _controllerPassword.text,
        );
        if (userCredential.user!.uid != null) {
          showNotifSnackBar('Register Success');
          Person person = Person(
            email: _controllerEmail.text,
            name: _controllerName.text,
            photo: '',
            token: '',
            uid: userCredential.user!.uid,
          );
          EventPerson.addPerson(person);
          await userCredential.user!.sendEmailVerification();
          _controllerName.clear();
          _controllerEmail.clear();
          _controllerPassword.clear();
        } else {
          showNotifSnackBar('Register Failed');
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          showNotifSnackBar('The password provided is too weak');
          print('The password provided is too weak.');
        } else if (e.code == 'email-already-in-use') {
          showNotifSnackBar('The account already exists for that email');
          print('The account already exists for that email.');
        }
      } catch (e) {
        print(e);
      }
    }
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
      body: SizedBox(
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
                  const Text('Already have account?'),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Login',
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
                          controller: _controllerName,
                          validator: (value) =>
                              value == '' ? "Don't Empty" : null,
                          decoration: const InputDecoration(
                            hintText: 'Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                          textAlignVertical: TextAlignVertical.center,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _controllerEmail,
                          validator: (value) =>
                              value == '' ? "Don't Empty" : null,
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                          ),
                          textAlignVertical: TextAlignVertical.center,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _controllerPassword,
                          validator: (value) =>
                              value == '' ? "Don't Empty" : null,
                          decoration: const InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                          ),
                          textAlignVertical: TextAlignVertical.center,
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                registerAccount();
                              }
                            },
                            child: const Text('Register', style: TextStyle(
                            color: Colors.white),),
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

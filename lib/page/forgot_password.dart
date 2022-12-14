import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';

class ForgotPassword extends StatelessWidget {
  var _controllerEmail = TextEditingController();
  var _formKey = GlobalKey<FormState>();
  var _scaffoldKey = GlobalKey<ScaffoldState>();

  void resetPassword() {
    FirebaseAuth.instance.sendPasswordResetEmail(email: _controllerEmail.text);
    _scaffoldKey.currentState!.showSnackBar(
      const SnackBar(content: Text('Link Reset Password has send to email')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text('Reset Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _controllerEmail,
                validator: (value) => value == '' ? "Don't Empty" : null,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                textAlignVertical: TextAlignVertical.center,
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      resetPassword();
                    }
                  },
                  child: const Text(
                    'Recover Password',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

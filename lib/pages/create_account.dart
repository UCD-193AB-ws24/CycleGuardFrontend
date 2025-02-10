import 'dart:math';

import 'package:cycle_guard_app/auth/auth_util.dart';
import 'package:cycle_guard_app/pages/home_page.dart';
import 'package:cycle_guard_app/pages/login_page.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // Import MyAppState

class CreateAccountPage extends StatefulWidget {
  @override


  @override
  State<StatefulWidget> createState() => LoginFormState();
}

class LoginFormState extends State<CreateAccountPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isCreatingAccount = false;

  void _tryCreateAccount() async {
    final username = usernameController.text;
    final password = passwordController.text;

    bool createSuccess = await AuthUtil.createAccount(username, password);
    print(createSuccess?"Create account success!":"Create account failed!");

    if (createSuccess) {
      setState(() {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage()));
      });
    }
  }

  void _login() {
    setState(() {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createAppBar(context, 'Create Account'),
      body: Center(
          child: Column(
            children: [
              Text('Create Account Page'),
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Username',
                ),
                controller: usernameController,
              ),
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Password',
                ),
                controller: passwordController,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  // foregroundColor: Colors.purple,
                  elevation: 0,
                ),
                onPressed: _tryCreateAccount,
                child: Text("Create account"),
              ),
              InkWell(
                onTap: _login,
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          )
      ),
    );
  }
}
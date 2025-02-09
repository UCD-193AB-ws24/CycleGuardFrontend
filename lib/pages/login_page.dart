import 'dart:math';

import 'package:cycle_guard_app/auth/auth_util.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // Import MyAppState

class LoginPage extends StatefulWidget {
  @override


  @override
  State<StatefulWidget> createState() => LoginFormState();
}

class LoginFormState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  void _tryLogin() async {
    final username = usernameController.text;
    final password = passwordController.text;

    bool loginSuccess = await AuthUtil.login(username, password);
    print(loginSuccess?"Login success!":"Login failed!");


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
      appBar: createAppBar(context, 'Login'),
      body: Center(
          child: Column(
            children: [
              Text('Login Page'),
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
                onPressed: _tryLogin,
                child: Text("Log in"),
              ),
            ],
          )
      ),
    );
  }
}
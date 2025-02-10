import 'dart:math';

import 'package:cycle_guard_app/auth/auth_util.dart';
import 'package:cycle_guard_app/pages/create_account.dart';
import 'package:cycle_guard_app/pages/home_page.dart';
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
  bool _isCreatingAccount = false;

  void _tryLogin() async {
    final username = usernameController.text;
    final password = passwordController.text;

    bool loginSuccess = await AuthUtil.login(username, password);
    print(loginSuccess?"Login success!":"Login failed!");

    if (loginSuccess) {
      setState(() {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage()));
      });
    }
  }

  void _createAccount() {
    print("Creating account...");
    setState(() {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CreateAccountPage()));
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
              InkWell(
                onTap: _createAccount,
                child: const Text(
                  'Create account',
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
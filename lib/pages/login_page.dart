import 'package:flutter/material.dart';
import '../main.dart'; // Import MyAppState

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createAppBar(context, 'Login'),
      body: Center(
        child: Text('Login Page'),
      ),
    );
  }
}
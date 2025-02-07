import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold( // Wrap with Scaffold to avoid full-screen issues
      appBar: AppBar(title: Text('Login')),
      body: Center(child: Text('Login Page')),
    );
  }
}
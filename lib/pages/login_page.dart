import 'dart:ffi';

import 'package:cycle_guard_app/auth/auth_util.dart';
import 'package:cycle_guard_app/pages/create_account.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fluttertoast/fluttertoast.dart';

import '../main.dart';

/*
Username: javagod123
Password: c++sucks
*/


class LoginPage extends StatefulWidget {
  @override


  @override
  State<StatefulWidget> createState() => LoginFormState();
}

class LoginFormState extends State<LoginPage> {
  final poppinsStyle = TextStyle(fontSize: 30,fontWeight: FontWeight.bold);
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  void _tryLogin() async {
    final username = usernameController.text;
    final password = passwordController.text;

    Fluttertoast.showToast(
        msg: "Logging in...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16.0
    );

    CreateAccountStatus loginStatus = await AuthUtil.login(username, password);
    final loginSuccess = loginStatus==CreateAccountStatus.success;
    print(loginSuccess?"Login success!":"Login failed!");

    if (loginSuccess) {
      Fluttertoast.cancel();
      setState(() {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage()));
      });
    } else {
      Fluttertoast.cancel();
      Fluttertoast.showToast(
          msg: "Incorrect username or password",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
      );
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

  Widget emailTextField() => TextField(

    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: 'username@example.com',
      labelText: 'Email',
      prefixIcon:  Icon(Icons.mail),
      border: OutlineInputBorder(),
    ),
    controller: usernameController,
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.done,
  );
  bool isVisible = true;
  Widget passwordTextField() => TextField(
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelText: 'password',
      //errorText: 'Incorrect Password',
      border: OutlineInputBorder(),
      suffixIcon: IconButton(
        icon: isVisible ? Icon(Icons.visibility) : Icon(Icons.visibility_off),
        onPressed: ()=>  setState(() => isVisible = !isVisible),
      ),
    ),
    controller: passwordController,
    textInputAction: TextInputAction.done,
    obscureText: isVisible,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 236, 177, 125),
      appBar: AppBar(
        title: Text(
                    'Login',
                    style: GoogleFonts.poppins(
                      textStyle: poppinsStyle
                    )),
        backgroundColor: Color.fromARGB(255, 236, 177, 125),
      ),
      body: Center(
          child: ListView(
            padding: EdgeInsets.all(32),

            children: [
              emailTextField(),
              const SizedBox(height:24),
              passwordTextField(),
              const SizedBox(height:24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  // foregroundColor: Colors.purple,
                  elevation: 5,

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
                    color: Colors.white,
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
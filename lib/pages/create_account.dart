import 'dart:math';

import 'package:cycle_guard_app/auth/auth_util.dart';
import 'package:cycle_guard_app/pages/home_page.dart';
import 'package:cycle_guard_app/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../main.dart'; // Import MyAppState

import 'package:google_fonts/google_fonts.dart';

class CreateAccountPage extends StatefulWidget {
  @override


  @override
  State<StatefulWidget> createState() => LoginFormState();
}

class LoginFormState extends State<CreateAccountPage> {
  final poppinsStyle = TextStyle(fontSize: 30,fontWeight: FontWeight.bold);
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();


  void _tryCreateAccount() async {
    final username = usernameController.text;
    final password = passwordController.text;

    Fluttertoast.showToast(
        msg: "Creating account...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16.0
    );

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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => OnBoardStart()));
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
            'Create Account',
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
                onPressed: _tryCreateAccount,
                child: Text("Create account"),
              ),
              InkWell(
                onTap: _login,
                child: const Text(
                  'Already have an account? Login',
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
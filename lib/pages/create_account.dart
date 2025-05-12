import 'package:cycle_guard_app/auth/auth_util.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Import MyAppState\

import 'package:google_fonts/google_fonts.dart';

class CreateAccountPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LoginFormState();
}

class LoginFormState extends State<CreateAccountPage> {
  final poppinsStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool termsAgreed = false;


  void _tryCreateAccount() async {
    _showTermsDialog();
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

  Widget usernameTextField() => TextField(

    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: 'username',
      labelText: 'username',
      prefixIcon: Icon(Icons.account_circle),
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
      border: OutlineInputBorder(),
      suffixIcon: IconButton(
        icon: isVisible ? Icon(Icons.visibility) : Icon(Icons.visibility_off),
        onPressed: () =>  setState(() => isVisible = !isVisible),
      ),
    ),
    controller: passwordController,
    textInputAction: TextInputAction.done,
    obscureText: isVisible,
  );

  Future<String> _loadTermsOfService() async {
    return await rootBundle.loadString('assets/terms_of_service.txt');
  }

  void _showTermsDialog() async {
    // Load terms text from assets
    String termsText = await _loadTermsOfService();
    
    // Create a local state variable for the dialog
    bool localTermsAgreed = termsAgreed;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Terms of Service", style: TextStyle(color: Colors.black)),
              content: Container(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Markdown(
                              data: termsText,
                              shrinkWrap: true,
                              physics: ClampingScrollPhysics(),
                              styleSheet: MarkdownStyleSheet(
                                  a: const TextStyle(
                                  color: Colors.black,
                                ),
                              )
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: localTermsAgreed,
                          onChanged: (bool? newBool) {
                            setStateDialog(() {
                              localTermsAgreed = newBool ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Text("I agree to the Terms of Service"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      termsAgreed = localTermsAgreed;
                    });
                    Navigator.of(context).pop();
                    if (localTermsAgreed) {
                      _createAccount();
                    } else {
                      _showTermsAlert();
                    }
                  },
                  child: Text("Accept"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showTermsAlert() {
    Fluttertoast.showToast(
      msg: "You must agree to the terms of service to create an account.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _createAccount() async {
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
    print(createSuccess ? "Create account success!" : "Create account failed!");

    if (createSuccess) {
      final appState = Provider.of<MyAppState>(context, listen: false);
      await appState.loadUserProfile();
      setState(() {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAECCF),
      appBar: AppBar(
        title: Text(
            'Create Account',
            style: GoogleFonts.poppins(
                textStyle: poppinsStyle
            )),
        backgroundColor: Color(0xFFFAECCF),
      ),
      body: Center(
          child: ListView(
            padding: EdgeInsets.all(32),
            children: [
              usernameTextField(),
              const SizedBox(height: 24),
              passwordTextField(),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 5,
                ),
                onPressed: _tryCreateAccount,
                child: Text("Create account"),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _login,
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF555555),
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
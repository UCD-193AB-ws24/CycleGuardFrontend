import 'package:flutter/material.dart';
// import '../main.dart'; // Import MyHomePage for navigation
// import 'login_page.dart';

class StartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(200),
              child: Image.asset(
              'assets/cg_img_1.png',
              width: 300,
              height: 300,
            
              ),
            ),
            
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                /*final homePageState = context.findAncestorStateOfType<_MyHomePageState>();
                if (homePageState != null) {
                  homePageState.updateSelectedIndex(1);
                }*/
                Navigator.pushNamed(context, '/loginpage');
              },
              style: ElevatedButton.styleFrom(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text('Get Started', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
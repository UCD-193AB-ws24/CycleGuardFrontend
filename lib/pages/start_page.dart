import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import '../main.dart'; 

class StartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final poppinsStyle = TextStyle(fontSize: 60,fontWeight: FontWeight.bold);
    return Scaffold(
      //backgroundColor: Color(0xFFD6D5C9),
      backgroundColor: Color(0xFFD9D7C8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text(
              "CycleGuard",
              style: GoogleFonts.poppins(
                textStyle: poppinsStyle,
              ),
            ),
            SizedBox(height: 40),
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
import 'package:cycle_guard_app/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import '../main.dart'; 

class StartPage extends StatelessWidget {
  @override
  final PageController pageController;
  StartPage(this.pageController);
  Widget build(BuildContext context) {
    final poppinsStyle = TextStyle(fontSize: 60,fontWeight: FontWeight.bold);
    return Scaffold(
      //backgroundColor: Color(0xFFD6D5C9),
      backgroundColor: Color.fromARGB(255, 236, 177, 125),
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
              child: SvgPicture.asset(
                'assets/cg_logomark.svg',
                width: 300,
                height: 300,
              ),
            ),
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                pageController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
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
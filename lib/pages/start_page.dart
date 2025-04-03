import 'package:cycle_guard_app/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import '../main.dart'; 

class StartPage extends StatelessWidget {
  final PageController pageController;
  StartPage(this.pageController);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color(0xFFF5E7C4),
      body: Stack(
        children: [
          Positioned(
            left: screenWidth * (-0.9), // Shift the logo 20% to the left
            top: screenHeight * 0.05, // Adjust this to set the top position
            child: SvgPicture.asset(
              'assets/cg_logomark.svg',
              width: screenWidth * 0.4,  // Logo width based on screen width (60% of screen width)
              height: screenHeight * 0.95,  // Logo height based on screen height (30% of screen height)
              colorFilter: ColorFilter.mode(
                Color(0xFFFFCC80), 
                BlendMode.srcIn,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "CycleGuard",
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF555555), 
                    ),
                  ),
                ),
                Text(
                  "Ready to Ride?",
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF555555), 
                    ),
                  ),
                ),
                SizedBox(height: 75),

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
        ],
      ),
    );
  }
}
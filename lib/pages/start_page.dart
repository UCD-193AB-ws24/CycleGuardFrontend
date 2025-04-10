import 'package:cycle_guard_app/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../auth/dim_util.dart';
// import '../main.dart'; 

class StartPage extends StatelessWidget {
  final PageController pageController;
  StartPage(this.pageController);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Color(0xFFF5E7C4),
      body: Stack(
        children: [
          Positioned(
            left: DimUtil.safeWidth(context) * (-0.75), 
            top: 0,
            child: SvgPicture.asset(
              'assets/cg_logomark.svg',
              width:  DimUtil.safeWidth(context),
              height: DimUtil.safeHeight(context) * 1.1, 
              colorFilter: ColorFilter.mode(
                Color(0xFFFFCC80), 
                BlendMode.srcIn,
              ),
            ),
          ),
          Positioned(
            top: DimUtil.safeHeight(context) * 0.3,
            left: 15,
            right: 15,
            child: SvgPicture.asset(
              'assets/cg_type_logo.svg',
              width: DimUtil.safeWidth(context) * 0.5, 
              height: DimUtil.safeHeight(context) * 0.3, 
              //fit: BoxFit.contain,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: DimUtil.safeHeight(context) * 0.15),
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
        ],
      ),
    );
  }
}

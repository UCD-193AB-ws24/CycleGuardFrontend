import 'package:cycle_guard_app/auth/auth_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../auth/dim_util.dart';
import '../main.dart';
// import '../main.dart'; 

class StartPage extends StatelessWidget {
  final PageController pageController;
  StartPage(this.pageController);

  void _handlePress() async {
    pageController.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _didLoad = false;
  void _afterLoadToken(BuildContext context) {
    if (_didLoad) return;

    print("Logged in? ${AuthUtil.isLoggedIn()}");
    print("Token found: ${AuthUtil.token}");

    if (!AuthUtil.isLoggedIn()) return;

    _didLoad = true;

    final appState = Provider.of<MyAppState>(context, listen: false);
    if (context.mounted) {
      appState.loadUserSettings().then(
              (onValue) => appState.fetchOwnedThemes().then(
                  (onValue) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage()))
              )
      );

    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building startpage");
    AuthUtil.loadToken().then((onValue) => _afterLoadToken(context));
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
                    _handlePress();
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

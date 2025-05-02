import 'package:cycle_guard_app/auth/auth_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../auth/dim_util.dart';
import '../main.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    print("Logged in? ${AuthUtil.isLoggedIn()}");
    print("Token found: ${AuthUtil.token}");

    if (!AuthUtil.isLoggedIn()) return;

    if (_didLoad) return;
    _didLoad = true;

    final appState = Provider.of<MyAppState>(context, listen: false);
    if (context.mounted) {
      appState.loadUserSettings().then((onValue) => appState
          .fetchOwnedThemes()
          .then((onValue) => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => MyHomePage()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    AuthUtil.loadToken().then((onValue) => _afterLoadToken(context));
    return Scaffold(
      backgroundColor: Color(0xFFF5E7C4),
      body: Stack(
        children: [
          // Background logomark
          Positioned(
            left: DimUtil.safeWidth(context) * (-0.75),
            top: 0,
            child: SvgPicture.asset(
              'assets/cg_logomark.svg',
              width: DimUtil.safeWidth(context),
              height: DimUtil.safeHeight(context) * 1.1,
              colorFilter: ColorFilter.mode(
                Color(0xFFFFD88E),
                BlendMode.srcIn,
              ),
            ),
          ),
          // Type logo
          Positioned(
            top: DimUtil.safeHeight(context) * 0.2,
            left: 16,
            right: 16,
            child: SvgPicture.asset(
              'assets/cg_type_logo.svg',
              width: DimUtil.safeWidth(context) * 0.5,
              height: DimUtil.safeHeight(context) * 0.3,
            ),
          ),
          // CTA
          Positioned(
            top: DimUtil.safeHeight(context) * 0.55,
            left: 16,
            child: SvgPicture.asset(
              'assets/cg_cta.svg',
              width: DimUtil.safeWidth(context) * 0.2,
              height: DimUtil.safeHeight(context) * 0.4,
            ),
          ),
          // Button
          Positioned(
            top: DimUtil.safeHeight(context) * 0.8, 
            right: 16,
            child: ElevatedButton(
              onPressed: () {
                _handlePress();
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.orange),
                elevation: WidgetStateProperty.all(4),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(28),
                      right: Radius.circular(28),
                    ),
                  ),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  FaIcon(
                    FontAwesomeIcons.chevronRight,
                    color: Colors.white38,
                    size: 36,
                  ),
                  FaIcon(
                    FontAwesomeIcons.chevronRight,
                    color: Colors.white60,
                    size: 36,
                  ),
                  FaIcon(
                    FontAwesomeIcons.chevronRight,
                    color: Colors.white,
                    size: 36,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
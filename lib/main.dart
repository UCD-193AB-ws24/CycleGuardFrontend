//import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import pages 
import 'pages/start_page.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/social_page.dart';
import 'pages/history_page.dart';
import 'pages/achievements_page.dart';
import 'pages/routes_page.dart';
import 'pages/store_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: Consumer<MyAppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'Cycle Guard App',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: appState.selectedColor),
            ),
            home: MyHomePage(),
            routes: {
              '/loginpage': (context) => LoginPage(),
            },
          );
        },
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  Color selectedColor = Colors.indigo;

  void updateThemeColor(Color newColor) {
    selectedColor = newColor;
    notifyListeners(); // Notify widgets to rebuild
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = StartPage();
      case 1:
        page = LoginPage();
      case 2:
        page = HomePage();
      case 3:
        page = SocialPage();
      case 4:
        page = HistoryPage();
      case 5:
        page = AchievementsPage();
      case 6:
        page = RoutesPage();
      case 7: 
        page = StorePage();
      case 8: 
        page = SettingsPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              // if (selectedIndex != 0) // comment out this line and the navigation rail will show everywhere except the login page after clicking "get started" button
                SafeArea(
                  child: NavigationRail(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    extended: constraints.maxWidth >= 600,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(Icons.waving_hand_outlined),
                        label: Text('Start'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.login),
                        label: Text('Login'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline),
                        label: Text('Social'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.calendar_month_outlined),
                        label: Text('History'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.emoji_events_outlined),
                        label: Text('Achievements'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.pedal_bike),
                        label: Text('Routes'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.monetization_on_outlined),
                        label: Text('Store'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        label: Text('Settings'),
                      ),
                    ],
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                  ),
                ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
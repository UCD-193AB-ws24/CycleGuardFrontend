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
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: appState.selectedColor),
            ),
            darkTheme: ThemeData.dark().copyWith(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(seedColor: appState.selectedColor)
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
  bool isDarkMode = false;

  final List<Map<String, dynamic>> availableThemes = [
    {'name': 'Indigo', 'color': Colors.indigo},
    {'name': 'Red', 'color': Colors.red},
    {'name': 'Green', 'color': Colors.green},
    {'name': 'Blue', 'color': Colors.blue},
    {'name': 'Purple', 'color': Colors.purple},
    {'name': 'Orange', 'color': Colors.orange},
  ];

  final List<Map<String, dynamic>> storeThemes = [
    {'name': 'Teal', 'color': Colors.teal},
    {'name': 'Lime', 'color': Colors.lime},
    {'name': 'Pink', 'color': Colors.pink},
  ];

  void updateThemeColor(Color newColor) {
    selectedColor = newColor;
    notifyListeners(); 
  }

  void toggleDarkMode(bool isEnabled) {
    isDarkMode = isEnabled;
    notifyListeners();
  }

  void purchaseTheme(Map<String, dynamic> theme) {
    availableThemes.add(theme);
    storeThemes.removeWhere((item) => item['color'] == theme['color']);
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  Color? getIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70 
        : Colors.black; 
  }

  Color? getNavRailBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.secondaryFixedDim; 
  }

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
              // if (selectedIndex != 0) //comment out for navigation menu access
                SizedBox(
                  height: double.infinity,
                  child: NavigationRail(
                    backgroundColor: getNavRailBackgroundColor(context),
                    extended: constraints.maxWidth >= 600,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(Icons.waving_hand_outlined, color: getIconColor(context),),
                        label: Text('Start'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.login_outlined, color: getIconColor(context),),
                        label: Text('Login'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.home, color: getIconColor(context),),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline, color: getIconColor(context),),
                        label: Text('Social'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.calendar_month_outlined, color: getIconColor(context),),
                        label: Text('History'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.emoji_events_outlined, color: getIconColor(context),),
                        label: Text('Achievements'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.pedal_bike, color: getIconColor(context),),
                        label: Text('Routes'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.monetization_on_outlined, color: getIconColor(context),),
                        label: Text('Store'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined, color: getIconColor(context),),
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
                child: page,
              ),
            ],
          ),
        );
      },
    );
  }
}

AppBar createAppBar(BuildContext context, String titleText) {
  return AppBar(
    title: Text(
      titleText,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white70 
            : Colors.black,
      ),
    ),
    backgroundColor: Theme.of(context).brightness == Brightness.dark 
        ? Colors.black12 
        : Theme.of(context).colorScheme.surface,
  );
}

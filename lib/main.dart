//import 'package:english_words/english_words.dart';
import 'package:cycle_guard_app/data/purchase_info_accessor.dart';
import 'package:cycle_guard_app/pages/feature_testing.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cycle_guard_app/data/user_stats_provider.dart';
import 'package:cycle_guard_app/data/achievements_progress_provider.dart';
import 'package:cycle_guard_app/data/week_history_provider.dart';

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
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserStatsProvider(),
      child: MyApp(),
    ),
  );
}

class OnBoardStart extends StatefulWidget{
  const OnBoardStart({Key?key}) : super(key:key);
  @override
  OnBoardStartState createState() => OnBoardStartState();
}

class OnBoardStartState extends State<OnBoardStart>{
  PageController pageController = PageController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: pageController,
            children: [
              StartPage(pageController),
              LoginPage()
            ],
          ),
          Container(
             alignment: const Alignment(0, .75),
              child: SmoothPageIndicator(
                  controller:pageController,
                  count:2
              ),
          )
        ],
      )
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: ChangeNotifierProvider(
        create: (context) => UserStatsProvider(), // Provide UserStatsProvider
        child: ChangeNotifierProvider(
          create: (context) => AchievementsProgressProvider(), // Provide AchievementsProgressProvider
          child: ChangeNotifierProvider(
            create: (context) => WeekHistoryProvider(), // Provide WeekHistoryProvider
            child: Consumer4<MyAppState, UserStatsProvider, AchievementsProgressProvider, WeekHistoryProvider>(
              builder: (context, appState, userStats, achievementsProgress, weekHistory, child) {
                return MaterialApp(
                  title: 'Cycle Guard App',
                  debugShowCheckedModeBanner: false,
                  themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                  theme: ThemeData(
                    useMaterial3: true,
                    colorScheme: ColorScheme.fromSeed(seedColor: appState.selectedColor),
                  ),
                  darkTheme: ThemeData.dark().copyWith(
                    brightness: Brightness.dark,
                    colorScheme: ColorScheme.fromSeed(seedColor: appState.selectedColor),
                  ),
                  home: OnBoardStart(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  Color selectedColor = Colors.orange;
  bool isDarkMode = false;

  final Map<String, Color> availableThemes = {
    'Indigo': Colors.indigo,
    'Red': Colors.red,
    'Green': Colors.green,
    'Blue': Colors.blue,
    'Purple': Colors.purple,
    'Orange': Colors.orange,
  };

  final Map<String, Color> storeThemes = {
    'Teal': Colors.teal,
    'Lime': Colors.lime,
    'Pink': Colors.pink,
  };

  final Map<String, Color> ownedThemes = {};

  Future<void> fetchOwnedThemes() async {
    final ownedThemeNames = await PurchaseInfo.getOwnedItems();

    for (var themeName in ownedThemeNames) {
      if (storeThemes.containsKey(themeName)) {
        ownedThemes[themeName] = storeThemes[themeName]!; 
      }
    }

    notifyListeners(); 
  }

  void updateThemeColor(Color newColor) {
    selectedColor = newColor;
    notifyListeners(); 
  }

  Future<bool> purchaseTheme(String themeName) async {
    final coins = await CycleCoinInfo.getCycleCoins();
    if (coins < 10) {
      Fluttertoast.showToast(
        msg: "Not enough CycleCoins!",
        backgroundColor: Colors.red,
      );
      return false; // Return false if not enough coins
    }

    final response = await PurchaseInfo.buyItem(themeName);
    switch (response) {
      case BuyResponse.success:
        final color = storeThemes.remove(themeName);
        if (color != null) availableThemes[themeName] = color;
        Fluttertoast.showToast(msg: "Purchase successful!");
        notifyListeners();
        return true; // Return true if purchase is successful
      case BuyResponse.notEnoughCoins:
        Fluttertoast.showToast(msg: "Not enough CycleCoins!");
        return false; // Return false if not enough coins
      case BuyResponse.alreadyOwned:
        Fluttertoast.showToast(msg: "You already own this theme!");
        return false; // Return false if already owned
      default:
        Fluttertoast.showToast(msg: "Purchase failed. Try again later.");
        return false; // Return false for any other failure
    }
  }

  Future<bool> purchaseRocketBoost() async {
    final coins = await CycleCoinInfo.getCycleCoins();
    if (coins < 100) {
      Fluttertoast.showToast(
        msg: "Not enough CycleCoins!",
        backgroundColor: Colors.red,
      );
      return false; // Return false if not enough coins
    }

    final response = await PurchaseInfo.buyItem("Rocket Boost");
    switch (response) {
      case BuyResponse.success:
        await CycleCoinInfo.addCycleCoins(-100);
        Fluttertoast.showToast(msg: "Rocket Boost purchased!");
        notifyListeners();
        return true; // Return true if purchase is successful
      case BuyResponse.notEnoughCoins:
        Fluttertoast.showToast(msg: "Not enough CycleCoins!");
        return false; // Return false if not enough coins
      default:
        Fluttertoast.showToast(msg: "Purchase failed. Try again later.");
        return false; // Return false for any other failure
    }
  }

  void toggleDarkMode(bool isEnabled) {
    isDarkMode = isEnabled;
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
        page = HomePage();
      case 1:
        page = SocialPage();
      case 2:
        page = HistoryPage();
      case 3:
        page = AchievementsPage();
      case 4:
        page = RoutesPage();
      case 5:
        page = StorePage();
      case 6:
        page = SettingsPage();
      case 7:
        page = TestingPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
                SizedBox(
                  height: double.infinity,
                  width: 60.0,
                  child: NavigationRail(
                    backgroundColor: getNavRailBackgroundColor(context),
                    extended: constraints.maxWidth >= 600,
                    destinations: [
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
                      NavigationRailDestination(
                        icon: Icon(Icons.perm_device_info_rounded, color: getIconColor(context),),
                        label: Text('Feature Testing'),
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
        : null,
  );
}

//import 'package:english_words/english_words.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:cycle_guard_app/data/purchase_info_accessor.dart';
import 'package:cycle_guard_app/pages/feature_testing.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cycle_guard_app/data/user_stats_provider.dart';
import 'package:cycle_guard_app/data/achievements_progress_provider.dart';
import 'package:cycle_guard_app/data/week_history_provider.dart';
import 'package:cycle_guard_app/data/trip_history_provider.dart';
import 'package:cycle_guard_app/data/user_settings_accessor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'constants.dart';

// import pages 
import 'pages/start_page.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/social_page.dart';
import 'pages/history_page.dart';
import 'pages/achievements_page.dart';
import 'pages/routes_page.dart';
import 'pages/store_page.dart';
import 'pages/leader_page.dart';
import 'pages/settings_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

//const MethodChannel platform = MethodChannel('com.cycleguard.channel'); // Must match iOS

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  String? apiKey = dotenv.env['API_KEY'];

  if (apiKey == null || apiKey.isEmpty) {
    throw Exception("Google Maps API Key is missing in .env file.");
  }

  print("Google Maps API Key: $apiKey");
  try {
    // Send API Key to iOS
    //await platform.invokeMethod('setApiKey', {"apiKey": apiKey});
    // print("Google Maps API Key sent to iOS successfully");

    // Request Location Permission from iOS
    // await platform.invokeMethod('requestLocationPermission');
    print("Location permission requested");
  } catch (e) {
    print("Error: $e");
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserStatsProvider()),
        ChangeNotifierProvider(create: (context) => AchievementsProgressProvider()),
        ChangeNotifierProvider(create: (context) => WeekHistoryProvider()),
        ChangeNotifierProvider(create: (context) => TripHistoryProvider()), 
      ],
      child: MyApp(),
    ),
  );
  });

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
      child: Consumer5<MyAppState, UserStatsProvider, AchievementsProgressProvider, WeekHistoryProvider, TripHistoryProvider>(
        builder: (context, appState, userStats, achievementsProgress, weekHistory, tripHistory, child) {
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

  void toggleDarkMode(bool isEnabled) async {
    isDarkMode = isEnabled;
    String themeName = _getThemeNameFromColor(selectedColor);
    
    UserSettings updatedSettings = UserSettings(
      darkModeEnabled: isDarkMode,
      currentTheme: themeName,
    );
    

    try {
      await UserSettingsAccessor.updateUserSettings(updatedSettings);
      print("updated user settings: ${await UserSettingsAccessor.getUserSettings()}");
      notifyListeners();
    } catch (e) {
      print("Error updating user settings: $e");
    }
  }

    void updateThemeColor(Color newColor) async {
    selectedColor = newColor;
    String themeName = _getThemeNameFromColor(selectedColor);
    UserSettings updatedSettings = UserSettings(
      darkModeEnabled: isDarkMode,
      currentTheme: themeName,
    );
    try {
      await UserSettingsAccessor.updateUserSettings(updatedSettings);
      print("updated user settings: ${await UserSettingsAccessor.getUserSettings()}");
      notifyListeners();
    } catch (e) {
      print("Error updating user settings: $e");
    }
  }

  String _getThemeNameFromColor(Color color) {
    for (String themeName in availableThemes.keys) {
      if (availableThemes[themeName] == color) {
        return themeName;
      }
    }

    for (String themeName in storeThemes.keys) {
      if (storeThemes[themeName] == color) {
        return themeName;
      }
    }

    return 'Orange';
  }

  Future<void> loadUserSettings() async {
    try {
      UserSettings settings = await UserSettingsAccessor.getUserSettings();
      print("Retrieved Settings: $settings");

      selectedColor = _getColorFromTheme(settings.currentTheme);
      isDarkMode = settings.darkModeEnabled;

      notifyListeners();
    } catch (e, stackTrace) {
      print("Error loading user settings: $e");
      print(stackTrace);
    }
  }

  Color _getColorFromTheme(String theme) {
    return availableThemes[theme] ?? storeThemes[theme] ?? Colors.orange;
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
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 1;

  Color getNavBarColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.onSecondaryFixedVariant
        : Theme.of(context).colorScheme.primary; 
  }

  Color getNavBarBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black12
        : Colors.white; 
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: _getSelectedPage(selectedIndex),
          bottomNavigationBar: CurvedNavigationBar(
            backgroundColor: getNavBarBackgroundColor(context),
            color: getNavBarColor(context),
            animationDuration: Duration(milliseconds: 270),
            index: selectedIndex,
            onTap: (int index) {
              setState(() {
                selectedIndex = index;
              });
            },
            items: [
              Icon(Icons.pedal_bike, color: Theme.of(context).colorScheme.onPrimary),
              Icon(Icons.home, color: Theme.of(context).colorScheme.onPrimary),
              Icon(Icons.person_outline, color: Theme.of(context).colorScheme.onPrimary),
              Icon(Icons.perm_device_info_rounded, color: Theme.of(context).colorScheme.onPrimary),
            ]

          ),
        );
      },
    );
  }

  Widget _getSelectedPage(int index) {
    switch (index) {
      case 0:
        return RoutesPage();
      case 1:
        return HomePage();
      case 2:
        return SocialPage();
      case 3: 
        return TestingPage();
      default:
        return Center(
          child: Text("Page not found"));
    }
  }
}

AppBar createAppBar(BuildContext context, String titleText) {
  bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
  return AppBar(
    iconTheme: IconThemeData(
        color: isDarkMode ? Colors.white70 : null
      ),
    title: Text(
      titleText,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white70 : Colors.black,
      ),
    ),
    backgroundColor: isDarkMode ? Colors.black12 : null,
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 32.0),
        child: SvgPicture.asset(
          'assets/cg_logomark.svg',
          height: 30,
          width: 30,
          colorFilter: ColorFilter.mode( 
            Theme.of(context).brightness == Brightness.dark 
              ? Colors.white70
              : Colors.black,
            BlendMode.srcIn,
          ),
        ),
      )
    ],
  );
}
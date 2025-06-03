//import 'package:english_words/english_words.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:cycle_guard_app/data/purchase_info_accessor.dart';
import 'package:cycle_guard_app/pages/feature_testing.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:cycle_guard_app/providers/social_data_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cycle_guard_app/data/user_stats_provider.dart';
import 'package:cycle_guard_app/data/user_daily_goal_provider.dart';
import 'package:cycle_guard_app/data/achievements_progress_provider.dart';
import 'package:cycle_guard_app/data/week_history_provider.dart';
import 'package:cycle_guard_app/data/trip_history_provider.dart';
import 'package:cycle_guard_app/data/user_settings_accessor.dart';
import 'package:cycle_guard_app/data/user_profile_accessor.dart';
import 'package:cycle_guard_app/data/single_trip_history.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// import pages
import 'pages/start_page.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/social_page.dart';
import 'pages/routes_page.dart';

import 'pages/local_notifications.dart';
import 'package:showcaseview/showcaseview.dart';

//const MethodChannel platform = MethodChannel('com.cycleguard.channel'); // Must match iOS

final ValueNotifier selectedIndexGlobal = ValueNotifier(1);

void main() async {
  // for local notifications
  WidgetsFlutterBinding.ensureInitialized();
  // init notifications
  LocalNotificationService().initNotification();

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

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox("localRideData");

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SocialDataProvider()..reloadAll()),
          ChangeNotifierProvider(create: (context) => UserStatsProvider()),
          ChangeNotifierProvider(
              create: (context) => AchievementsProgressProvider()),
          ChangeNotifierProvider(create: (context) => WeekHistoryProvider()),
          ChangeNotifierProvider(create: (context) => TripHistoryProvider()),
          ChangeNotifierProvider(create: (context) => UserDailyGoalProvider()),
        ],
        child: MyApp(),
      ),
    );
  });
}

class OnBoardStart extends StatefulWidget {
  const OnBoardStart({Key? key}) : super(key: key);
  @override
  OnBoardStartState createState() => OnBoardStartState();
}

class OnBoardStartState extends State<OnBoardStart> {
  PageController pageController = PageController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        PageView(
          controller: pageController,
          children: [StartPage(pageController), LoginPage()],
        ),
      ],
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: Consumer6<
          MyAppState,
          UserStatsProvider,
          AchievementsProgressProvider,
          WeekHistoryProvider,
          TripHistoryProvider,
          UserDailyGoalProvider>(
        builder: (context, appState, userStats, achievementsProgress,
            weekHistory, tripHistory, userDailyGoal, child) {

          appState.setDependencies(
            weekHistoryProvider: weekHistory,
            userGoalProvider: userDailyGoal,
          );

          return ShowCaseWidget(
            enableAutoScroll: true,
            globalTooltipActions: [
              TooltipActionButton(
                backgroundColor: appState.selectedColor,
                type: TooltipDefaultActionType.next,
              ),
              TooltipActionButton(
                backgroundColor: appState.selectedColor,
                type: TooltipDefaultActionType.skip,
                onTap: () {
                  appState.skipTutorial();
                },
              ),
            ],
            builder: (context) => MaterialApp(
              title: 'Cycle Guard App',
              debugShowCheckedModeBanner: false,
              themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              theme: ThemeData(
                useMaterial3: true,
                colorScheme:
                    ColorScheme.fromSeed(seedColor: appState.selectedColor),
              ),
              darkTheme: ThemeData.dark().copyWith(
                brightness: Brightness.dark,
                colorScheme:
                    ColorScheme.fromSeed(seedColor: appState.selectedColor),
              ),
              home: OnBoardStart(),
            ),
          );
        },
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  late WeekHistoryProvider weekHistory;
  late UserDailyGoalProvider userGoals;

  void setDependencies({
    required WeekHistoryProvider weekHistoryProvider,
    required UserDailyGoalProvider userGoalProvider,
  }) {
    weekHistory = weekHistoryProvider;
    userGoals = userGoalProvider;
  }

  final isRouteRecordingActive = ValueNotifier<bool>(false);
  Color selectedColor = Colors.orange;
  String selectedIcon = "icon_default";
  bool isDarkMode = false;
  bool isHomeTutorialActive = false;
  bool isSocialTutorialActive = false;
  bool _tutorialSkipped = false;

  bool isDistanceGoalMet = false;
  bool isTimeGoalMet = false;
  bool isCalorieGoalMet = false;

  bool get tutorialSkipped => _tutorialSkipped;

  void updateGoalStatus() {
    final todayUtcTimestamp = DateTime.utc(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          0,
          0,
          0,
          0,
          0,
        ).millisecondsSinceEpoch ~/
        1000;

    final todayInfo = weekHistory.dayHistoryMap[todayUtcTimestamp] ??
        const SingleTripInfo(
            distance: 0.0,
            calories: 0.0,
            time: 0.0,
            averageAltitude: 0,
            climb: 0);

    double todayDistance = todayInfo.distance;
    double todayCalories = todayInfo.calories;
    double todayTime = todayInfo.time;

    isDistanceGoalMet = todayDistance >= userGoals.dailyDistanceGoal;
    isCalorieGoalMet = todayCalories >= userGoals.dailyCaloriesGoal;
    isTimeGoalMet = todayTime >= userGoals.dailyTimeGoal;
  }

  void startRouteRecording() {
    isRouteRecordingActive.value = true;
    notifyListeners(); // Optional if you're only using ValueNotifier
  }

  void stopRouteRecording() {
    isRouteRecordingActive.value = false;
    notifyListeners(); // Optional if you're only using ValueNotifier
  }

  final Map<String, Color> availableThemes = {
    'Yellow': Colors.yellow,
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
    'Cyan': Colors.cyan,
    'Indigo': Colors.indigo,
  };

  final Map<String, Color> ownedThemes = {};

  final List<String> availableIcons = ['icon_default'];
  final List<String> storeIcons = [
    'icon_1_F',
    'icon_1_M',
    'icon_2_F',
    'icon_2_M',
    'bear',
    'panda',
    'pig',
    'cow',
    'tiger',
    'Cat',
    'Dog',
    'Elephant',
    'Gunrock',
    'Koala',
    'Penguin',
    'Rabbit',
    'Stitch'
  ];
  final List<String> ownedIcons = [];





  Future<void> fetchOwnedThemes() async {
    final ownedThemeNames =
        (await PurchaseInfoAccessor.getPurchaseInfo()).themesOwned;

    for (var themeName in ownedThemeNames) {
      if (storeThemes.containsKey(themeName)) {
        ownedThemes[themeName] = storeThemes[themeName]!;
      }
    }

    notifyListeners();
  }

  void skipTutorial() {
    isHomeTutorialActive = false;
    isSocialTutorialActive = false;
    _tutorialSkipped = true;
    notifyListeners();
  }

  Future<void> loadUserProfile() async {
    final profile = await UserProfileAccessor.getOwnProfile();
    isHomeTutorialActive = profile.isNewAccount;
    notifyListeners();
  }

  void enableTutorial() {
    isHomeTutorialActive = true;
    _tutorialSkipped = false;
    notifyListeners();
  }

  Future<void> fetchOwnedIcons() async {
    final ownedIconNames =
        (await PurchaseInfoAccessor.getPurchaseInfo()).iconsOwned;

    for (var iconName in ownedIconNames) {
      if (storeIcons.contains(iconName) && !ownedIcons.contains(iconName)) {
        ownedIcons.add(iconName);
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
      print(
          "updated user settings: ${await UserSettingsAccessor.getUserSettings()}");
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
      print(
          "updated user settings: ${await UserSettingsAccessor.getUserSettings()}");
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

    final response = await PurchaseInfoAccessor.buyTheme(themeName);
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

  Future<bool> purchaseIcon(String iconName) async {
    final coins = await CycleCoinInfo.getCycleCoins();
    if (coins < 10) {
      Fluttertoast.showToast(
        msg: "Not enough CycleCoins!",
        backgroundColor: Colors.red,
      );
      return false;
    }

    final response = await PurchaseInfoAccessor.buyIcon(iconName);
    switch (response) {
      case BuyResponse.success:
        if (storeIcons.contains(iconName)) {
          storeIcons.remove(iconName);
          availableIcons.add(iconName);
          ownedIcons.add(iconName);
        }
        Fluttertoast.showToast(msg: "Icon purchased successfully!");
        notifyListeners();
        return true;
      case BuyResponse.notEnoughCoins:
        Fluttertoast.showToast(msg: "Not enough CycleCoins!");
        return false;
      case BuyResponse.alreadyOwned:
        Fluttertoast.showToast(msg: "You already own this icon!");
        return false;
      default:
        Fluttertoast.showToast(msg: "Purchase failed. Try again later.");
        return false;
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

    final response = await PurchaseInfoAccessor.buyMisc("Rocket Boost");
    switch (response) {
      case BuyResponse.success:
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
    Color selectedColor = Provider.of<MyAppState>(context).selectedColor;
    return Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.onSecondaryFixedVariant
        : selectedColor;
  }

  Color getNavBarBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black12
        : Theme.of(context).colorScheme.surface;
  }


  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedIndexGlobal,
      builder: (context, val, child) {
        final appState = Provider.of<MyAppState>(context);

        return ValueListenableBuilder(
          valueListenable: appState.isRouteRecordingActive,
          builder: (context, isRecording, _) {
            return Scaffold(
              body: _getSelectedPage(selectedIndexGlobal.value),
              // Only show the navigation bar when NOT recording
              bottomNavigationBar: isRecording
                  ? null
                  : CurvedNavigationBar(
                      backgroundColor: getNavBarBackgroundColor(context),
                      color: getNavBarColor(context),
                      animationDuration: Duration(milliseconds: 270),
                      index: selectedIndexGlobal.value,
                      onTap: (int index) {
                        setState(() {
                          selectedIndex = index;
                          selectedIndexGlobal.value = index;
                        });
                      },
                      items: [
                        Icon(Icons.pedal_bike,
                            color: Theme.of(context).colorScheme.onPrimary),
                        Icon(Icons.home,
                            color: Theme.of(context).colorScheme.onPrimary),
                        Icon(Icons.person_outline,
                            color: Theme.of(context).colorScheme.onPrimary),
                        // Icon(Icons.perm_device_info_rounded,
                        //     color: Theme.of(context).colorScheme.onPrimary),
                      ],
                    ),
            );
          }
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
      // case 3:
      //   return TestingPage();
      default:
        return Center(child: Text("Page not found"));
    }
  }
}

AppBar createAppBar(BuildContext context, String titleText) {
  bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
  return AppBar(
    iconTheme: IconThemeData(color: isDarkMode ? Colors.white70 : null),
    title: Text(
      titleText,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white70 : Colors.black,
      ),
    ),
    backgroundColor: isDarkMode
        ? Theme.of(context).colorScheme.onSecondaryFixedVariant
        : Theme.of(context).colorScheme.surfaceContainer,
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 32.0),
        child: GestureDetector(
          onTap: () {
            selectedIndexGlobal.value = 1;
            Navigator.pushAndRemoveUntil(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    MyHomePage(),
                transitionDuration: Duration(milliseconds: 500),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  var offsetAnimation = Tween<Offset>(
                    begin: Offset(0.0, -1.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  ));

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
              ),
              (_) => false,
            );
          },
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
        ),
      )
    ],
  );
}

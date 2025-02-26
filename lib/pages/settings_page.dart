import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:intl/intl.dart';
import 'package:cycle_guard_app/data/user_stats_accessor.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int accountCreationTime = 0;
  @override
  void initState() {
    super.initState();
    // Fetch owned themes when the settings page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MyAppState>(context, listen: false).fetchOwnedThemes();
    });
    _getUserStats();
  }

  void _getUserStats() async {
    final userStats = await UserStatsAccessor.getUserStats();
    if (mounted) {
      setState(() {
        accountCreationTime = userStats.accountCreationTime;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createAppBar(context, 'Settings'),
      body: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Selection
              Text(
                'Select Theme Color:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 10),
              Consumer<MyAppState>(
                builder: (context, appState, child) {
                  return DropdownButton<Color>(
                    value: appState.selectedColor,
                    items: [
                      ...appState.availableThemes.entries.map((entry) {
                        return DropdownMenuItem<Color>(
                          value: entry.value,
                          child: Row(
                            children: [
                              Container(width: 24, height: 24, color: entry.value),
                              SizedBox(width: 15),
                              Text(entry.key),
                            ],
                          ),
                        );
                      }),
                      ...appState.ownedThemes.entries.map((entry) {
                        return DropdownMenuItem<Color>(
                          value: entry.value,
                          child: Row(
                            children: [
                              Container(width: 24, height: 24, color: entry.value),
                              SizedBox(width: 15),
                              Text(entry.key),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (newColor) {
                      if (newColor != null) {
                        appState.updateThemeColor(newColor);
                      }
                    },
                  );
                },
              ),
              SizedBox(height: 10),
              Consumer<MyAppState>(
                builder: (context, appState, child) {
                  return SwitchListTile(
                    title: Text(
                      'Dark Mode',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    value: appState.isDarkMode,
                    onChanged: (bool value) {
                      appState.toggleDarkMode(value);
                    },
                  );
                },
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    final appState = Provider.of<MyAppState>(context, listen: false);
                    appState.updateThemeColor(Colors.orange);
                    appState.toggleDarkMode(false);
                  },
                  style: ElevatedButton.styleFrom(elevation: 10),
                  child: Text('Reset Default Settings'),
                ),
              ),
              SizedBox(height: 20),
              // Display account creation time and duration since account creation
              Consumer<MyAppState>(
                builder: (context, appState, child) {
                  DateTime creationDate = DateTime.fromMillisecondsSinceEpoch(accountCreationTime * 1000);
                  Duration duration = DateTime.now().difference(creationDate);

                  String formattedCreationDate = DateFormat('yyyy-MM-dd').format(creationDate);
                  String durationString = '${duration.inDays} days, ${duration.inHours % 24} hours, ${duration.inMinutes % 60} minutes';

                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Created On: $formattedCreationDate',
                        ),
                        Text(
                          'Member for: $durationString',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
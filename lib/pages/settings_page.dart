import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class SettingsPage extends StatelessWidget {
  final List<Map<String, dynamic>> themeOptions = [
    {'name': 'Indigo', 'color': Colors.indigo},
    {'name': 'Red', 'color': Colors.red},
    {'name': 'Green', 'color': Colors.green},
    {'name': 'Blue', 'color': Colors.blue},
    {'name': 'Purple', 'color': Colors.purple},
    {'name': 'Orange', 'color': Colors.orange},
  ];

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
              // Themes
              Text(
                'Select Theme Color:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 10),
              Consumer<MyAppState>(
                builder: (context, appState, child) {
                  return DropdownButton<Color>(
                    value: appState.selectedColor,
                    items: themeOptions.map((theme) {
                      return DropdownMenuItem<Color>(
                        value: theme['color'],
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              color: theme['color'],
                            ),
                            SizedBox(width: 15),
                            Text(theme['name']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newColor) {
                      if (newColor != null) {
                        appState.updateThemeColor(newColor);
                      }
                    },
                  );
                },
              ),
              // Dark Mode
              SizedBox(height:10),
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
              // Reset Button
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    final appState = Provider.of<MyAppState>(context, listen: false);
                    appState.updateThemeColor(Colors.indigo);
                    appState.toggleDarkMode(false);
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 10,
                  ),
                  child: Text('Reset Default Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
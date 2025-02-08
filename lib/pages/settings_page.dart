import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Import MyAppState

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
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          )
        ),
      ),
      body: Container(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
            ],
          ),
        ),
      ),
    );
  }
}
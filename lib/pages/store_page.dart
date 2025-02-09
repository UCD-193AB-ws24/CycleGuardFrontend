import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class StorePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<MyAppState>(context);

    return Scaffold(
      appBar: createAppBar(context, 'Store'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  "New Color Themes",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text("10 CycleCoins"),
                ElevatedButton(
                  onPressed: appState.storeThemes.isNotEmpty
                      ? () => _showThemeMenu(context, appState)
                      : null, // Disable if no themes left
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  ),
                  child: Text("Buy"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeMenu(BuildContext context, MyAppState appState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Choose a Theme",
            style: TextStyle(
              color: Colors.black
            )
          ),
          content: appState.storeThemes.isNotEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: appState.storeThemes.map((theme) {
                    return ListTile(
                      leading: Icon(Icons.color_lens, color: theme['color']),
                      title: Text(theme['name']),
                      onTap: () {
                        appState.purchaseTheme(theme); // Move to settings
                        Navigator.pop(context); // Close the dialog
                      },
                    );
                  }).toList(),
                )
              : Text("No more themes available!"),
        );
      },
    );
  }
}

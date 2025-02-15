import 'package:cycle_guard_app/data/purchase_info_accessor.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class StorePage extends StatelessWidget {
  void _addCycleCoins() async {
    print("Adding...");
    final newCoins = await CycleCoinInfo.addCycleCoins(5);

    Fluttertoast.cancel();
    Fluttertoast.showToast(
        msg: "You now have $newCoins CycleCoins!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 5,
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  void _getCycleCoins() async {
    final newCoins = await CycleCoinInfo.getCycleCoins();

    Fluttertoast.cancel();
    Fluttertoast.showToast(
        msg: "You have $newCoins CycleCoins!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 5,
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  void _getOwnedItems() async {
    print("Showing owned items...");
    final items = await PurchaseInfo.getOwnedItems();

    Fluttertoast.cancel();
    Fluttertoast.showToast(
        msg: "Your owned items: $items",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 5,
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                  ),
                  onPressed: _getCycleCoins,
                  child: Text("Temp: Display current CycleCoin count"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                  ),
                  onPressed: _addCycleCoins,
                  child: Text("Temp: Add 5 CycleCoins to account"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                  ),
                  onPressed: _getOwnedItems,
                  child: Text("Temp: Show owned items"),
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

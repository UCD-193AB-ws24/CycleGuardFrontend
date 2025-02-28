import 'package:cycle_guard_app/data/purchase_info_accessor.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:cycle_guard_app/pages/rocket_screen.dart';
import '../main.dart';

class StorePage extends StatelessWidget {
  void _addCycleCoins() async {
    print("Adding...");
    final newCoins = await CycleCoinInfo.addCycleCoins(100);

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
                  onPressed: () => _buyRocketBoost(context, appState),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  ),
                  child: Text("Buy Rocket Boost (100 CycleCoins)"),
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

  void _showThemeMenu(BuildContext context, MyAppState appState) async {
    await appState.fetchOwnedThemes();

    final purchasableThemes = Map.fromEntries(
      appState.storeThemes.entries.where((entry) => !appState.ownedThemes.containsKey(entry.key))
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Choose a Theme",
            style: TextStyle(color: Colors.black),
          ),
          content: purchasableThemes.isNotEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: purchasableThemes.entries.map((entry) {
                    return ListTile(
                      leading: Icon(Icons.color_lens, color: entry.value),
                      title: Text(entry.key),
                      onTap: () async {
                        final success = await appState.purchaseTheme(entry.key);
                        if (success) {
                          Navigator.pop(context);
                        }
                      },
                    );
                  }).toList(),
                )
              : Text("No more themes available!"),
        );
      },
    );
  }

  void _buyRocketBoost(BuildContext context, MyAppState appState) async {
    if (await appState.purchaseRocketBoost()) {
          // Navigate to the rocket screen to show the animation
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AnimatedButtonScreen()),
      );

      // Wait for 3 seconds to let the animation play
      await Future.delayed(const Duration(seconds: 3));

      // After the animation, return to the store page
      Navigator.pop(context);
    }
  }
}

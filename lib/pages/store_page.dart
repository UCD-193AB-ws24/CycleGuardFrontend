import 'package:cycle_guard_app/data/purchase_info_accessor.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:cycle_guard_app/pages/rocket_screen.dart';
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

  Future<int> _getCycleCoins(BuildContext context) async {
    return await CycleCoinInfo.getCycleCoins();
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
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 60),
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
                    SizedBox(height: 20), // Adds space between the two sections
                    Text(
                      "Rocket Boost",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text("100 CycleCoins"),
                    ElevatedButton(
                      onPressed: () => _buyRocketBoost(context, appState),
                      style: ElevatedButton.styleFrom(
                        elevation: 5,
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                      ),
                      child: Text("Buy"),
                    ),
                    SizedBox(height: 20), 
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
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: FutureBuilder<int>(
                future: _getCycleCoins(context),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Row(
                      children: [
                        Icon(Icons.monetization_on, color: Colors.amber),
                        SizedBox(width: 5),
                        Text(
                          'Loading...',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                        ),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 5),
                        Text(
                          'Error!',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Icon(Icons.monetization_on, color: Colors.amber),
                        SizedBox(width: 5),
                        Text(
                          '${snapshot.data} CycleCoins',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                        ),
                      ],
                    );
                  }
                },
              ),
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
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AnimatedButtonScreen()),
      );

      if (result == 'done') {
        Navigator.pop(context);
      }

    }
  }
}

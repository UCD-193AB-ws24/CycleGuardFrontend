import 'package:cycle_guard_app/data/health_info_accessor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';

class TestingPage extends StatelessWidget {
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final ageController = TextEditingController();

  Widget _numberField(TextEditingController controller, String hint) => TextField(
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      border: OutlineInputBorder(),
    ),
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
    textInputAction: TextInputAction.done,
  );
  
  void _closeMenu(BuildContext context) {
    Navigator.pop(context);
  }

  Future<void> _updateHealthData(BuildContext context) async {
    final height = heightController.text;
    final weight = weightController.text;
    final age = ageController.text;

    await HealthInfoAccessor.setHealthInfo(height, weight, age);
    _closeMenu(context);
  }

  Future<void> _getHealthData() async {
    final healthData = await HealthInfoAccessor.getHealthInfo();
    final height = healthData.heightInches;
    final weight = healthData.weightPounds;
    final age = healthData.ageYears;
    heightController.text = "$height";
    weightController.text = "$weight";
    ageController.text = "$age";
  }

  void _showEnterHealthInfoMenu(BuildContext context, MyAppState appState) async {
    await _getHealthData();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
              "Change fitness info",
              style: TextStyle(
                  color: Colors.black
              )
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _numberField(heightController, "Height (inches)"),
              const SizedBox(height:24),
              _numberField(weightController, "Weight (pounds)"),
              const SizedBox(height:24),
              _numberField(ageController, "Age (years)"),
              const SizedBox(height:24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 5,
                ),
                onPressed: () => _updateHealthData(context),
                child: Text("Update health info"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 5,
                ),
                onPressed: () => _closeMenu(context),
                child: Text("Exit without saving"),
              ),
            ]
          )
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<MyAppState>(context);
    return Scaffold(
      appBar: createAppBar(context, 'Accessor Function Testing'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => _showEnterHealthInfoMenu(context, appState),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  ),
                  child: Text("Set fitness info"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
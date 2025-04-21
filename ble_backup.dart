import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../auth/dim_util.dart';

class BluetoothController extends GetxController {
  static BluetoothController get to => Get.find();
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<List<ScanResult>> scanDevices() async {
    await requestBluetoothPermissions();
    PermissionStatus bluetoothScanStatus = await Permission.bluetoothScan.status;
    await FlutterBluePlus.turnOn();

    try {
      print("Starting scan");
      print("State:");
      print((await FlutterBluePlus.adapterState.first).name);

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 1));
      List<ScanResult> scanResults = [];
      var subscription = FlutterBluePlus.onScanResults.listen((results) {
        // print("Scan complete");
        // print(results);
        scanResults = results;
      });

      await FlutterBluePlus.isScanning.where((e)=>e==false).first;
      await subscription.cancel();

      print("Stopped scanning");

      // final res = await FlutterBluePlus.scanResults.last;
      print(scanResults);
      print(scanResults.length);

      return scanResults;
    } catch(e) {
      e.printError();
      return [];
    }
    
    
  //   if (bluetoothScanStatus.isGranted) {
  //   // if (true) {
  //     FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

  //     // Listen to scan results
  //     FlutterBluePlus.scanResults.listen((results) {
  //       print("Scan Results: $results");
  //     });

  //     await Future.delayed(const Duration(seconds: 5));
  //     FlutterBluePlus.stopScan();
  //   } else {
  //     print("Bluetooth scan permission is not granted");
  //   }
  }
}

Future<void> _connectAndRead(BluetoothDevice device) async {

  if(!device.isConnected) await device.connect();
  List<BluetoothService> services = await device.discoverServices();

  // theres only one table inside the ble lol
  BluetoothCharacteristic? targetCharacteristic;
  for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
          targetCharacteristic = characteristic;

      }
  }


  if (targetCharacteristic != null) {
    // Read the value from the known characteristic
    var value = await targetCharacteristic.read();
    print('Read value from characteristic: $value');
  } else {
    print('Characteristic not found');
  }

}

void showCustomDialog(BuildContext context) async {
  await requestBluetoothPermissions();
  Get.put(BluetoothController());
  var scanResults = await BluetoothController.to.scanDevices();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        contentPadding: EdgeInsets.symmetric(horizontal: 100,vertical: 10),
        title: Text('Select Your Helmet'),
        content:
        Container(
          height: 500,
          width: 300,
          padding: EdgeInsets.symmetric(horizontal: 4,vertical: 5),
          child: ListView.builder(
            itemCount: scanResults.length,
            itemBuilder: (context, index) {
              final data = scanResults[index];
              // print(data);
              // return Text("INDEX $index");
              return Card(
                elevation: 2,
                child: ListTile(
                  title: Text(data.device.platformName),
                  subtitle: Text(data.device.remoteId.str),
                  trailing: Text(data.rssi.toString()),
                  onTap: () => _connectAndRead(data.device),
                ),
              );
            },
          )
        ),
        actions: <Widget>[
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                // Get.put(BluetoothController());
                await BluetoothController.to.scanDevices();
              },
              child: Text(
                "Scan",
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    },
  );
}


Future<void> requestBluetoothPermissions() async {
  PermissionStatus bluetoothPermissionStatus = await Permission.bluetooth.request();
  PermissionStatus bluetoothConnectPermissionStatus = await Permission.bluetoothConnect.request();
  PermissionStatus bluetoothScanPermissionStatus = await Permission.bluetoothScan.request();
  PermissionStatus locationPermissionStatus = await Permission.locationWhenInUse.request();

  print(bluetoothPermissionStatus.isGranted);
  print(bluetoothConnectPermissionStatus.isGranted);
  print(bluetoothScanPermissionStatus.isGranted);
  print(locationPermissionStatus.isGranted);

  if (bluetoothPermissionStatus.isGranted &&
      bluetoothConnectPermissionStatus.isGranted &&
      bluetoothScanPermissionStatus.isGranted &&
      locationPermissionStatus.isGranted) {
    print("All required permissions granted");
  } else {
    print("Required permissions not granted");
    // openAppSettings();
  }
}

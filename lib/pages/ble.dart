import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothController extends GetxController {
  static BluetoothController get to => Get.find();
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> scanDevices() async {
    await requestBluetoothPermissions();
    PermissionStatus bluetoothScanStatus = await Permission.bluetoothScan.status;
    if (bluetoothScanStatus.isGranted) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        print("Scan Results: $results");
      });

      await Future.delayed(const Duration(seconds: 5));
      FlutterBluePlus.stopScan();
    } else {
      print("Bluetooth scan permission is not granted");
    }
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
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Select Your Helmet'),
        content: Container(
          height: 300, // Fixed height for the container
          width: 300, // Fixed width for the container
          child: StreamBuilder<List<ScanResult>>(
            stream: Get.put(BluetoothController()).scanResults,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data![index];
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
                );
              } else {
                return const Center(child: Text("No devices found"));
              }
            },
          ),
        ),
        actions: <Widget>[
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () async {
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

  if (bluetoothPermissionStatus.isGranted &&
      bluetoothConnectPermissionStatus.isGranted &&
      bluetoothScanPermissionStatus.isGranted &&
      locationPermissionStatus.isGranted) {
    print("All required permissions granted");
  } else {
    print("Required permissions not granted");
    openAppSettings();
  }
}

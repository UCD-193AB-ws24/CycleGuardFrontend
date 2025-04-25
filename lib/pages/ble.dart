import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../auth/dim_util.dart';
import 'dart:typed_data';

import 'dart:io' show Platform;


class BluetoothController extends GetxController {
  static BluetoothController get to => Get.find();
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> scanDevices() async {
    await requestBluetoothPermissions();

    if ((await FlutterBluePlus.adapterState.first) != BluetoothAdapterState.on) {
      if (Platform.isAndroid) {
        PermissionStatus status = await Permission.bluetoothScan.status;
        if (!status.isGranted) {
          print("Android: Bluetooth permission is not granted");
          return;
        }
        await FlutterBluePlus.turnOn();
      } else if (Platform.isIOS) {
        try {
          print("iOS detected - beginning prelimenary scan to turn on bluetooth");
          await FlutterBluePlus.startScan(timeout: const Duration(seconds: 1));
          await FlutterBluePlus.scanResults.first;

        } catch (e) {}
          await Future.delayed(const Duration(seconds: 1));
      }
    }

    try {
      print("Starting scan");
      print("State:");
      print((await FlutterBluePlus.adapterState.first).name);

      FlutterBluePlus.startScan(timeout: const Duration(seconds: 1));

      // print(await FlutterBluePlus.scanResults.first);
    } catch(e) {
      e.printError();
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

  print("Connected to ${device.advName}: $device");
  List<BluetoothService> services = await device.discoverServices();

  // theres only one table inside the ble lol
  BluetoothCharacteristic? targetCharacteristic;
  for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
          // print(characteristic);
          var cur = await characteristic.read();
          print(cur);
          int bitData = convertTo32Bit(cur);


          var byteData = ByteData(4);
          byteData.setInt32(0, bitData);
          print(byteData.getFloat32(0));

          targetCharacteristic = characteristic;

      }
  }

  // longitude, latitude, speed, uv


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
        contentPadding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
        title: Text('Select Your Helmet'),
        content: Container(

          height: 1000,
          width: 1000,
          padding: EdgeInsets.symmetric(horizontal: 4,vertical: 5),
          child: StreamBuilder<List<ScanResult>>(
            
            stream: Get.put(BluetoothController()).scanResults,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return ListView.builder(
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
                Get.put(BluetoothController());
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

int convertTo32Bit(List<int> list) {
  int res = 0;
  for (int i=0; i<list.length; i++) {
    int cur = list[i];
    // res |= cur<<(8*(list.length-1 - i));
    res |= cur<<(8*i);
  }

  print(res.toRadixString(2).padLeft(32, '0'));
  return res;
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

// class BluetoothData {
//   // longitude, latitude, speed, uv
//   double longitude, latitude, speed;
//   int uv;
//   BluetoothData(List<BluetoothService> services) {
//     for (BluetoothService service in services) {
//       for (BluetoothCharacteristic characteristic in service.characteristics) {
//           print(characteristic);
//           var cur = await characteristic.read();
//           print(cur);
//           print(convertTo32Bit(cur));
//           targetCharacteristic = characteristic;

//       }
//     }
//   }
// }
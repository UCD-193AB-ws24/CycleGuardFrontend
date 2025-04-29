import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../auth/dim_util.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:io' show Platform;


class BluetoothController extends GetxController {
  static BluetoothController get to => Get.find();
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;



  Future<void> scanDevices() async {
    print("Scanning devices...");
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
Timer? timer;

bool _isConnected = false;
bool isConnected() => _isConnected;

Future<void> _connectAndRead(BluetoothDevice device, Function(BluetoothData) callback) async {
  _isConnected = false;
  if(!device.isConnected) await device.connect();

  _isConnected = true;
  print("Connected to ${device.advName}: $device");
  if (timer != null) timer!.cancel();
  timer = Timer.periodic(Duration(seconds: 1), (Timer timer) async {
      BluetoothData data = await BluetoothData.fromBluetooth(device);
      callback(data);
    }
  );
}

Future<void> showCustomDialog(BuildContext context, Function(BluetoothData) callback) async {
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
                final filteredScan = snapshot.data!.where((scanResult) => 
                  scanResult.device.platformName.contains("CycleGuard")).toList(growable: false);
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredScan.length,
                  itemBuilder: (context, index) {
                    final data = filteredScan[index];
                    return Card(

                      elevation: 2,
                      child: ListTile(
                        title: Text(data.device.platformName),
                        subtitle: Text(data.device.remoteId.str),
                        iconColor: data.device.isConnected ? Colors.white : Colors.grey,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(data.rssi.toString()),
                            const SizedBox(width: 8),
                            if (data.device.isConnected)
                              ElevatedButton(
                                onPressed: () async {
                                  if (timer != null) {
                                    timer!.cancel();
                                    timer = null;
                                    _isConnected = false;
                                  }
                                  await data.device.disconnect();
                                  print("Device disconnected: ${data.device.platformName}");
                                },
                                child: Text("Disconnect"),
                              ),
                          ],
                        ),
                        onTap: () => _connectAndRead(data.device, callback),
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

  // print(res.toRadixString(2).padLeft(32, '0'));
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


class BluetoothData {
  // longitude, latitude, speed, uv
  final double longitude, latitude, speed, uv;

  BluetoothData(this.longitude, this.latitude, this.speed, this.uv);
  static Future<BluetoothData> fromBluetooth(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    List<double> resData = [0, 0, 0, 0];

    for (BluetoothService service in services) {
      var characteristics = service.characteristics;
      for (int i=0; i<characteristics.length; i++) {
        var characteristic = characteristics[i];
        var cur = await characteristic.read();
        
        int bitData = convertTo32Bit(cur);
        var byteData = ByteData(4);
        byteData.setInt32(0, bitData);
        resData[i] = byteData.getFloat32(0);
      }
    }

    // double longitude, latitude, speed, uv;
    double longitude = resData[0];
    double latitude = resData[1];
    double speed = resData[2];
    double uv = resData[3];

    return BluetoothData(longitude, latitude, speed, uv);
  }

  @override
  String toString() {
    return 'BluetoothData{longitude: $longitude, latitude: $latitude, speed: $speed, uv: $uv}';
  }
}
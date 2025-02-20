import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:location/location.dart';

//import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
class RoutesPage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Routes Page'));
  }

  @override
  State<StatefulWidget> createState() => mapState();
}

class mapState extends State<RoutesPage>{
  late GoogleMapController mapController;
  final locationController = Location();
  late LatLng center = new LatLng(0,0);

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async => await fetchLocationUpdates());
  }

  void onMapCreated(GoogleMapController controller){
    mapController=controller;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: GoogleMap(
          initialCameraPosition: CameraPosition(
              target: center,
              zoom: 11.0)
      ),
    );
  }
  Future<void> fetchLocationUpdates() async{
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await locationController.serviceEnabled();
    if(serviceEnabled){
      serviceEnabled = await locationController.requestService();
    }else{
      return;
    }

    permissionGranted = await locationController.hasPermission();
    if(permissionGranted == PermissionStatus.denied){
      permissionGranted = await locationController.requestPermission();
      if(permissionGranted!= PermissionStatus.granted){
        return;
      }
    }
    locationController.onLocationChanged.listen((center){});
    if(center.latitude != null && center.longitude != null){
      setState(() {
        center = LatLng(
            center.latitude,
            center.longitude);
      });
    }
  }

}
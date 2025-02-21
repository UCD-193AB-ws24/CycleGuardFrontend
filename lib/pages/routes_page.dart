import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

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
  LatLng? center;

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async => await fetchLocationUpdates());
  }

  void onMapCreated(GoogleMapController controller){
    mapController=controller;
  }

  Widget mainMap() => GoogleMap(
    initialCameraPosition: CameraPosition(
        target: center!,
        zoom: 13.0),
    markers: {
      Marker(
          markerId: MarkerId("centerMarker"),
          icon: BitmapDescriptor.defaultMarker,
          position: center!
      ),
    },
  );

  Widget locationTextInput() => Positioned(
    top: 100.0,
    left: 50.0,
    right: 75.0,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 1.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(), // Background with some opacity
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.location_pin),
          hintText: 'Search here',
          border: InputBorder.none,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Stack(
        children: [
          center == null ? const Center(child: CircularProgressIndicator()) : mainMap(),
          locationTextInput()
        ],

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
    locationController.onLocationChanged.listen((currentLocation){
      if(currentLocation.latitude!=null && currentLocation.longitude!=null){
        setState(() {
          center = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          print(center);
        });
      }
    });
  }

}
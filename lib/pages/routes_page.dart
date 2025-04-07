import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import '../auth/key_util.dart';
import '../auth/dim_util.dart';

ApiService apiService = ApiService();
class RoutesPage extends StatefulWidget {

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Routes Page'));
  }
  @override
  State<StatefulWidget> createState() => mapState();
}

class mapState extends State<RoutesPage> {

  List<dynamic> listForSuggestions = [];
  Map<PolylineId,Polyline> polylines = {};
  late GoogleMapController mapController;
  bool dstFound = false;
  final locationController = Location();
  final TextEditingController textController = TextEditingController();
  LatLng? center;
  LatLng? dest = LatLng(0.0, 0.0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((
        _) async => await fetchLocationUpdates());
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }


  Widget mainMap() =>
      GoogleMap(
        onMapCreated: onMapCreated,
        initialCameraPosition: CameraPosition(
            target: center!,
            zoom: 13.0),
        markers: {
          Marker(
              markerId: MarkerId("centerMarker"),
              icon: BitmapDescriptor.defaultMarker,
              position: center!
          ),
          Marker(
            markerId: MarkerId("destinationMarker"),
              icon: BitmapDescriptor.defaultMarker,
              position: dest!,
              visible: dstFound ? true : false
          )
        },
        polylines: Set<Polyline>.of(polylines.values),
      );

  Widget locationTextInput() =>
      Positioned(
        top: DimUtil.safeHeight(context)*1/10,
        width: DimUtil.safeWidth(context)*9.5/10,
        right: DimUtil.safeWidth(context)*.2/10,

        child: Container(
          margin:EdgeInsets.symmetric(horizontal: 30.0, vertical: 1.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              GooglePlaceAutoCompleteTextField(
                boxDecoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8.0,
                      spreadRadius: 2.0,
                      offset: Offset(0, 4), // Position of the shadow
                    ),
                  ],
                ),
                textEditingController: textController,
                googleAPIKey: apiService.getGoogleApiKey(),
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (prediction) {
                  dest = LatLng(double.parse(prediction.lat!), double.parse(prediction.lng!));
                  LatLngBounds bounds = getBounds();
                  mapController.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds,50), // 100 is padding around the bounds
                  );
                  dstFound = true;
                  getPolylinePoints().then((coordinates)=>{
                    generatePolyLines(coordinates)
                  });
                },
                itemClick: (prediction) {
                  // This callback is triggered when a place is selected from the list
                  textController.text = prediction.description!;
                  print(dest);
                },
              ),
            ],
          ),
        ),
      );



  LatLngBounds getBounds(){
    double latMin = min(center!.latitude, dest!.latitude);
    double lonMin = min(center!.longitude, dest!.longitude);
    double latMax = max(center!.latitude, dest!.latitude);
    double lonMax = max(center!.longitude, dest!.longitude);

    return LatLngBounds(southwest: LatLng(latMin, lonMin), northeast: LatLng(latMax, lonMax));
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Stack(
        children: [
          center == null ? const Center(child: CircularProgressIndicator()) : mainMap(),
          locationTextInput(),

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
          centerCamera(center!);
        });
      }
    });
  }

  Future<void> centerCamera(LatLng pos) async{
    CameraPosition newCameraPos = CameraPosition(
      target: pos,
      zoom:13
    );
    await mapController.animateCamera(
        CameraUpdate.newCameraPosition(newCameraPos));
  }

  Future<List<LatLng>> getPolylinePoints() async{
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
    googleApiKey: apiService.getGoogleApiKey(),
    request: PolylineRequest(origin: PointLatLng(center!.latitude, center!.longitude),
        destination: PointLatLng(dest!.latitude, dest!.longitude),
        mode: TravelMode.bicycling));
    if(result.points.isNotEmpty){
      result.points.forEach((PointLatLng point){
        polylineCoordinates.add(LatLng(point.latitude,point.longitude));
      });
    }
    return polylineCoordinates;

  }
  void generatePolyLines(List<LatLng> polylineCoordinates) async{
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.blue,
        points: polylineCoordinates,
         width: 6
    );
    setState(() {
      polylines[id] = polyline;
    });
  }

}
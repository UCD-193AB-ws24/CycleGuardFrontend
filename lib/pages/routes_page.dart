import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' hide LocationAccuracy;
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
  MapType currentMapType = MapType.terrain;
  Map<PolylineId, Polyline> polylines = {};
  late GoogleMapController mapController;
  bool dstFound = false;
  bool offCenter = true;
  bool mapType = true;
  bool showStartButton = false;
  bool showStopButton = false;
  bool recordingDistance = false;
  final stopwatch = Stopwatch();
  int rideDuration = 0;

  final locationController = Location();
  final TextEditingController textController = TextEditingController();
  LatLng? center;
  LatLng? dest = LatLng(0.0, 0.0);
  LatLng? prevLoc;
  double totalDist = 0;
  double? heading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchLocationUpdates();
      Geolocator.getPositionStream(
        locationSettings: LocationSettings(accuracy:LocationAccuracy.high),
      ).listen((Position position) {
        heading = position.heading;
      });
    });
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void changeMapType() {
    setState(() {
      currentMapType = currentMapType == MapType.normal
          ? MapType.terrain
          : MapType.normal;
    });
  }

  void recenterMap() {
    if (!offCenter) offCenter = true;
  }

  void startDistanceRecord() {
    setState(() {
      showStartButton = false;
      showStopButton = true;
      recordingDistance = true;
      offCenter = true;
    });
    stopwatch.start();
  }

  void stopDistanceRecord() {
    setState(() {
      showStartButton = true;
      showStopButton = false;
      recordingDistance = false;

    });
    centerCamera(center!);
    totalDist = 0;
    rideDuration = 0;
  }

  void calcDist() {
    Duration time = stopwatch.elapsed;
    stopwatch.stop();


    if (prevLoc != center) {
      rideDuration += stopwatch.elapsedMilliseconds;
      totalDist += Geolocator.distanceBetween(
        prevLoc!.latitude,
        prevLoc!.longitude,
        center!.latitude,
        center!.longitude,
      );
      offCenter = true;
    }

    double distBetweenDest = Geolocator.distanceBetween(
      center!.latitude,
      center!.longitude,
      dest!.latitude,
      dest!.longitude
    );

    if (distBetweenDest<=50) {
      rideDuration += stopwatch.elapsedMilliseconds;
      stopwatch.reset();
      stopDistanceRecord();
    }else{
      stopwatch.reset();
      stopwatch.start();
    }


    print(totalDist);
  }

  Widget mainMap() => GoogleMap(
    onMapCreated: onMapCreated,
    onCameraMoveStarted: () {
      setState(() {
        offCenter = false;

      });
    },
    mapType: currentMapType,
    initialCameraPosition: CameraPosition(
      target: center!,
      zoom: 15.0,
    ),
    markers: {
      Marker(
        markerId: MarkerId("centerMarker"),
        icon: BitmapDescriptor.defaultMarker,
        position: center!,
      ),
      Marker(
        markerId: MarkerId("destinationMarker"),
        icon: BitmapDescriptor.defaultMarker,
        position: dest!,
        visible: dstFound,
      ),
    },
    polylines: Set<Polyline>.of(polylines.values),
  );

  Widget locationTextInput() => Positioned(
    top: DimUtil.safeHeight(context) * 1 / 10,
    width: DimUtil.safeWidth(context) * 9.5 / 10,
    right: DimUtil.safeWidth(context) * .2 / 10,
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 30.0, vertical: 1.0),
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
                  offset: Offset(0, 4),
                ),
              ],
            ),
            textEditingController: textController,
            googleAPIKey: apiService.getGoogleApiKey(),
            isLatLngRequired: true,
            getPlaceDetailWithLatLng: (prediction) {
              dest = LatLng(
                double.parse(prediction.lat!),
                double.parse(prediction.lng!),
              );
              LatLngBounds bounds = getBounds();
              mapController.animateCamera(
                CameraUpdate.newLatLngBounds(bounds, 50),
              );
              dstFound = true;
              showStartButton = true;
              getPolylinePoints().then((coordinates) {
                generatePolyLines(coordinates);
              });
            },
            itemClick: (prediction) {
              textController.text = prediction.description!;
            },
          ),
        ],
      ),
    ),
  );

  LatLngBounds getBounds() {
    double latMin = min(center!.latitude, dest!.latitude);
    double lonMin = min(center!.longitude, dest!.longitude);
    double latMax = max(center!.latitude, dest!.latitude);
    double lonMax = max(center!.longitude, dest!.longitude);

    return LatLngBounds(
      southwest: LatLng(latMin, lonMin),
      northeast: LatLng(latMax, lonMax),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          center == null
              ? const Center(child: CircularProgressIndicator())
              : mainMap(),
          Positioned(
            bottom: DimUtil.safeHeight(context) * 1 / 8,
            left: DimUtil.safeWidth(context) * 1 / 20,
            child: FloatingActionButton(
              onPressed: changeMapType,
              child: Icon(Icons.compass_calibration_sharp),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 4,
            ),
          ),
          Positioned(
            bottom: DimUtil.safeHeight(context) * 1 / 20,
            left: DimUtil.safeWidth(context) * 1 / 20,
            child: FloatingActionButton(
              onPressed: recenterMap,
              child: Icon(Icons.my_location),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 4,
            ),
          ),
          if (showStartButton)
            Positioned(
              bottom: DimUtil.safeHeight(context) * 1 / 20,
              left: DimUtil.safeWidth(context) * .4,
              child: FloatingActionButton.extended(
                onPressed: startDistanceRecord,
                icon: Icon(Icons.arrow_upward),
                label: Text("Start"),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
            ),
          if (showStopButton)
            Positioned(
              bottom: DimUtil.safeHeight(context) * 1 / 20,
              left: DimUtil.safeWidth(context) * .4,
              child: FloatingActionButton.extended(
                onPressed: stopDistanceRecord,
                icon: Icon(Icons.stop_circle),
                label: Text("Stop"),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
            ),
          locationTextInput(),
        ],
      ),
    );
  }

  Future<void> fetchLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    serviceEnabled = await locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await locationController.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    locationController.onLocationChanged.listen((currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          if (recordingDistance) prevLoc = center;
          center = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          if (recordingDistance) {
            calcDist();
            if(offCenter)animateCameraWithHeading(center!, heading ?? 0);
          } else {
            if(offCenter) centerCamera(center!);
          }

          getPolylinePoints().then((coordinates) {
            generatePolyLines(coordinates);
          });
        });
      }
    });
  }

  Future<void> centerCamera(LatLng pos) async {
    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: pos,
        zoom: 15,
      )),
    );
  }

  Future<void> animateCameraWithHeading(LatLng pos, double heading) async {
    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: pos,
          zoom: 18,
          tilt: 60,
          bearing: heading,
        ),
      ),
    );
  }

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: apiService.getGoogleApiKey(),
      request: PolylineRequest(
        origin: PointLatLng(center!.latitude, center!.longitude),
        destination: PointLatLng(dest!.latitude, dest!.longitude),
        mode: TravelMode.bicycling,
      ),
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }

    return polylineCoordinates;
  }

  void generatePolyLines(List<LatLng> polylineCoordinates) async {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 6,
    );

    setState(() {
      polylines[id] = polyline;
    });
  }
}

import 'dart:async';
import 'dart:math';
import 'package:cycle_guard_app/data/user_profile_accessor.dart';
import 'package:cycle_guard_app/pages/ble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' hide LocationAccuracy;
import 'package:google_places_flutter/google_places_flutter.dart';
import '../auth/key_util.dart';
import '../auth/dim_util.dart';
import '../data/submit_ride_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import './ble.dart';

ApiService apiService = ApiService();



class RoutesPage extends StatefulWidget {
  static final String POLYLINE_USER = "poly", POLYLINE_GENERATED = "generated";

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
  bool showStartButton = true;
  bool showStopButton = false;
  bool recordingDistance = false;
  final stopwatch = Stopwatch();
  int rideDuration = 0;

  // Recalculate the route if far enough away: units are meters
  static final double RECALCULATE_ROUTE_THRESHOLD = 100;

  bool _helmetConnected = false;

  BitmapDescriptor customIcon = BitmapDescriptor.defaultMarker;

  final locationController = Location();
  final TextEditingController textController = TextEditingController();
  LatLng? center;
  LatLng? dest;
  LatLng? prevLoc;
  double totalDist = 0;
  List<LatLng> recordedLocations = [], generatedPolylines = [];
  double? heading;

  Future<void> setCustomIcon() async {
    try{
      UserProfile userProfile = await UserProfileAccessor.getOwnProfile();
      //print('${userProfile.profileIcon}.png aaaaaaaaaaaaaaaaaaaaAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
      BitmapDescriptor.asset(
        ImageConfiguration(size: Size(30, 30)),
        'assets/${userProfile.profileIcon}.png',

      ).then((icon){
        setState(() {
          customIcon = icon;
        });
      });
    }catch(e){
      print("Error loading custom icon: $e");
    }

  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setCustomIcon();
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
    _helmetConnected = isConnected();
    });
    stopwatch.start();
    if (dest == null) {
      recordedLocations.clear();
      if (!_helmetConnected) {
        recordedLocations.add(center!);
      }
    }
  }

  List<double> _toLats(List<LatLng> list) {
    return list.map((e) => e.latitude).toList(growable: false);
  }

  List<double> _toLngs(List<LatLng> list) {
    return list.map((e) => e.longitude).toList(growable: false);
  }

  double _calculateCalories() {
    return 0;
  }

  void toastMsg(String message, int time) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: time,
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  void stopDistanceRecord() {
    print(recordedLocations);

    setState(() {
      showStartButton = true;
      showStopButton = false;
      recordingDistance = false;
    });

    // Distance is in miles
    // Time is in milliseconds
    final rideInfo = RideInfo(
        totalDist * 0.000621371,
        _calculateCalories(),
        rideDuration/60000,
        _toLats(recordedLocations),
        _toLngs(recordedLocations)
    );
    print(rideInfo.toJson());


    toastMsg("${rideInfo.toJson()}", 5);

    // For now, don't send anything to backend yet
    SubmitRideService.addRide(rideInfo);
    
    centerCamera(center!);
    totalDist = 0;
    rideDuration = 0;

    stopwatch.stop();
    stopwatch.reset();
  }

  void calcDist() {
    Duration time = stopwatch.elapsed;
    stopwatch.stop();


    if (prevLoc != center) {
      rideDuration += stopwatch.elapsedMilliseconds;
      // stopwatch.reset();
      totalDist += Geolocator.distanceBetween(
        prevLoc!.latitude,
        prevLoc!.longitude,
        center!.latitude,
        center!.longitude,
      );
      offCenter = true;
    }
    if(dest != null) {
      double distBetweenDest = Geolocator.distanceBetween(
          center!.latitude,
          center!.longitude,
          dest!.latitude,
          dest!.longitude
      );
    if (distBetweenDest <= 50) {
        stopwatch.reset();
        stopDistanceRecord();
        return;
      }

    } else {
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
        icon: customIcon,
        position: center!,
      ),
      if (dest != null)
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
              getGooglePolylinePoints().then((coordinates) {
                generatedPolylines = coordinates;
                generatePolyLines(coordinates, RoutesPage.POLYLINE_GENERATED);
                print(coordinates);
                print(coordinates.length);
              });
            },
            itemClick: (prediction) {
              textController.text = prediction.description!;
              recordedLocations.clear();
              FocusScope.of(context).unfocus();
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
            right: DimUtil.safeWidth(context) * 1 / 20,
            child: FloatingActionButton(
              onPressed: () => connectHelmet(context),
              backgroundColor: _helmetConnected?Colors.green:Colors.white,
              elevation: 4,
              child: SvgPicture.asset(
                'assets/cg_logomark.svg',
                height: 30,
                width: 30,
                colorFilter: ColorFilter.mode(
                  _helmetConnected?Colors.white:Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
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

  bool isOffTrack(LatLng center) {
    if (dest == null || (dest?.latitude == 0.0 && dest?.longitude == 0.0)) return false;

    double distanceToRoute = minDistanceToRoute(generatedPolylines, center);

    return distanceToRoute > RECALCULATE_ROUTE_THRESHOLD;
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
          if (!_helmetConnected) {
            if (recordingDistance) prevLoc = center;
            center = LatLng(currentLocation.latitude!, currentLocation.longitude!);
            if (recordingDistance) {
              calcDist();
              // if (dest == null || (dest?.latitude == 0.0 && dest?.longitude == 0.0)) {

                recordedLocations.add(center!);
                generatePolyLines(recordedLocations, RoutesPage.POLYLINE_USER);
                if (isOffTrack(center!)) {

                  getGooglePolylinePoints().then((coordinates) {
                    generatePolyLines(coordinates, RoutesPage.POLYLINE_USER);
                  });

                  toastMsg("Recalculating route...", 5);
                }
              // }
              if (offCenter) animateCameraWithHeading(center!, heading ?? 0);
            } else {
              if (offCenter) centerCamera(center!);
            }
          }
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

  Future<List<LatLng>> getGooglePolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();

    if(dest!=null) {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: apiService.getGoogleApiKey(),
        request: PolylineRequest(
          origin: PointLatLng(center!.latitude, center!.longitude),
          destination: PointLatLng(dest!.latitude, dest!.longitude),
          mode: TravelMode.bicycling,
        ),
      );
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

    } else if( dest == null && recordedLocations.isNotEmpty){
      for (var point in recordedLocations) {
        polylineCoordinates.add(point);
      }
    }

    return polylineCoordinates;
  }

  void generatePolyLines(List<LatLng> polylineCoordinates, String polylineId) async {
    PolylineId id = PolylineId(polylineId);
    Polyline polyline = Polyline(
      polylineId: id,
      color: polylineId==RoutesPage.POLYLINE_GENERATED?Colors.deepOrangeAccent:Colors.blue,
      points: polylineCoordinates,
      width: 6,
    );

    setState(() {
      polylines[id] = polyline;
    });
  }

  void connectHelmet(BuildContext context) async {
    await showCustomDialog(context, (data) {
      print("In callback function: $data");
      {
        final newCenter = LatLng(data.latitude, data.longitude);
        if (newCenter == center) return;
      }

      if (recordingDistance) prevLoc = center;
        center = LatLng(data.latitude, data.longitude);
        if (recordingDistance) {
          calcDist();
          if (dest == null || (dest?.latitude == 0.0 && dest?.longitude == 0.0)) {

            recordedLocations.add(center!);
            getGooglePolylinePoints().then((coordinates) {
              generatePolyLines(coordinates, RoutesPage.POLYLINE_USER);
            });
          }
          if (offCenter) animateCameraWithHeading(center!, heading ?? 0);
        } else {
          if (offCenter) centerCamera(center!);
        }
    });

    print("After await");

    print("Connected: ${isConnected()}");
    setState(() {
      _helmetConnected = isConnected();
    });
  }

  double minDistanceToRoute(List<LatLng> route, LatLng point) {
    double max=0, cur;

    for (int i=0; i<route.length-1; i++) {
      cur = distanceToLine(point, route[i], route[i+1]);
      if (cur>max) max=cur;
    }

    return max;
  }

  double distanceToLine(LatLng point, LatLng start, LatLng end) {
    double x1 = start.longitude;
    double y1 = start.latitude;
    double x2 = end.longitude;
    double y2 = end.latitude;
    double x = point.longitude;
    double y = point.latitude;

    double dx = x2 - x1;
    double dy = y2 - y1;
    double distSq = dx * dx + dy * dy;

    if (distSq == 0) {
      return Geolocator.distanceBetween(
        point.latitude,
        point.longitude,
        start.latitude,
        start.longitude,
      );
    }

    double t = ((x - x1) * dx + (y - y1) * dy) / distSq;

    // Clamp t to [0, 1] to find the closest point on the line segment
    t = t.clamp(0, 1);

    // Calculate the closest point on the line segment
    double closestX = x1 + t * dx;
    double closestY = y1 + t * dy;

    // Calculate the distance between the point and the closest point on the line segment
    return Geolocator.distanceBetween(
      point.latitude,
      point.longitude,
      closestX,
      closestY,
    );
  }
}

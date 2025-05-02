import 'dart:async';
import 'dart:math';

import 'package:cycle_guard_app/data/coordinates_accessor.dart';
import 'package:cycle_guard_app/data/health_info_accessor.dart';
import 'package:cycle_guard_app/data/single_trip_history.dart';
import 'package:cycle_guard_app/data/user_profile_accessor.dart';
import 'package:cycle_guard_app/pages/ble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:location/location.dart' hide LocationAccuracy;

import 'package:provider/provider.dart';
import 'package:cycle_guard_app/main.dart';

import '../auth/dim_util.dart';
import '../auth/key_util.dart';
import '../data/submit_ride_service.dart';

ApiService apiService = ApiService();

SingleTripInfo? _tripInfo;
int _timestamp = -1;
int _rideIdx=-1;
String? _rideDate;
void setSelectedRoute(int timestamp, SingleTripInfo? tripInfo, int rideIdx, String rideDate) {
  _timestamp = timestamp;
  _tripInfo = tripInfo;
  _rideIdx = rideIdx;
  _rideDate = rideDate;
}


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
  static final double RECALCULATE_ROUTE_THRESHOLD = 75;
  static final double DEFAULT_ZOOM = 16;

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

  Future<void> drawTimestampData(int timestamp) async {
    final coords = await CoordinatesAccessor.getCoordinates(timestamp);
    final latitudes = coords.latitudes, longitudes = coords.longitudes;

    final polylines = [for(var i=0; i<latitudes.length; i++) LatLng(latitudes[i], longitudes[i])];

    generatedPolylines = polylines;
    generatePolyLines(polylines, RoutesPage.POLYLINE_GENERATED);
  }

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
    print("Map controller created");
    if (_timestamp != -1) {
      drawTimestampData(_timestamp);

      // setState(() {
      // });
    }
  }

  void changeMapType() {
    setState(() {
      currentMapType = currentMapType == MapType.normal
          ? MapType.terrain
          : MapType.normal;
    });
  }

  int recenterClickTime=0;
  void recenterMap() async {
    int curClickTime = DateTime.now().millisecondsSinceEpoch;
    bool resetZoom = curClickTime-recenterClickTime < 500;
    print("Recentering map: $offCenter");
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: center!,
        zoom: resetZoom?DEFAULT_ZOOM:(await mapController.getZoomLevel()),
      )),
    );
    recenterClickTime = curClickTime;
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
    recordedLocations.clear();
    if (!_helmetConnected) {
      recordedLocations.add(center!);
    }
  }

  List<double> _toLats(List<LatLng> list) => list.map((e) => e.latitude).toList(growable: false);

  List<double> _toLngs(List<LatLng> list) => list.map((e) => e.longitude).toList(growable: false);

  Future<double> _calculateCalories(double miles, double minutes) async {
    return await HealthInfoAccessor.getCaloriesBurned(miles, minutes);
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

  Future<void> stopDistanceRecord() async {
    print(recordedLocations);

    setState(() {
      showStartButton = true;
      showStopButton = false;
      recordingDistance = false;
    });


    final miles = totalDist * 0.000621371;
    final minutes = rideDuration/60000;
    // Distance is in miles
    // Time is in milliseconds
    final rideInfo = RideInfo(
        miles,
        await _calculateCalories(miles, minutes),
        minutes,
        _toLats(recordedLocations),
        _toLngs(recordedLocations)
    );
    print(rideInfo.toJson());

    // For now, don't send anything to backend yet
    SubmitRideService.addRide(rideInfo);
    
    centerCamera(center!);
    totalDist = 0;
    rideDuration = 0;

    stopwatch.stop();
    stopwatch.reset();

    PostRideData.showPostRideDialog(context, rideInfo);
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


    // print(totalDist);
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
      zoom: DEFAULT_ZOOM,
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
                generatePolyLines(coordinates, RoutesPage.POLYLINE_GENERATED);
                // print(coordinates);
                // print(coordinates.length);
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

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
          if (_timestamp>-1)
            Positioned(
              top: DimUtil.safeHeight(context) * 3 / 16,
              width: DimUtil.safeWidth(context) * 9.5 / 10,
              height: DimUtil.safeHeight(context) * 1.8 / 16,
              right: DimUtil.safeWidth(context) * .2 / 10,
              child: FloatingActionButton.extended(
                onPressed: () {
                  print("Ride info display pressed");
                  _timestamp=-1;
                  setState(() => {});
                },
                label: Text(
                  "Ride $_rideIdx on $_rideDate:\n"
                    "${_tripInfo!.distance} miles, "
                    "${_tripInfo!.time} minutes, "
                    "${_tripInfo!.calories} calories",
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                backgroundColor: colorScheme.primary,
                foregroundColor: isDarkTheme?Colors.white:Colors.black,
                elevation: 4,
              ),
            ),
          locationTextInput(),
        ],
      ),
    );
  }

  StreamSubscription<LocationData>? googleLocationUpdates;
  @override
  void dispose() {
    super.dispose();
    if (googleLocationUpdates != null) {
      googleLocationUpdates!.cancel();
    }
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

    // locationController.changeSettings(accuracy: );
    // locationController.

    googleLocationUpdates = locationController.onLocationChanged.listen((currentLocation) {
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
                    generatePolyLines(coordinates, RoutesPage.POLYLINE_GENERATED);
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

  int lastPress=0;
  Future<void> centerCamera(LatLng pos) async {
    // print("Centering");
    try {
      await mapController.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(
            target: pos,
            zoom: DEFAULT_ZOOM
        )),
      );
    } catch(e) {}
    // prevPos = pos;
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

      final res = result.points.map((point) => LatLng(point.latitude, point.longitude)).toList();
      generatedPolylines = res;
      return res;
    }

    return generatedPolylines;
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

  void readHelmetData(BluetoothData data) {
    print("In callback function: $data");
    {
      final newCenter = LatLng(data.latitude, data.longitude);
      if (newCenter == center) return;
    }

    if (recordingDistance) prevLoc = center;
    center = LatLng(data.latitude, data.longitude);
    if (recordingDistance) {
      calcDist();
      // if (dest == null || (dest?.latitude == 0.0 && dest?.longitude == 0.0)) {

      recordedLocations.add(center!);
      generatePolyLines(recordedLocations, RoutesPage.POLYLINE_USER);
      if (isOffTrack(center!)) {
        getGooglePolylinePoints().then((coordinates) {
          generatePolyLines(coordinates, RoutesPage.POLYLINE_GENERATED);
        });

        toastMsg("Recalculating route...", 5);
      }
      // }
      if (offCenter) animateCameraWithHeading(center!, heading ?? 0);
    } else {
      if (offCenter) centerCamera(center!);
    }
  }

  void onBluetoothSelected(bool isConnected) {
    setState(() => _helmetConnected = isConnected);
    Navigator.pop(context);
  }

  void connectHelmet(BuildContext context) async {
    await showCustomDialog(context, onNewDataCallback: readHelmetData, onBluetoothSelectedCallback: onBluetoothSelected);
  }

  double minDistanceToRoute(List<LatLng> route, LatLng point) {
    double min=2000000000, cur;

    for (int i=0; i<route.length-1; i++) {
      cur = distanceToLine(point, route[i], route[i+1]);
      if (cur<min) min=cur;
    }

    return min;
  }

  // Thanks GPT!
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
    final res =  Geolocator.distanceBetween(
      point.latitude,
      point.longitude,
      closestY,
      closestX,
    );

    // print("Min distance calculation: $start, $end, $point, $res");
    return res;
  }
}


class PostRideData {
  static final random = Random();
  static final _postRidePrefixes = ["Nice", "Great", "Fun", "Cool"];
  static final _postRideSuffixes = ["ride", "trip", "journey"];

  static String _getRandomPostRideText() {
    final i1 = random.nextInt(_postRidePrefixes.length);
    final i2 = random.nextInt(_postRideSuffixes.length);
    return "${_postRidePrefixes[i1]} ${_postRideSuffixes[i2]}!";
  }

  static Future<void> showPostRideDialog(BuildContext context, RideInfo rideInfo) async {
    Color selectedColor = Provider.of<MyAppState>(context, listen: false).selectedColor;
    print(rideInfo);

    final mins = rideInfo.time.floor();
    final secs = ((rideInfo.time - mins) * 60).floor();
    final miles = rideInfo.distance.toStringAsFixed(1);
    final cals = rideInfo.calories.toStringAsFixed(1);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Container(
            width: 320,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [selectedColor, Theme.of(context).colorScheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getRandomPostRideText(),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                _buildInfoRow(Icons.directions_bike, "$miles miles biked"),
                _buildInfoRow(Icons.local_fire_department, "$cals calories burned"),
                _buildInfoRow(Icons.timer, "$mins min $secs sec"),
                SizedBox(height: 25),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    backgroundColor: selectedColor, 
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Nice!",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

}
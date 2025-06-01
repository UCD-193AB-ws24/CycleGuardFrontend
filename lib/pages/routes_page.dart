import 'dart:async';
import 'dart:math';

import 'package:cycle_guard_app/data/coordinates_accessor.dart';
import 'package:cycle_guard_app/data/health_info_accessor.dart';
import 'package:cycle_guard_app/data/navigation_accessor.dart';
import 'package:cycle_guard_app/data/single_trip_history.dart';
import 'package:cycle_guard_app/data/user_daily_goal_provider.dart';
import 'package:cycle_guard_app/data/user_profile_accessor.dart';
import 'package:cycle_guard_app/data/week_history_provider.dart';
import 'package:cycle_guard_app/main.dart';
import 'package:cycle_guard_app/pages/ble.dart';
import 'package:cycle_guard_app/pages/routes_autofill.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' hide LocationAccuracy;
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

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
  static final double METERS_TO_MILES = 0.000621371;
  static final double METERS_TO_FEET = 3.28084;

  bool _helmetConnected = false;

  BitmapDescriptor customIcon = BitmapDescriptor.defaultMarker;

  final locationController = Location();
  final TextEditingController textController = TextEditingController();
  LatLng? center;
  LatLng? dest;
  LatLng? prevLoc;
  double totalDist = 0;
  List<LatLng> recordedLocations = [], generatedPolylines = [];
  List<double> recordedAltitudes = [];
  double? heading;

  double distanceGoal = 0.0;
  double caloriesGoal = 0.0;
  double timeGoal = 0.0;

  double targetDistance = 0.0;
  double targetCalories = 0.0;
  double targetTime = 0.0;

  Future<void> drawTimestampData(int timestamp) async {
    final coords = await CoordinatesAccessor.getCoordinates(timestamp);
    final latitudes = coords.latitudes, longitudes = coords.longitudes;

    final polylines = [for(var i=0; i<latitudes.length; i++) LatLng(latitudes[i], longitudes[i])];

    generatedPolylines.clear();
    for (final point in polylines) {
      generatedPolylines.add(point);
      compressCoords(generatedPolylines);
    }

    // generatedPolylines = polylines;
    generatePolyLines(generatedPolylines, RoutesPage.POLYLINE_GENERATED);

    print("Generated polylines with length ${generatedPolylines.length}");

    if (generatedPolylines.isNotEmpty) {
      center = generatedPolylines[0];
      recenterMap();
      recenterMap();
    }
  }

  Future<void> setCustomIcon() async {
    try{
      UserProfile userProfile = await UserProfileAccessor.getOwnProfile();
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

  late HealthInfo healthInfo;

  Future<void> initHealthInfo() async {
    healthInfo = await HealthInfoAccessor.getHealthInfo();
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

    Future.microtask(() {
      Provider.of<UserDailyGoalProvider>(context, listen: false).fetchDailyGoals();
      Provider.of<WeekHistoryProvider>(context, listen: false).fetchWeekHistory();
    });

    final userGoals = Provider.of<UserDailyGoalProvider>(context, listen: false);
    distanceGoal = userGoals.dailyDistanceGoal;
    timeGoal = userGoals.dailyTimeGoal;
    caloriesGoal = userGoals.dailyCaloriesGoal;

    initHealthInfo();
    SubmitRideService.tryAddAllRides();
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
    final weekHistory = Provider.of<WeekHistoryProvider>(context, listen: false);
    final todayUtcTimestamp = DateTime.utc(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          0,
          0,
          0,
          0,
          0,
        ).millisecondsSinceEpoch ~/
        1000;

    final todayInfo = weekHistory.dayHistoryMap[todayUtcTimestamp] ??
      const SingleTripInfo(
          distance: 0.0,
          calories: 0.0,
          time: 0.0,
          averageAltitude: 0,
          climb: 0);

    targetDistance = distanceGoal - todayInfo.distance;
    targetTime = timeGoal - todayInfo.time;
    targetCalories = caloriesGoal - todayInfo.calories;

    _notifyCurrentRideData.value = AccumRideData.blank();
    final appState = Provider.of<MyAppState>(context, listen: false);

    if (appState.isCalorieGoalMet == true) {
      targetCalories = 0.0;
    }
    if (appState.isDistanceGoalMet == true) {
      targetDistance = 0.0;
    }
    if(appState.isTimeGoalMet == true) {
      targetTime = 0.0;
    }

    setState(() {
      showStartButton = false;
      showStopButton = true;
      recordingDistance = true;
      offCenter = true;
      _helmetConnected = isConnected();
    });
    appState.startRouteRecording();
    stopwatch.start();
    recordedLocations.clear();
    generatePolyLines(recordedLocations, RoutesPage.POLYLINE_USER);
    recordedAltitudes.clear();
    // if (!_helmetConnected) {
    //   recordedLocations.add(center!);
    // }
  }

  List<double> _toLats(List<LatLng> list) => list.map((e) => e.latitude).toList(growable: false);
  List<double> _toLngs(List<LatLng> list) => list.map((e) => e.longitude).toList(growable: false);

  double _calculateCalories(double miles, double minutes) {
    return healthInfo.getCaloriesBurned(miles, minutes);
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

  static double avg(List<double> list) {
    print(list);
    if (list.isEmpty) return 0;
    double accum=0;
    for (double n in list) {
      accum+=n;
    }
    return accum/list.length;
  }

  void stopDistanceRecord() {
    // print(recordedLocations);
    final appState = Provider.of<MyAppState>(context, listen: false);

    setState(() {
      showStartButton = true;
      showStopButton = false;
      recordingDistance = false;
    });

     appState.stopRouteRecording();

    final miles = totalDist * METERS_TO_MILES;
    final minutes = rideDuration/60000;
    // Distance is in miles
    // Time is in milliseconds
    final rideInfo = RideInfo(
        miles,
        _notifyCurrentRideData.value.calories,
        minutes,
        _toLats(recordedLocations),
        _toLngs(recordedLocations),
        // _notifyCurrentRideData.value.climb,
        // avg(recordedAltitudes),
      0, 0
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

  void calcDist({double altitude=0}) {
    Duration time = stopwatch.elapsed;
    stopwatch.stop();


    if (prevLoc != center) {
      int elapsedMs = stopwatch.elapsedMilliseconds;
      double distanceMeters = Geolocator.distanceBetween(
        prevLoc!.latitude,
        prevLoc!.longitude,
        center!.latitude,
        center!.longitude,
      );

      rideDuration += elapsedMs;
      // stopwatch.reset();
      totalDist += distanceMeters;

      final newVal = _notifyCurrentRideData.value.addToCur(
          distanceMeters * METERS_TO_MILES, elapsedMs/60000, altitude, healthInfo);
      _notifyCurrentRideData.value = newVal;

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



  String? destString;
  void setRoutesAutofillCallback(BuildContext context) {
    setCallback((input) {
      // print("Selected autofill value: $input");
      destString = input;
      getGooglePolylinePoints().then((coordinates) {
        generatePolyLines(coordinates, RoutesPage.POLYLINE_GENERATED);
        dest = coordinates[coordinates.length-1];
      });
    });
  }

  Widget mainMap() => GoogleMap(
    onTap: (argument) {
      print("Map tap");
      SystemChannels.textInput.invokeMethod("TextInput.hide");
    },
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
          RoutesAutofill(this),
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
    Color selectedColor = Provider.of<MyAppState>(context, listen: false).selectedColor;
    final colorScheme = Theme.of(context).colorScheme;
    //final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    setRoutesAutofillCallback(context);

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
            bottom: DimUtil.safeHeight(context) * 2 / 8,
            right: DimUtil.safeWidth(context) * 1 / 20,
            child: FloatingActionButton(
              onPressed: () => _showRideInputPage(context),
              child: Icon(Icons.bike_scooter),
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
          if (!recordingDistance && _timestamp>-1)
            Positioned(
              top: DimUtil.safeHeight(context) * 3 / 16,
              width: DimUtil.safeWidth(context) * 9.5 / 10,
              height: DimUtil.safeHeight(context) * 1.8 / 16,
              right: DimUtil.safeWidth(context) * .2 / 10,
              child: FloatingActionButton.extended(
                onPressed: () {
                  print("Ride info display pressed");
                  _timestamp=-1;
                  // generatedPolylines.clear();
                  // generatePolyLines([], RoutesPage.POLYLINE_GENERATED);
                  setState(() => {});
                },
                label: Text(
                  "Ride $_rideIdx on $_rideDate:\n"
                    "${_tripInfo!.distance} miles, "
                    "${_tripInfo!.time} minutes, "
                    "${_tripInfo!.calories} calories",
                    // "${_tripInfo!.averageAltitude} ft. elevation, "
                    // "${_tripInfo!.climb} ft. climbed",
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                backgroundColor: selectedColor,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
            ),
          if (recordingDistance)
            _curRideInfoWidget(colorScheme.primary),
          locationTextInput(),
        ],
      ),
    );
  }

  final ValueNotifier<AccumRideData> _notifyCurrentRideData = ValueNotifier<AccumRideData>(AccumRideData.blank());

  Widget _curRideInfoWidget(Color bg) {
    /*print("-------- DISTANCE -------");
    print(distanceGoal);
    print(targetDistance);
    print("------- TIME --------");
    print(timeGoal);
    print(targetTime);
    print("------- CALORIES --------");
    print(caloriesGoal);
    print(targetCalories);
    print("---------------");*/

    return ValueListenableBuilder(
      valueListenable: _notifyCurrentRideData,
      builder: (BuildContext context, AccumRideData rideData, Widget? child) {
        return Stack(
          children: [
            Positioned(
              top: DimUtil.safeHeight(context) * 3 / 16,
              width: DimUtil.safeWidth(context) * 3.2 / 10,
              height: DimUtil.safeHeight(context) * 1.2 / 16,
              left: DimUtil.safeWidth(context) * .2 / 10,
              child: StatCard(
                icon: Icons.timer,
                label: 'Time',
                value: rideData.time,
                remaining: targetTime,
                goal: timeGoal,
                unit: 'min',
                color: Colors.blueAccent),
            ),
            Positioned(
              top: DimUtil.safeHeight(context) * 4.2 / 16,
              width: DimUtil.safeWidth(context) * 3.2 / 10,
              height: DimUtil.safeHeight(context) * 1.2 / 16,
              left: DimUtil.safeWidth(context) * .2 / 10,
              child: _buildStatCard(
                  Icons.speed,
                  'Speed',
                  rideData.speed,
                  0.0,
                  0.0,
                  'mph',
                  Colors.lightBlueAccent),
            ),
            Positioned(
                top: DimUtil.safeHeight(context) * 4.2 / 16,
                width: DimUtil.safeWidth(context) * 3.2 / 10,
                height: DimUtil.safeHeight(context) * 1.2 / 16,
                right: DimUtil.safeWidth(context) * .2 / 10,
              child: StatCard(
                icon: Icons.directions_bike,
                label: 'Distance',
                value: rideData.distance,
                remaining: targetDistance,
                goal: distanceGoal,
                unit: 'mi',
                color: Colors.greenAccent),
            ),
            // Positioned(
            //   top: DimUtil.safeHeight(context) * 4.2 / 16,
            //   width: DimUtil.safeWidth(context) * 3.2 / 10,
            //   height: DimUtil.safeHeight(context) * 1.2 / 16,
            //   left: DimUtil.safeWidth(context) * 3.4 / 10,
            //   child: _buildStatCard(
            //     Icons.trending_up,
            //       'Altitude',
            //       rideData.altitude,
            //       0.0,
            //       0.0,
            //       'ft',
            //       Colors.deepPurpleAccent),
            // ),
            Positioned(
              top: DimUtil.safeHeight(context) * 3 / 16,
              width: DimUtil.safeWidth(context) * 3.2 / 10,
              height: DimUtil.safeHeight(context) * 1.2 / 16,
              right: DimUtil.safeWidth(context) * .2 / 10,
              child: StatCard(
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  value: rideData.calories,
                  remaining: targetCalories,
                  goal: caloriesGoal,
                  unit: 'cal',
                  color: Colors.redAccent),
            ),
            // Positioned(
            //   top: DimUtil.safeHeight(context) * 4.2 / 16,
            //   width: DimUtil.safeWidth(context) * 3.2 / 10,
            //   height: DimUtil.safeHeight(context) * 1.2 / 16,
            //   right: DimUtil.safeWidth(context) * .2 / 10,
            //   child: _buildStatCard(
            //       Icons.arrow_upward,
            //       'Climb',
            //       rideData.climb,
            //       0.0,
            //       0.0,
            //       'ft',
            //       Colors.purpleAccent),
            // ),
          ],
        );
      });
  }

  Widget _buildStatCard(IconData icon, String label, double value, double remaining, double goal, String unit, Color color) {
    return Card(
      color: color.withAlpha(192),
      shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: value >= remaining && goal > 0
          ? BorderSide(color: Colors.amber, width: 2)
          : BorderSide.none,
    ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(label,
                    style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text("${value.toStringAsFixed(1)} $unit",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
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

    locationController.enableBackgroundMode(enable: true);

    googleLocationUpdates = locationController.onLocationChanged.listen((currentLocation) {

      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {

        setState(() {
          if (!_helmetConnected) {
            if (recordingDistance) prevLoc = center;
            center = LatLng(currentLocation.latitude!, currentLocation.longitude!);
            if (recordingDistance) {
              // print("Altitude: ${currentLocation.altitude}");
              final altitudeFeet = currentLocation.altitude! * METERS_TO_FEET;
              calcDist(altitude: altitudeFeet);
              // if (dest == null || (dest?.latitude == 0.0 && dest?.longitude == 0.0)) {

                recordedLocations.add(center!);
                compressCoords(recordedLocations);

                // recordedAltitudes.add(altitudeFeet);
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
    // PolylinePoints polylinePoints = PolylinePoints();

    if(destString!=null) {
      // PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      //   googleApiKey: apiService.getGoogleApiKey(),
      //   request: PolylineRequest(
      //     origin: PointLatLng(center!.latitude, center!.longitude),
      //     destination: PointLatLng(dest!.latitude, dest!.longitude),
      //     mode: TravelMode.bicycling,
      //   ),
      // );

      final result = await NavigationAccessor.getRoute(center!, destString!);

      final res = result.polyline;
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

  static final double epsilon = .00001;
  void readHelmetData(BluetoothData data) {
    print("In callback function: $data");
    {
      if (data.latitude.abs()<epsilon || data.longitude.abs()<epsilon) {
        print("0, 0 found, returning");
        return;
      }
      final newCenter = LatLng(data.latitude, data.longitude);
      if (newCenter == center) return;
    }


    if (recordingDistance) prevLoc = center;
    final newCenter = LatLng(data.latitude, data.longitude);
    if (center != null) {
      final distPoints = Geolocator.distanceBetween(
        center!.latitude,
        center!.longitude,
        data.latitude,
        data.longitude,
      );
      
      if (!recordingDistance || distPoints <= 50) {
        center = newCenter;
      } else return;
    }
    if (recordingDistance) {
      calcDist();
      // if (dest == null || (dest?.latitude == 0.0 && dest?.longitude == 0.0)) {

      recordedLocations.add(center!);
      compressCoords(recordedLocations);
      // TODO handle altitudes from helmet
      // recordedAltitudes.add(0);
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

  double distanceBetweenMeters(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  double _cosines(LatLng A, LatLng B, LatLng C) {
    double a = distanceBetweenMeters(B, C);
    double b = distanceBetweenMeters(A, C);
    double c = distanceBetweenMeters(A, B);

    double squares = a*a + c*c - b*b;
    double angle = acos(squares/(2*a*c));

    return angle;
  }

  static final double COSINES_THRESHOLD_RADIANS = 10 * (pi/180);
  void compressCoords(List<LatLng> list) {
    if (list.length<3) return;

    LatLng C=list[list.length-1];
    while (list.length>=3) {
      LatLng A=list[list.length-3], B=list[list.length-2];
      double angleRadians = _cosines(A, B, C);

      // Angle is big enough to be considered a turn: stop combining
      if ((pi-angleRadians) > COSINES_THRESHOLD_RADIANS) {
        break;
      } else {
        list.removeAt(list.length-2);
      }
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


  Future<int> _addRideInfo(double distance, double calories, double time) async {
    final timestamp = await SubmitRideService.addRideRaw(distance, calories, time, [], [], 0, 0);
    print("Successfully added ride info! Timestamp: $timestamp");
    return timestamp;
  }

  final distanceController = TextEditingController();
  final caloriesController = TextEditingController();
  final timeController = TextEditingController();

  Widget _numberField(TextEditingController controller, String hint) => TextField(
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      border: OutlineInputBorder(),
    ),
    style: TextStyle(color: Colors.black),
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
    textInputAction: TextInputAction.done,
  );

  void _showRideInputPage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Manually add ride", style: TextStyle(color: Colors.black87),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _numberField(distanceController, "Distance (miles)"),
              const SizedBox(height: 12),
              _numberField(caloriesController, "Calories burned"),
              const SizedBox(height: 12),
              _numberField(timeController, "Time (minutes)"),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final distance = double.tryParse(distanceController.text) ?? 0.0;
                  final calories = double.tryParse(caloriesController.text) ?? 0.0;
                  final time = double.tryParse(timeController.text) ?? 0.0;

                  _addRideInfo(distance, calories, time);
                  Navigator.pop(context);
                },
                child: Text("Submit Ride Info"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AccumRideData {
  final double distance, time, calories, speed, altitude, climb;
  AccumRideData(this.distance, this.time, this.calories, this.speed, this.altitude, this.climb);

  factory AccumRideData.blank() {
    return AccumRideData(0, 0, 0, 0, 0, 0);
  }

  /// AccumRideData is immutable. Instead, return a new object with the accumulated data.
  AccumRideData addToCur(double distance, double time, double altitude, HealthInfo healthInfo) {
    final speed = 60 * distance/time;
    final calories = healthInfo.getCaloriesBurned(distance, time);

    var climb = this.climb + max(0, altitude-this.altitude);
    if (this.time==0) climb=0;

    return AccumRideData(this.distance+distance, this.time+time, this.calories+calories, speed, altitude, climb);
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
    final climb = rideInfo.climb.toStringAsFixed(1);
    final avgAltitude = rideInfo.averageAltitude.toStringAsFixed(1);

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
                // _buildInfoRow(Icons.trending_up, "$avgAltitude ft. average elevation"),
                // _buildInfoRow(Icons.arrow_upward, "$climb ft. climbed"),
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

class StatCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final double value;
  final double remaining;
  final double goal;
  final String unit;
  final Color color;

  const StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.remaining,
    required this.goal,
    required this.unit,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  _StatCardState createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _animationPlayed = false;
  bool _isDisposed = false;

  @override
  void initState() {
    final appState = Provider.of<MyAppState>(context, listen: false);
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08) 
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_controller);

    if (widget.label == 'Distance') {
      _animationPlayed = appState.isDistanceGoalMet;
    } else if (widget.label == 'Time') {
      _animationPlayed = appState.isTimeGoalMet;
    } else {
      _animationPlayed = appState.isCalorieGoalMet;
    }
  }

  @override
  void didUpdateWidget(covariant StatCard oldWidget) {
    final appState = Provider.of<MyAppState>(context, listen: false);
    super.didUpdateWidget(oldWidget);
    // Only trigger if not previously played AND goal is met AND not disposed
    if (!_animationPlayed && 
        widget.value >= widget.remaining && 
        widget.goal > 0 &&
        !_isDisposed) {
      
      // Safe vibration - wrapped in try/catch
      try {
        Vibration.hasVibrator().then((hasVibrator) {
          if (hasVibrator && !_isDisposed) {
            Vibration.vibrate(duration: 200); // ms
          }
        });
      } catch (e) {
        print('Vibration error: $e');
      }

      if (mounted) {
        setState(() {
          if (widget.label == 'Distance') {
            appState.isDistanceGoalMet = true;
          } else if (widget.label == 'Time') {
            appState.isTimeGoalMet = true;
          } else {
            appState.isCalorieGoalMet = true;
          }
          _animationPlayed = true;
        });
      }

      _controller.forward().then((_) {
        _controller.reverse();
      });
    }
  }

  @override
  void dispose() {
    // Ensure any ongoing vibration is canceled
    try {
      Vibration.cancel();
    } catch (e) {
      print('Error canceling vibration: $e');
    }
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool highlight = widget.value >= widget.remaining && widget.goal > 0;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        color: widget.color.withAlpha(192),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: highlight
              ? BorderSide(color: Colors.amber, width: 2)
              : BorderSide.none,
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.white),
              SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(widget.label,
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text("${widget.value.toStringAsFixed(1)} ${widget.unit}",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
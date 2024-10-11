import 'dart:async';
import 'dart:convert';
import 'package:driverapp/pages/payment_dialog.dart';
import 'package:driverapp/pushnotification/push_notification_system.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:restart_app/restart_app.dart';
import '../global/global.dart';
import '../method/theme_methods.dart';
import '../model/trip_details.dart';
import '../widget/notification_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfDriver;
  Color colorToShow = Colors.green;
  String titleToShow = "GO ONLINE NOW";
  bool isDriverAvailable = false;
  DatabaseReference? newTripRequestReference;
  MapThemeMethods themeMethods = MapThemeMethods();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    retrieveCurrentDriverInfo();
    getCurrentLiveLocationOfUser();
    listenForNewTripRequests(); // Listen for new trip requests
  }

  Future<void> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Handle the case when permissions are denied
        return;
      }
    }
  }

  Future<void> getCurrentLiveLocationOfUser() async {
    // await checkLocationPermission(); // Request permissions

    try {
      Position positionOfUser = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation);
      currentPositionOfDriver = positionOfUser;
      driverCurrentPosition = currentPositionOfDriver;

      LatLng positionOfUserInLatLng = LatLng(currentPositionOfDriver!.latitude,
          currentPositionOfDriver!.longitude);

      CameraPosition cameraPosition =
          CameraPosition(target: positionOfUserInLatLng, zoom: 15);
      controllerGoogleMap!
          .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

      setState(() {}); // Refresh the UI to show the marker
    } catch (e) {
      // Handle any errors here, e.g., show a message to the user
      print("Error getting location: $e");
    }
  }

  goOnlineNow() {
    //all drivers who are available for new trip request
    Geofire.initialize("onlineDrivers");

    Geofire.setLocation(FirebaseAuth.instance.currentUser!.uid,
        currentPositionOfDriver!.latitude, currentPositionOfDriver!.longitude);

    newTripRequestReference = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("newTripStatus");
    newTripRequestReference!.set("waiting");

    newTripRequestReference!.onValue.listen((event) {});
  }

  setAndGetLocationUpdates() {
    positionStreamHomePage =
        Geolocator.getPositionStream().listen((Position position) {
      currentPositionOfDriver = position;

      if (isDriverAvailable == true) {
        Geofire.setLocation(
            FirebaseAuth.instance.currentUser!.uid,
            currentPositionOfDriver!.latitude,
            currentPositionOfDriver!.longitude);
      }
      LatLng positionLatLng = LatLng(
        position.latitude,
        position.longitude,
      );
      controllerGoogleMap!
          .animateCamera(CameraUpdate.newLatLng(positionLatLng));
    });
  }

  goOfflineNow() {
    //stop sharing live location Updates
    Geofire.removeLocation(FirebaseAuth.instance.currentUser!.uid);

    //stop listening to the newTripStatus
    newTripRequestReference!.onDisconnect();
    newTripRequestReference!.remove();
    newTripRequestReference = null;
  }

  initializePushNotificationSystem() {
    PushNotificationSystem notificationSystem = PushNotificationSystem();
    notificationSystem.generateDeviceRegistrationToken();
    notificationSystem.startListeningForNewNotification(context);
  }

  void listenForNewTripRequests() {
    newTripRequestReference = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("newTripRequest");

    newTripRequestReference!.onChildAdded.listen((event) async {
      // Check if there is already an active trip request
      DatabaseReference driverTripStatusRef = FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(FirebaseAuth.instance.currentUser!.uid)
          .child("newTripStatus");

      // Fetch current trip status
      DataSnapshot snapshot = await driverTripStatusRef.once();
      if (snapshot.value == null) {
        // No active trip request, proceed to show the notification dialog
        final tripDetails = TripDetails.fromSnapshot(event.snapshot);
        showDialog(
          context: context,
          barrierDismissible: false, // Optional: prevent dismissing the dialog by tapping outside
          builder: (BuildContext context) {
            return NotificationDialog(tripDetailsInfo: tripDetails);
          },
        );
      } else {
        // Handle active trip request (e.g., show a message)
        // Optional: Display a snackbar or other notification to inform the user
        cMethods.displaySnackBar("You have an active trip request.", context);
      }
    });
  }

  retrieveCurrentDriverInfo() {
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .once()
        .then((snap) {
      driverName = (snap.snapshot.value as Map)["name"];
      driverPhone = (snap.snapshot.value as Map)["phone"];
      driverPhoto = (snap.snapshot.value as Map)["photo"];
      carColor = (snap.snapshot.value as Map)["car_details"]["carColor"];
      carModel = (snap.snapshot.value as Map)["car_details"]["carModel"];
      carNumber = (snap.snapshot.value as Map)["car_details"]["carNumber"];
    });

    initializePushNotificationSystem();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ///google map
          GoogleMap(
            padding: EdgeInsets.only(top: 136),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController) {
              controllerGoogleMap = mapController;
              themeMethods.updateMapTheme(controllerGoogleMap!);
              googleMapCompleterController.complete(controllerGoogleMap);

              getCurrentLiveLocationOfUser();
            },
            markers: currentPositionOfDriver != null
                ? {
                    Marker(
                      markerId: MarkerId("currentLocation"),
                      position: LatLng(currentPositionOfDriver!.latitude,
                          currentPositionOfDriver!.longitude),
                      infoWindow: InfoWindow(title: "You are here"),
                    ),
                  }
                : {},
          ),

          Container(
            height: 136,
            width: double.infinity,
            color: Colors.black54,
          ),

          ///go online offline button
          Positioned(
              top: 61,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                            context: context,
                            isDismissible: false,
                            builder: (BuildContext context) {
                              return Container(
                                decoration: const BoxDecoration(
                                    color: Colors.black,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.grey,
                                          blurRadius: 5.0,
                                          spreadRadius: 0.5,
                                          offset: Offset(0.7, 0.7))
                                    ]),
                                height: 221,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 18),
                                  child: Column(
                                    children: [
                                      const SizedBox(
                                        height: 11,
                                      ),
                                      Text(
                                        !isDriverAvailable
                                            ? "GO ONLINE NOW"
                                            : "GO OFFLINE NOW",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 21,
                                      ),
                                      Text(
                                        !isDriverAvailable
                                            ? "You are about to go online, you will become available to receive trip request from users."
                                            : "GO OFFLINE NOWYou are about to go offline, you will stop receiving trip request from users.",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 25,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                              child: ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.blue),
                                                  child: const Text("BACK"))),
                                          const SizedBox(
                                            width: 16,
                                          ),
                                          Expanded(
                                              child: ElevatedButton(
                                                  onPressed: () {
                                                    if (!isDriverAvailable) {
                                                      //go online
                                                      goOnlineNow();

                                                      //get driver location updates
                                                      setAndGetLocationUpdates();

                                                      Navigator.pop(context);

                                                      setState(() {
                                                        colorToShow =
                                                            Colors.pink;
                                                        titleToShow =
                                                            "GO OFFLINE NOW";
                                                        isDriverAvailable =
                                                            true;
                                                      });
                                                    } else {
                                                      //go offline
                                                      goOfflineNow();

                                                      Navigator.pop(context);

                                                      setState(() {
                                                        colorToShow =
                                                            Colors.green;
                                                        titleToShow =
                                                            "GO ONLINE NOW";
                                                        isDriverAvailable =
                                                            false;
                                                      });
                                                    }
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          (titleToShow ==
                                                                  "GO ONLINE NOW")
                                                              ? Colors.green
                                                              : Colors.pink),
                                                  child: const Text("CONFIRM")))
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            });
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: colorToShow),
                      child: Text(titleToShow))
                ],
              ))
        ],
      ),
    );
  }
}

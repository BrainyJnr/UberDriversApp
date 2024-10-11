import 'dart:async';
import 'package:driverapp/authentication/common/network_manager.dart';
import 'package:driverapp/model/trip_details.dart';
import 'package:driverapp/pages/payment_dialog.dart';
import 'package:driverapp/widget/loading_dialogue.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../global/global.dart';
import '../method/theme_methods.dart';

class NewTripPage extends StatefulWidget {
  TripDetails? newTripDetailsInfo;

  NewTripPage({super.key, this.newTripDetailsInfo});

  @override
  State<NewTripPage> createState() => _NewTripPageState();
}

class _NewTripPageState extends State<NewTripPage> {
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  MapThemeMethods themeMethods = MapThemeMethods();
  double googleMapPaddingFromBottom = 0;
  List<LatLng> coOrdinatesPolylineLatLngList = [];
  PolylinePoints polylinePoints = PolylinePoints();
  Set<Marker> markerSet = Set<Marker>();
  Set<Circle> circleSet = Set<Circle>();
  Set<Polyline> polylineSet = Set<Polyline>();
  BitmapDescriptor? carMarkerIcon;
  bool directionRequested = false;
  String statusOfTrip = "accepted", distanceText = "";
  String durationText = "";
  String buttonTitleText = "ARRIVED";
  Color buttonColor = Colors.indigoAccent;
  CommonMethods commonMethods = CommonMethods();
  Marker? currentLocationMarker; // To hold the current location marker

  makeMarker() {
    if (carMarkerIcon == null) {
      ImageConfiguration configuration =
          createLocalImageConfiguration(context, size: Size(2, 2));

      BitmapDescriptor.fromAssetImage(
              configuration, "assets/images/tracking.png")
          .then((valueIcon) {
        carMarkerIcon = valueIcon;
      });
    }
  }

  obtainDirectionAndDrawRoute(
      sourceLocationLatLng, destinationLocationLatLng) async {
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            LoadingDialog(messageText: "Please wait..."));

    var tripDetailsInfo = await CommonMethods.getDirectionDetailsFromAPI(
        sourceLocationLatLng, destinationLocationLatLng);

    Navigator.pop(context);

    PolylinePoints pointPolyline = PolylinePoints();
    List<PointLatLng> LatLngPoints =
        pointPolyline.decodePolyline(tripDetailsInfo!.encodedPoints!);

    coOrdinatesPolylineLatLngList.clear();

    if (LatLngPoints.isNotEmpty) {
      LatLngPoints.forEach((PointLatLng pointLatLng) {
        coOrdinatesPolylineLatLngList
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    //draw polyline
    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
          polylineId: const PolylineId("routeID"),
          color: Colors.amber,
          points: coOrdinatesPolylineLatLngList,
          jointType: JointType.round,
          width: 4,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true);
      polylineSet.add(polyline);
    });

    //fit the polyline on google map
    LatLngBounds boundsLatLng;

    if (sourceLocationLatLng.latitude > destinationLocationLatLng.latitude &&
        sourceLocationLatLng.longitude > destinationLocationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
          southwest: destinationLocationLatLng,
          northeast: sourceLocationLatLng);
    } else if (sourceLocationLatLng.longitude >
        destinationLocationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(
            sourceLocationLatLng.latitude, destinationLocationLatLng.longitude),
        northeast: LatLng(
            destinationLocationLatLng.latitude, sourceLocationLatLng.longitude),
      );
    } else if (sourceLocationLatLng.latitude >
        destinationLocationLatLng.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(
            destinationLocationLatLng.latitude, sourceLocationLatLng.longitude),
        northeast: LatLng(
            sourceLocationLatLng.latitude, destinationLocationLatLng.longitude),
      );
    } else {
      boundsLatLng = LatLngBounds(
          southwest: sourceLocationLatLng,
          northeast: destinationLocationLatLng);
    }

    controllerGoogleMap!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72));

    //add marker

    //add sourceMarker
    Marker sourceMarker = Marker(
      markerId: const MarkerId("sourceID"),
      position: sourceLocationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    //add destinationMarker
    Marker destinationMarker = Marker(
      markerId: const MarkerId("destinationID"),
      position: destinationLocationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );

    setState(() {
      markerSet.add(sourceMarker);
      markerSet.add(destinationMarker);
    });

    //add circle
    Circle sourceCircle = Circle(
        circleId: const CircleId("sourceCircleID"),
        strokeColor: Colors.orange,
        strokeWidth: 4,
        radius: 14,
        center: sourceLocationLatLng,
        fillColor: Colors.green);

    Circle destinationCircle = Circle(
        circleId: const CircleId("destinationCircleID"),
        strokeWidth: 4,
        strokeColor: Colors.green,
        radius: 14,
        center: destinationLocationLatLng,
        fillColor: Colors.orange);

    setState(() {
      circleSet.add(sourceCircle);
      circleSet.add(destinationCircle);
    });
  }

  getLiveLocationUpdatesDriver() {
    LatLng lastPositionLatLng = LatLng(0, 0);

    positionStreamNewTripPage =
        Geolocator.getPositionStream().listen((Position positionDriver) {
      driverCurrentPosition = positionDriver;

      LatLng driverCurrentPositionLatLng = LatLng(
          driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

      Marker carMarker = Marker(
        markerId: MarkerId("carMarkerID"),
        position: driverCurrentPositionLatLng,
        icon: carMarkerIcon!,
        infoWindow: const InfoWindow(title: "My Location"),
      );
      if (mounted) {
        setState(() {
          CameraPosition cameraPosition =
              CameraPosition(target: driverCurrentPositionLatLng, zoom: 16);
          controllerGoogleMap!
              .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

          markerSet.removeWhere(
              (element) => element.markerId.value == "carMarkerID");
          markerSet.add(carMarker);
        });
        lastPositionLatLng = driverCurrentPositionLatLng;

        //update trip details information
        updateTripDetailInformation();

        //update driver location tripRequest
        Map updatedLocationOfDriver = {
          "latitude": driverCurrentPosition!.latitude,
          "longitude": driverCurrentPosition!.longitude,
        };
        FirebaseDatabase.instance
            .ref()
            .child("tripRequests")
            .child(widget.newTripDetailsInfo!.tripID!)
            .child("driverLocation")
            .set(updatedLocationOfDriver);
      }
    });
  }

  updateTripDetailInformation() async {
    if (!directionRequested) {
      directionRequested = true;

      if (directionRequested == null) {
        return;
      }

      var driverLocationLatLng = LatLng(
          driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);
      LatLng dropOffDestinationLocationLatLng;
      if (statusOfTrip == "accepted") {
        dropOffDestinationLocationLatLng =
            widget.newTripDetailsInfo!.pickUpLatLng!;
      } else {
        dropOffDestinationLocationLatLng =
            widget.newTripDetailsInfo!.dropOffLatLng!;
      }
      var directionDetailsInfo = await CommonMethods.getDirectionDetailsFromAPI(
          driverLocationLatLng, dropOffDestinationLocationLatLng);

      if (directionDetailsInfo != null) {
        directionRequested = false;
        setState(() {
          durationText = directionDetailsInfo.durationTextString!;
          distanceText = directionDetailsInfo.distanceTextString!;
        });
      }
    }
  }

  endTripNow() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            LoadingDialog(messageText: "Please wait..."));

    var driverCurrentLocationLatLng = LatLng(
        driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

    var directionDetailsEndTripInfo =
        await CommonMethods.getDirectionDetailsFromAPI(
            widget.newTripDetailsInfo!.pickUpLatLng!,
            driverCurrentLocationLatLng);
    Navigator.pop(context);

    String fareAmount =
        (commonMethods.calculateFareAmount(directionDetailsEndTripInfo!))
            .toString();

    await FirebaseDatabase.instance
        .ref()
        .child("tripRequests")
        .child(widget.newTripDetailsInfo!.tripID!)
        .child("fareAmount")
        .set(fareAmount);

    await FirebaseDatabase.instance
        .ref()
        .child("tripRequests")
        .child(widget.newTripDetailsInfo!.tripID!)
        .child("status")
        .set("ended");

    positionStreamNewTripPage!.cancel();


      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => PaymentDialog(
          fareAmount: fareAmount,    // Pass the distance in kilometers
        ),
      );
    saveFareAmountToDriverTotalEarnings(fareAmount);
    }

    saveFareAmountToDriverTotalEarnings(String fareAmount) async {
    DatabaseReference driverEarningsRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("earnings");

    await driverEarningsRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        double previousTotalEarnings =
            double.parse(snap.snapshot.value.toString());
        double fareAmountForTrip = double.parse(fareAmount);

        double newTotalEarnings = previousTotalEarnings + fareAmountForTrip;

        driverEarningsRef.set(newTotalEarnings);
      } else {
        driverEarningsRef.set(fareAmount);
      }
    });
  }

  SaveDriverDataToTripInfo() async {
    Map<String, dynamic> driverDataMap = {
      "status": "accepted",
      "driverID": FirebaseAuth.instance.currentUser!.uid,
      "driverName": driverName,
      "driverPhone": driverPhone,
      "driverPhoto": driverPhoto,
      "carDetails": carColor + " - " + carModel + " - " + carNumber,
    };
    Map<String, dynamic> driverCurrentLocation = {
      "latitude": driverCurrentPosition!.latitude.toString(),
      "longitude": driverCurrentPosition!.longitude.toString(),
    };
    await FirebaseDatabase.instance
        .ref()
        .child("tripRequests")
        .child(widget.newTripDetailsInfo!.tripID!)
        .update(driverDataMap);

    await FirebaseDatabase.instance
        .ref()
        .child("tripRequests")
        .child(widget.newTripDetailsInfo!.tripID!)
        .child("driverLocation")
        .update(driverCurrentLocation);
  }

  @override
  void initState() {
    // TODO: implement iniState
    super.initState();
    SaveDriverDataToTripInfo();
  }

  @override
  Widget build(BuildContext context) {
    makeMarker();
    return Scaffold(
      body: Stack(
        children: [
          ///google map
          GoogleMap(
            padding: EdgeInsets.only(bottom: googleMapPaddingFromBottom),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            circles: circleSet,
            markers: markerSet,
            polylines: polylineSet,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController) async {
              controllerGoogleMap = mapController;
              themeMethods.updateMapTheme(controllerGoogleMap!);
              googleMapCompleterController.complete(controllerGoogleMap);

              setState(() {
                googleMapPaddingFromBottom = 262;
              });

              var driverCurrentLocationLatLng = LatLng(
                  driverCurrentPosition!.latitude,
                  driverCurrentPosition!.longitude);

              var userPickUpLocationLatLng =
                  widget.newTripDetailsInfo!.pickUpLatLng;

              obtainDirectionAndDrawRoute(
                  driverCurrentLocationLatLng, userPickUpLocationLatLng);

              getLiveLocationUpdatesDriver();
            },
          ),

          ///trip details
          Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(17),
                        topLeft: Radius.circular(17)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 17,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7))
                    ]),
                height: 282,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //trip duration text
                      Center(
                        child: Text(
                          durationText + " - " + distanceText,
                          style: const TextStyle(
                              color: Colors.green, fontSize: 15),
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      //user name - call user icon btn
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //user name
                          Text(widget.newTripDetailsInfo!.userName!,
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),

                          //call user icon btn
                          GestureDetector(
                            onTap: () {
                              launchUrl(Uri.parse(
                                  "tel://${widget.newTripDetailsInfo!.userPhone.toString()}"));
                            },
                            child: Padding(
                              padding: EdgeInsets.only(right: 18),
                              child: Icon(
                                Icons.phone_android_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      //pickup icon and location
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/initial.png",
                            height: 16,
                            width: 16,
                          ),
                          Expanded(
                              child: Text(
                            widget.newTripDetailsInfo!.pickupAddress.toString(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 18, color: Colors.grey),
                          ))
                        ],
                      ),

                      const SizedBox(height: 10),
                      //dropOff icon and location
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/final.png",
                            height: 16,
                            width: 16,
                          ),
                          Expanded(
                              child: Text(
                            widget.newTripDetailsInfo!.dropOffAddress
                                .toString(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 18, color: Colors.grey),
                          ))
                        ],
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      Center(
                        child: ElevatedButton(
                            onPressed: () async {
                              //arrive button
                              if (statusOfTrip == "accepted") {
                                setState(() {
                                  buttonTitleText = "START TRIP";
                                  buttonColor = Colors.green;
                                });

                                statusOfTrip = "arrived";
                                FirebaseDatabase.instance
                                    .ref()
                                    .child("tripRequests")
                                    .child(widget.newTripDetailsInfo!.tripID!)
                                    .child("status")
                                    .set("arrived");

                                showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (BuildContext context) =>
                                        LoadingDialog(
                                            messageText: "Please wait..."));

                                await obtainDirectionAndDrawRoute(
                                    widget.newTripDetailsInfo!.pickUpLatLng,
                                    widget.newTripDetailsInfo!.dropOffLatLng);

                                Navigator.pop(context);

                                //start button
                              } else if (statusOfTrip == "arrived") {
                                setState(() {
                                  buttonTitleText = "END TRIP";
                                  buttonColor = Colors.amber;
                                });

                                statusOfTrip = "ontrip";

                                FirebaseDatabase.instance
                                    .ref()
                                    .child("tripRequests")
                                    .child(widget.newTripDetailsInfo!.tripID!)
                                    .child("status")
                                    .set("ontrip");

                                //end the trip
                              } else if (statusOfTrip == "ontrip") {
                                //end the trip
                                endTripNow();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                            ),
                            child: Text(
                              buttonTitleText,
                              style: const TextStyle(color: Colors.white),
                            )),
                      )
                    ],
                  ),
                ),
              ))
        ],
      ),
    );
  }
}



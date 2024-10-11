import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:driverapp/global/global.dart';
import 'package:driverapp/model/trip_details.dart';
import 'package:driverapp/widget/loading_dialogue.dart';
import 'package:driverapp/widget/notification_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PushNotificationSystem {
  FirebaseMessaging firebaseCloudMessaging = FirebaseMessaging.instance;

  Future<String?> generateDeviceRegistrationToken() async {
    String? deviceRecognitionToken = await firebaseCloudMessaging.getToken();

    DatabaseReference referenceOnlineDriver = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("deviceToken");

    referenceOnlineDriver.set(deviceRecognitionToken);

    firebaseCloudMessaging.subscribeToTopic("drivers");
    firebaseCloudMessaging.subscribeToTopic("users");
  }

  startListeningForNewNotification(BuildContext context) async {
    ///1. Terminated
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? messageRemote) {
      if (messageRemote != null && messageRemote.data.isNotEmpty) {
        String tripID = messageRemote.data["tripID"];
        handleNotification(tripID, context);
      }
    });

    ///2. Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage? messageRemote) {
      if (messageRemote != null && messageRemote.data.isNotEmpty) {
        String? tripID = messageRemote.data["tripID"];
        handleNotification(tripID, context);
      }
    });

    ///3. Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? messageRemote) {
      if (messageRemote != null && messageRemote.data.isNotEmpty) {
        String tripID = messageRemote.data["tripID"];
        handleNotification(tripID, context);
      }
    });
  }

  void handleNotification(String? tripID, BuildContext context) {
    if (tripID != null && tripID.isNotEmpty) {
      retrieveTripRequestInfo(tripID, context);
    } else {
      print('tripID is null or empty');
    }
  }

  void retrieveTripRequestInfo(String tripID, BuildContext context) {
    // Show loading dialog while retrieving data
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(messageText: "Getting details..."),
    );

    DatabaseReference tripRequestRef = FirebaseDatabase.instance.ref().child("tripRequests").child(tripID);

    tripRequestRef.once().then((dataSnapshot) {
      Navigator.pop(context); // Dismiss loading dialog

      // Check if the snapshot contains data
      if (dataSnapshot.snapshot.exists && dataSnapshot.snapshot.value != null) {
        TripDetails tripDetailsInfo = TripDetails();

        // Extract trip status
        String tripStatus = (dataSnapshot.snapshot.value as Map)["status"] as String? ?? "";

        // Skip processing if the trip is already completed
        if (tripStatus == "completed") {
          _showErrorDialog(context, "Trip has already been completed.");
          return;
        }

        // Extract trip details (coordinates, addresses, etc.)
        double dropOffLat = double.parse((dataSnapshot.snapshot.value as Map)["dropOffLatLng"]["latitude"].toString());
        double dropOffLng = double.parse((dataSnapshot.snapshot.value as Map)["dropOffLatLng"]["longitude"].toString());
        tripDetailsInfo.dropOffLatLng = LatLng(dropOffLat, dropOffLng);
        tripDetailsInfo.dropOffAddress = (dataSnapshot.snapshot.value as Map)["dropOffAddress"] as String;

        double pickUpLat = double.parse((dataSnapshot.snapshot.value as Map)["pickUpLatLng"]["latitude"].toString());
        double pickUpLng = double.parse((dataSnapshot.snapshot.value as Map)["pickUpLatLng"]["longitude"].toString());
        tripDetailsInfo.pickUpLatLng = LatLng(pickUpLat, pickUpLng);
        tripDetailsInfo.pickupAddress = (dataSnapshot.snapshot.value as Map)["pickupAddress"] as String;

        // Extract user information
        tripDetailsInfo.userName = (dataSnapshot.snapshot.value as Map)["userName"] as String?;
        tripDetailsInfo.userPhone = (dataSnapshot.snapshot.value as Map)["userPhone"] as String?;
        tripDetailsInfo.tripID = tripID;

        // Show the notification dialog with trip details
        showDialog(
          context: context,
          builder: (BuildContext context) => NotificationDialog(tripDetailsInfo: tripDetailsInfo),
        );
      } else {
        _showErrorDialog(context, "Trip request not found.");
      }
    }).catchError((error) {
      Navigator.pop(context); // Dismiss loading dialog on error
      print('Error retrieving trip: $error');
      _showErrorDialog(context, "Error retrieving trip details.");
    });
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

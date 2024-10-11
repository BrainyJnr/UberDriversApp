import 'dart:async';
import 'package:driverapp/authentication/common/network_manager.dart';
import 'package:driverapp/global/global.dart';
import 'package:driverapp/model/trip_details.dart';
import 'package:driverapp/pages/new_trip_page.dart';
import 'package:driverapp/widget/loading_dialogue.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';


class NotificationDialog extends StatefulWidget {
  final TripDetails? tripDetailsInfo;

  NotificationDialog({super.key, this.tripDetailsInfo});

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  String tripRequestStatus = "";
  bool isDialogClosed = false; // Track if dialog is already closed
  bool tripAccepted = false; // Track if the trip has been accepted
  int driverTripRequestTimeout = 20; // Timeout in seconds
  CommonMethods cMethods = CommonMethods();
  late Timer timerCountDown;

  cancelNotificationDialogueAfter20Sec() {
    const oneTickPerSecond = Duration(seconds: 1);

    timerCountDown = Timer.periodic(oneTickPerSecond, (timer) {
      if (mounted) {
        setState(() {
          driverTripRequestTimeout -= 1;
        });

        // If trip is accepted or timeout ends, cancel the timer and close dialog
        if (tripRequestStatus == "accepted" || driverTripRequestTimeout == 0) {
          if (!isDialogClosed) {
            Navigator.pop(context);
            isDialogClosed = true; // Mark dialog as closed
          }
          timer.cancel();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (!tripAccepted) {
      cancelNotificationDialogueAfter20Sec();
    }
  }

  @override
  void dispose() {
    // Make sure to cancel the timer when the widget is disposed
    if (timerCountDown.isActive) {
      timerCountDown.cancel();
    }
    super.dispose();
  }

  checkAvailabilityOfTripRequest(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            LoadingDialog(messageText: "please wait..."));

    DatabaseReference driverTripStatusRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("newTripStatus");

    await driverTripStatusRef.once().then((snap) {
      Navigator.pop(context); // Close loading dialog
      if (!isDialogClosed) {
        Navigator.pop(context); // Close the trip notification dialog
        isDialogClosed = true; // Mark dialog as closed
      }

      String newTripStatusValue = "";

      if (snap.snapshot.value != null) {
        newTripStatusValue = snap.snapshot.value.toString();
      } else {
        cMethods.displaySnackBar(
            "Trip request not found mannnnnnnnnnnnn...", context);
      }
      if (newTripStatusValue == widget.tripDetailsInfo!.tripID) {
        driverTripStatusRef.set("accepted");
        setState(() {
          tripAccepted = true; // Mark trip as accepted
        });

        // Disable homepage location updates
        cMethods.turnOffLocationUpdatesFromHomePage();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                NewTripPage(newTripDetailsInfo: widget.tripDetailsInfo),
          ),
        );
      } else {
        if (newTripStatusValue == "cancelled") {
          cMethods.displaySnackBar(
              "Trip Request has been cancelled by user", context);
        } else if (newTripStatusValue == "timeout") {
          cMethods.displaySnackBar("Trip Request has timed out", context);
        } else {
          cMethods.displaySnackBar("Trip Request not found", context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return tripAccepted || isDialogClosed
        ? const SizedBox() // If trip is accepted or dialog is closed, don't show anything
        : Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Container(
        margin: const EdgeInsets.all(5),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(4)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 30.0),
            Image.asset(
              "assets/images/uberexec.png",
              width: 140,
            ),
            const SizedBox(height: 16.0),
            const Text(
              "NEW TRIP REQUEST",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey),
            ),
            const SizedBox(height: 20.0),
            Divider(
              height: 1,
              color: Colors.white,
              thickness: 1,
            ),
            const SizedBox(height: 10.0),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Pickup
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        "assets/images/initial.png",
                        height: 15,
                        width: 16,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                          child: Text(
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              widget.tripDetailsInfo!.pickupAddress
                                  .toString(),
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 18)))
                    ],
                  ),
                  const SizedBox(height: 15),
                  // DropOff
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        "assets/images/final.png",
                        height: 15,
                        width: 16,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                          child: Text(
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              widget.tripDetailsInfo!.dropOffAddress
                                  .toString(),
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 18)))
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(
              height: 1,
              color: Colors.white,
              thickness: 1,
            ),
            const SizedBox(height: 8),
            // Decline and Accept buttons
            Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (!isDialogClosed) {
                          Navigator.pop(context);
                          isDialogClosed = true; // Prevent further pops
                        }
                        audioPlayer.stop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                      ),
                      child: Text(
                        "DECLINE",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (!tripAccepted && !isDialogClosed) {
                          setState(() {
                            tripRequestStatus = "accepted";
                            isDialogClosed = true; // Close the dialog
                          });
                          audioPlayer.stop();
                          checkAvailabilityOfTripRequest(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
                        "ACCEPT",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}


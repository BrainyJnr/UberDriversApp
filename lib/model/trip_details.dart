import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:firebase_database/firebase_database.dart'; // For Realtime Database

class TripDetails {
  String? tripID;

  LatLng? pickUpLatLng;
  LatLng? originLatLng;
  String? pickupAddress;

  LatLng? dropOffLatLng;
  String? dropOffAddress;

  String? userName;
  String? userPhone;

  TripDetails({
    this.originLatLng,
    this.tripID,
    this.pickUpLatLng,
    this.pickupAddress,
    this.dropOffAddress,
    this.dropOffLatLng,
    this.userName,
    this.userPhone,
  });

  // Factory constructor to create a TripDetails instance from a DataSnapshot
  factory TripDetails.fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>;

    return TripDetails(
      tripID: data['tripID'] ?? '',
      pickUpLatLng: LatLng(
        data['pickUpLatLng']['latitude'] ?? 0.0,
        data['pickUpLatLng']['longitude'] ?? 0.0,
      ),
      pickupAddress: data['pickupAddress'] ?? '',
      dropOffLatLng: LatLng(
        data['dropOffLatLng']['latitude'] ?? 0.0,
        data['dropOffLatLng']['longitude'] ?? 0.0,
      ),
      dropOffAddress: data['dropOffAddress'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? '',
    );
  }
}

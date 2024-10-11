import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class TripsHistoryPage extends StatefulWidget {
  const TripsHistoryPage({super.key});

  @override
  State<TripsHistoryPage> createState() => _TripsHistoryPageState();
}

class _TripsHistoryPageState extends State<TripsHistoryPage> {
  final completedTripRequestedOfCurrentDriver =
  FirebaseDatabase.instance.ref().child("tripRequests");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Completed Trips",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder(
        stream: completedTripRequestedOfCurrentDriver.onValue,
        builder: (BuildContext context, snapshotData) {
          if (snapshotData.hasError) {
            return const Center(
              child: Text(
                "Error Occurred",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (snapshotData.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshotData.hasData || snapshotData.data!.snapshot.value == null) {
            return const Center(
              child: Text(
                "No record found",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          Map dataTrips = snapshotData.data!.snapshot.value as Map;
          List tripList = [];
          dataTrips.forEach((key, value) => tripList.add({"key": key, ...value}));

          if (tripList.isEmpty) {
            return const Center(
              child: Text(
                "No completed trips available",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: tripList.length,
            itemBuilder: ((context, index) {
              if (tripList[index]["status"]  != null && tripList[index]["status"] == "ended" &&
                  tripList[index]["driverID"] ==
                      FirebaseAuth.instance.currentUser!.uid) {
                return Card(
                  color: Colors.white12,
                  elevation: 10,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              "assets/images/initial.png",
                              height: 5,
                              width: 16,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tripList[index]["pickupAddress"].toString(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white38,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                             "\$ " + tripList[index]["fareAmount"].toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Image.asset(
                              "assets/images/final.png",
                              height: 14,
                              width: 16,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tripList[index]["dropOffAddress"].toString(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white38,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Container();
              }
            }),
          );
        },
      ),
    );
  }
}


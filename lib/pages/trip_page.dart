import 'package:driverapp/pages/trips_history_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class TripPage extends StatefulWidget {
  const TripPage({super.key});

  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  String currentDriverTotalTripCompleted = "";

  @override
  void initState() {
    super.initState();
    getCurrentDriverTotalNumberOfTripsCompleted(); // Fetch total trips when the widget is built
  }

  getCurrentDriverTotalNumberOfTripsCompleted() async {
    DatabaseReference tripRequestsRef =
    FirebaseDatabase.instance.ref().child("tripRequests");

    await tripRequestsRef.once().then((snap) async {
      if (snap.snapshot.value != null) {
        Map<dynamic, dynamic> allTripsMap = snap.snapshot.value as Map;
        int allTripsLength = allTripsMap.length;

        List<String> tripsCompletedByCurrentDriver = [];

        allTripsMap.forEach((key, value) {
          if (value["status"] != null) {
            if (value["status"] == "ended") {
              if (value["driverID"] ==
                  FirebaseAuth.instance.currentUser!.uid) {
                tripsCompletedByCurrentDriver.add(key);
              }
            }
          }
        });

        // Update the UI once the data is fetched
        setState(() {
          currentDriverTotalTripCompleted =
              tripsCompletedByCurrentDriver.length.toString();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Total Trips
            Center(
              child: Container(
                color: Colors.indigo,
                width: 300,
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/images/totaltrips.png",
                        width: 120,
                      ),
                      const SizedBox(
                        height: 10, // Adjusted to height instead of width for proper spacing
                      ),
                      const Text(
                        "Total Trips",
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        currentDriverTotalTripCompleted, // This will now show once data is fetched
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20,),

            //check trip history
            GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (c) => TripsHistoryPage()));
              },
              child: Center(
                child: Container(
                  color: Colors.indigo,
                  width: 300,
                  child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/images/tripscompleted.png",
                          width: 150,
                        ),
                        const SizedBox(
                          height: 10, // Adjusted to height instead of width for proper spacing
                        ),

                        const Text("Check Trips History",
                        style: TextStyle(
                          color: Colors.white
                        ),)
                      ],
                    ),
                  ),
                ),
              ),
            ),

          ],
        ));
  }
}


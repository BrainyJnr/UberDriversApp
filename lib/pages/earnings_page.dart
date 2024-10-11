import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class EarningPage extends StatefulWidget {
  const EarningPage({super.key});

  @override
  State<EarningPage> createState() => _EarningPageState();
}

class _EarningPageState extends State<EarningPage> {

  String driverEarnings = "";

  getTotalEarningsOfCurrentDriver() async {
    DatabaseReference driverRef =
        FirebaseDatabase.instance.ref().child("drivers");

    await driverRef
        .child(FirebaseAuth.instance.currentUser!.uid)
        .once()
        .then((snap) {
          if((snap.snapshot.value as Map)["earnings"] != null){

            setState(() {
              driverEarnings = ((snap.snapshot.value as Map)["earnings"]).toString();
            });

          }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getTotalEarningsOfCurrentDriver();
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
                    "assets/images/totalearnings.png",
                    width: 120,
                  ),
                  const SizedBox(
                    height:
                        10, // Adjusted to height instead of width for proper spacing
                  ),
                  const Text(
                    "Total Earnings",
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    "\$" + driverEarnings,
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

      ],
    ));
  }
}

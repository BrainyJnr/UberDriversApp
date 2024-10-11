import 'package:driverapp/authentication/common/network_manager.dart';
import 'package:driverapp/authentication/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:restart_app/restart_app.dart';

class PaymentDialog extends StatefulWidget {
  final double distanceKm; // Distance in kilometers
  final double durationMinutes; // Duration in minutes

  PaymentDialog({super.key, required this.distanceKm, required this.durationMinutes, required String fareAmount});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  CommonMethods commonMethods = CommonMethods();

  // Fare calculation parameters
  double baseFare = 5.0;         // Base fare for starting the ride
  double costPerKm = 1.2;        // Cost per kilometer
  double costPerMinute = 0.5;    // Cost per minute

  // Function to calculate the total fare
  double calculateFare() {
    double totalFare = baseFare + (costPerKm * widget.distanceKm) + (costPerMinute * widget.durationMinutes);
    return totalFare;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the total fare
    double fareAmount = calculateFare();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.black54,
      child: Container(
        margin: const EdgeInsets.all(5.0),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.black87, borderRadius: BorderRadius.circular(6)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const SizedBox(height: 22,),

            const Text("COLLECT CASH", style: TextStyle(
                color: Colors.grey
            ),),

            const SizedBox(height: 21,),

            const Divider(height: 1.5, color: Colors.white70, thickness: 1.0,),

            const SizedBox(height: 16,),

            // Display the calculated fare amount
            Text("\$${fareAmount.toStringAsFixed(2)}",
              style: const TextStyle(
                  color: Colors.grey, fontSize: 36, fontWeight: FontWeight.bold
              ),),

            const SizedBox(height: 16,),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text("This is the fare amount ( \$${fareAmount.toStringAsFixed(2)} ) you have to pay to the driver.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),

            ElevatedButton(onPressed: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => PaidScreen() "paid");

              // Example restart action (if necessary)
              Restart.restartApp();
            },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green
                ),
                child: const Text("PAY CASH")),

            const SizedBox(height: 20,)
          ],
        ),
      ),
    );
  }
}


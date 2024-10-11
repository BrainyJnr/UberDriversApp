import 'package:driverapp/authentication/signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../pages/dashboard_screen.dart';
import '../widget/loading_dialogue.dart';
import 'common/network_manager.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController PassswordTextEditingController =
  TextEditingController();
  CommonMethods cMethods = CommonMethods();

  checkIfNetworkIsAvailable() {
    //cMethods.checkConnectivity(context);
    //cMethods.checkConnectivity(context);
    signinFormValidation();
  }

  signinFormValidation() {
    if (!emailTextEditingController.text.contains("@")) {
      cMethods.displaySnackBar("Pls write a verified email", context);
    } else if (PassswordTextEditingController.text.trim().length < 4) {
      cMethods.displaySnackBar(
          "Your phone number must be at least 4 characters", context);
    } else {
      SignInUser();
    }
  }

  SignInUser() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
      const LoadingDialog(messageText: "Logging your account..."),
    );

    try {
      final User? userFirebase = (await FirebaseAuth.instance
          .signInWithEmailAndPassword(
          email: emailTextEditingController.text.trim(),
          password: PassswordTextEditingController.text.trim())).user;

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      if (userFirebase != null) {
        DatabaseReference userRef = FirebaseDatabase.instance
            .ref()
            .child("drivers")
            .child(userFirebase.uid);

        final snap = await userRef.once();

        if (snap.snapshot.value != null) {
          // User exists, check BlockStatus
          Map userData = snap.snapshot.value as Map;

          if (userData["BlockStatus"] == "no") {
            //  userName = userData["name"];
            Navigator.push(
                context, MaterialPageRoute(builder: (c) => DashboardScreen()));
          } else {
            // User is blocked, sign them out and show message
            FirebaseAuth.instance.signOut();
            cMethods.displaySnackBar(
                "You are blocked. Contact admin: godwinchimdikefavour@gmail.com",
                context);
          }
        } else {
          // User does not exist in the database, sign out and show message
          FirebaseAuth.instance.signOut();
          cMethods.displaySnackBar("Your record does not exist as a Driver", context);
        }
      } else {
        // Sign-in failed, show an error message
        cMethods.displaySnackBar("Sign-in failed. Please check your credentials.", context);
      }
    } catch (error) {
      // Handle any other errors
      Navigator.pop(context);
      cMethods.displaySnackBar("Error: ${error.toString()}", context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Image(
              image: const AssetImage("assets/images/uberexec.png"),
            ),
            Text(
              "Login as a Driver",
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: EdgeInsets.all(22),
              child: Column(
                children: [
                  TextField(
                    controller: emailTextEditingController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Driver's Email",
                      labelStyle: TextStyle(fontSize: 14),
                    ),
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: PassswordTextEditingController,
                    keyboardType: TextInputType.text,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Driver's  Password",
                      labelStyle: TextStyle(fontSize: 14),
                    ),
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                      onPressed: () {
                        checkIfNetworkIsAvailable();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal:
                            width * 0.3, // Responsive horizontal padding
                          )),
                      child: Text("Log In"))
                ],
              ),
            ),
            TextButton(
                onPressed: () {
                  Get.to(SignUpScreen());
                },
                child: Text("Don\'t have an account? Register Here"))
          ],
        ),
      ),
    );
  }
}
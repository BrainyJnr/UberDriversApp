import 'package:driverapp/pages/dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:permission_handler/permission_handler.dart';

import 'authentication/signin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyDtk-4rLokV7sA5TH1Y6qrOJTigbPu-yEk",
          authDomain: "ubercloneuser-39a46.firebaseapp.com",
          projectId: "ubercloneuser-39a46",
          storageBucket: "ubercloneuser-39a46.appspot.com",
          messagingSenderId: "194920093414",
          appId: "1:194920093414:web:671c0916ab000720974d27",
          measurementId: "G-ZC45QESQ97"));

  // Request permission for location
//  await Permission.locationWhenInUse.request().then((status) {
//     if (status.isDenied) {
//       // Handle the case when permission is denied
//       print('Location permission denied.');
//     }
//   });

  await Permission.locationWhenInUse.isDenied.then((valueOfPermission) {
    if (valueOfPermission) {
      Permission.locationWhenInUse.request();
    }
  });

  await Permission.notification.isDenied.then((valueOfPermission) {
    if (valueOfPermission) {
      Permission.notification.request();
    }
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "Drivers App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: FirebaseAuth.instance.currentUser == null
          ? LoginScreen()
          : DashboardScreen(), // Redirect to HomePage if user is logged in
    );
  }
}

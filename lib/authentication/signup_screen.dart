import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:driverapp/authentication/signin_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../pages/dashboard_screen.dart';
import '../widget/loading_dialogue.dart';
import 'common/network_manager.dart';



class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  TextEditingController userNameTextEditingController = TextEditingController();
  TextEditingController userPhoneTextEditingController =
  TextEditingController();
  TextEditingController VehicleModelTextEditingController =
  TextEditingController();
  TextEditingController VehicleColorTextEditingController =
  TextEditingController();
  TextEditingController VehicleNumberTextEditingController =
  TextEditingController();
  CommonMethods cMethods = CommonMethods();
  XFile? imageFile;
  String urlOfUploadedImage = "";

  checkIfNetworkIsAvailable() {
   // cMethods.checkConnectivity(context);

    if (imageFile != null) {
      // image validation
      signupFormValidation();
    } else {
      cMethods.displaySnackBar("Please choose image first", context);
    }
  }


  signupFormValidation() {
    if (userNameTextEditingController.text.trim().length < 4) {
      cMethods.displaySnackBar(
          "Your name must be at least 4 characters", context);
    } else if (userPhoneTextEditingController.text.trim().length < 4) {
      cMethods.displaySnackBar(
          "Your phone number must be at least 4 characters", context);
    } else if (!emailTextEditingController.text.contains("@")) {
      cMethods.displaySnackBar("Please enter a valid email", context);
    } else if (passwordTextEditingController.text.trim().length < 6) {
      cMethods.displaySnackBar(
          "Your password must be at least 6 characters.", context);
    } else if (VehicleModelTextEditingController.text.trim().isEmpty) {
      cMethods.displaySnackBar("Please write your car model.", context);
    } else if (VehicleColorTextEditingController.text.trim().isEmpty) {
      cMethods.displaySnackBar("Please write your car color.", context);
    } else if (VehicleNumberTextEditingController.text.trim().isEmpty) {
      cMethods.displaySnackBar("Please write your car number.", context);
    } else {
      uploadImageToStorage();
    }
  }

  uploadImageToStorage() async {
    String imageIDName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceImage =
    FirebaseStorage.instance.ref().child('Images').child(imageIDName);

    UploadTask uploadTask = referenceImage.putFile(File(imageFile!.path));
    TaskSnapshot snapshot = await uploadTask;
    urlOfUploadedImage = await snapshot.ref.getDownloadURL();

    setState(() {
      urlOfUploadedImage;
    });

    registerNewDriver();
  }


  registerNewDriver() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
      const LoadingDialog(messageText: "Registering your account..."),
    );
    try {
      // Register new user
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailTextEditingController.text.trim(),
        password: passwordTextEditingController.text.trim(),
      );

      User? userFirebase = userCredential.user;

      if (userFirebase != null) {
        // Write user data to Firebase Realtime Database
        DatabaseReference userRef = FirebaseDatabase.instance
            .ref()
            .child("drivers")
            .child(userFirebase.uid);

        Map driverCarInfo = {
          "carColor": VehicleColorTextEditingController.text.trim(),
          "carModel": VehicleModelTextEditingController.text.trim(),
          "carNumber": VehicleNumberTextEditingController.text.trim(),
        };

        Map driverDataMap = {
          "photo": urlOfUploadedImage,
          "car_details": driverCarInfo,
          "name": userNameTextEditingController.text.trim(),
          "email": emailTextEditingController.text.trim(),
          "phone": userPhoneTextEditingController.text.trim(),
          "id": userFirebase.uid,
          "BlockStatus": "no",
        };

        userRef.set(driverDataMap);

        // Success message and navigation to Home Page
        cMethods.displaySnackBar("Account registered successfully!", context);

        if (!context.mounted) return;
        Navigator.pop(context); // Close the loading dialog
        Get.to(DashboardScreen()); // Navigate to the home page
      } else {
        throw Exception("Driver's  registration failed");
      }
    } catch (error) {
      Navigator.pop(context); // Close the loading dialog in case of error
      cMethods.displaySnackBar(error.toString(), context);
    }
  }

  chooseImageFromGallery() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imageFile = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    return Scaffold(
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              SizedBox(
                height: screenSize.height * 0.10,
              ),
              imageFile == null
                  ? CircleAvatar(
                radius: screenSize.width * 0.23,
                backgroundImage:
                AssetImage("assets/images/avatarman.png"),
              )
                  : Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey,
                    image: DecorationImage(
                        fit: BoxFit.fitHeight,
                        image: FileImage(File(
                          imageFile!.path,
                        )))),
              ),
              SizedBox(
                height: 5,
              ),
              GestureDetector(
                onTap: () {
                  chooseImageFromGallery();
                },
                child: const Text(
                  "Select Image",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 30, left: 10, right: 10),
                child: Column(
                  children: [
                    TextField(
                      controller: userNameTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: "Driver  Name",
                        labelStyle: TextStyle(fontSize: 14),
                      ),
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: userPhoneTextEditingController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Driver  Phone",
                        labelStyle: TextStyle(fontSize: 14),
                      ),
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Driver Email",
                        labelStyle: TextStyle(fontSize: 14),
                      ),
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordTextEditingController,
                      keyboardType: TextInputType.text,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Driver  Password",
                        labelStyle: TextStyle(fontSize: 14),
                      ),
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: VehicleModelTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: "Driver  Model",
                        labelStyle: TextStyle(fontSize: 14),
                      ),
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: VehicleColorTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: "Driver  Vehicle Color",
                        labelStyle: TextStyle(fontSize: 14),
                      ),
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: VehicleNumberTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: "Driver  Vehicle Number",
                        labelStyle: TextStyle(fontSize: 14),
                      ),
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        checkIfNetworkIsAvailable();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.3,
                          // Responsive horizontal padding
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        "Sign Up",
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Get.to(LoginScreen());
                },
                child: const Text("Already have an account? Login Here"),
              ),
            ])));
  }
}
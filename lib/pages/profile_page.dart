import 'package:driverapp/authentication/signin_screen.dart';
import 'package:driverapp/global/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController carTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();

  setDriverInfo(){
    setState(() {
      nameTextEditingController.text = driverName;
      phoneTextEditingController.text = driverPhone;
      carTextEditingController.text = FirebaseAuth.instance.currentUser!.email.toString();
      emailTextEditingController.text = carNumber + " - " + carColor + " - " + carModel;

    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    setDriverInfo();
  }
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              //Image
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey,
                    image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(driverPhoto),
                        ))),

              const SizedBox(height: 16,),

              //driver name
              Padding(
                padding: EdgeInsets.only(left: 18.0,right: 18.0,top: 20),
                child: TextField(
                  controller: nameTextEditingController,
                  textAlign: TextAlign.center,
                  enabled: false,
                  style: const TextStyle(fontSize: 14,color: Colors.white),
                  decoration: const InputDecoration(
                    filled: true,fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.white,
                        width: 2

                      )
                    ),
                    prefixIcon: Icon(Icons.person,
                      color: Colors.white,)

                  ),

                ),
              ),

              //driver phone
              Padding(
                padding: EdgeInsets.only(left: 18.0,right: 18.0,top: 4),
                child: TextField(
                  controller: phoneTextEditingController,
                  textAlign: TextAlign.center,
                  enabled: false,
                  style: const TextStyle(fontSize: 14,color: Colors.white),
                  decoration: const InputDecoration(
                      filled: true,fillColor: Colors.white24,
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.white,
                              width: 2

                          )
                      ),
                      prefixIcon: Icon(Icons.phone_android_outlined,
                        color: Colors.white,)

                  ),

                ),
              ),

              Padding(
                padding: EdgeInsets.only(left: 18.0,right: 18.0,top: 4),
                child: TextField(
                  controller: emailTextEditingController,
                  textAlign: TextAlign.center,
                  enabled: false,
                  style: const TextStyle(fontSize: 14,color: Colors.white),
                  decoration: const InputDecoration(
                      filled: true,fillColor: Colors.white24,
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.white,
                              width: 2

                          )
                      ),
                      prefixIcon: Icon(Icons.drive_eta_rounded,
                        color: Colors.white,)

                  ),

                ),
              ),

              Padding(
                padding: EdgeInsets.only(left: 18.0,right: 18.0,top: 4),
                child: TextField(
                  controller: carTextEditingController,
                  textAlign: TextAlign.center,
                  enabled: false,
                  style: const TextStyle(fontSize: 14,color: Colors.white),
                  decoration: const InputDecoration(
                      filled: true,fillColor: Colors.white24,
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.white,
                              width: 2

                          )
                      ),
                      prefixIcon: Icon(Icons.email,
                        color: Colors.white,)

                  ),

                ),
              ),

              const SizedBox(height: 14),

              //logout btn
              ElevatedButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
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
                  "Logout",
                ),
              ),


            ]),
        ),
          ),


    );
  }
}

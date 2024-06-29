import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'features/auth/data/firebase.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuthService().authInstance.currentUser;
    if (user != null) {
      // Change this to actual Dashboard Widget (once made)
      return const Dashboard();
    } else {
      return const AuthenticationPage();
    }
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final cloudMessagingApiUrl = 'https://fcm.googleapis.com/fcm/send';
  String? token = '';
  String fullName = '';
  void updateMyToken() async {
    token = await FirebaseMessaging.instance.getToken();
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance
        .collection('FcmTokens')
        .doc(uid)
        .set({'token': token});

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .get()
        .then((value) {
      fullName = value.data()!['fullName'];
    });
  }

  void setupInAppDialog() {
    TextEditingController responseController = TextEditingController();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                backgroundColor: Colors.black,
                title: Text(
                  message.notification!.title ?? "",
                  style: const TextStyle(color: Colors.white),
                ),
                content: Wrap(
                  children: [
                    if (message.notification!.title == 'Ride Request')
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          controller: responseController,
                          decoration: const InputDecoration(
                              hintText: 'Fare for the Ride',
                              hintStyle: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    Text(
                      message.notification!.body ?? "",
                      style: const TextStyle(color: Colors.white),
                    )
                  ],
                ),
                actions: <Widget>[
                  if (message.notification!.title == 'Ride Request') ...[
                    TextButton(
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.red,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        responseController.clear();
                      },
                    ),
                    TextButton(
                      child: const Text(
                        'Accept',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.green,
                        ),
                      ),
                      onPressed: () {
                        if (responseController.text == '') {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text('Please enter fare for the ride'),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }
                        if (token == '') {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text(
                                'Something went wrong, please try restarting the app'),
                            backgroundColor: Colors.red,
                          ));
                          Navigator.pop(context);
                          return;
                        }
                        http.post(Uri.parse(cloudMessagingApiUrl),
                            headers: {
                              "Content-Type": "application/json",
                              "Authorization":
                                  "key=AAAACjgM6cI:APA91bGtSocRefhqegUzpstlLc7t7ycNzsAqCtEMXe9GvDcTxrPlekq_6WFGi0IMpiKh1iY9viCgoxOiXMhz6_GoQGWbXmgJ8eOP4aB8ae_NoY8dO4ojTnaQR0x0ZYwID7miuM0ETIR7"
                            },
                            body: jsonEncode({
                              "to": message.data['fcm-token'],
                              "notification": {
                                "body": responseController.text,
                                "title": "Driver Response:"
                              },
                              "data": {"fcm-token": token}
                            }));
                        Navigator.of(context).pop();
                        responseController.clear();
                      },
                    ),
                  ] else if (message.notification!.title ==
                      'Fare Accepted') ...[
                    TextButton(
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.green,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        http.post(Uri.parse(cloudMessagingApiUrl),
                            headers: {
                              "Content-Type": "application/json",
                              "Authorization":
                                  "key=AAAACjgM6cI:APA91bGtSocRefhqegUzpstlLc7t7ycNzsAqCtEMXe9GvDcTxrPlekq_6WFGi0IMpiKh1iY9viCgoxOiXMhz6_GoQGWbXmgJ8eOP4aB8ae_NoY8dO4ojTnaQR0x0ZYwID7miuM0ETIR7"
                            },
                            body: jsonEncode({
                              "to": message.data['fcm-token'],
                              "notification": {
                                "body":
                                    "Driver Name: \n$fullName\nPhone Number:\n${FirebaseAuth.instance.currentUser!.phoneNumber}",
                                "title": "Contact Number"
                              }
                            }));
                      },
                    ),
                  ]
                ],
              ));
    });
  }

  @override
  void initState() {
    updateMyToken();
    setupInAppDialog();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Ghumo'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                // Signing out the current user, directing her to Authentication Page again
                FirebaseAuthService().signOut();
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) =>
                            const AuthenticationPage()));
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: const Center(
          child: Text("Waiting for rides :)"),
        ));
  }

  @override
  void dispose() {
    super.dispose();
  }
}

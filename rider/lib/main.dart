// for fcm
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
// -- for fcm

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rider/features/auth/data/firebase.dart';
import 'package:rider/features/auth/presentation/pages/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/ride_direction/presentation/bloc/ride_direction_bloc.dart';
import 'features/ride_direction/presentation/pages/home.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
          BlocProvider<RideDirectionBloc>(
            create: (context) => RideDirectionBloc(),
          ),
          BlocProvider(
            create: (context) => AuthenticationBloc(),
          )
    ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Home(),
      )
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
      return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(),
      );
    } else {
      return const AuthenticationPage();
    }
  }
}


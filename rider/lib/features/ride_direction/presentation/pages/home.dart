import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider/features/ride_direction/presentation/bloc/ride_direction_bloc.dart';
import 'package:rider/features/ride_direction/presentation/pages/search.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/address.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Home();
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String myFcmToken = "";

  final Completer<GoogleMapController> _controllerGoogleMap =
      Completer<GoogleMapController>();
  CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14,
  );
  Address userCurrentLocation = Address();
  double bottomPaddingOfMap = 0.0;
  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};
  late GoogleMapController newGoogleMapController;

  bool isBookRide = false;
  bool isSnackBar = false;
  String errorMessage = "";

  final cloudMessagingApiUrl = 'https://fcm.googleapis.com/fcm/send';

  Future<List<String>> getDriverTokens() async {
    var snapshot = await FirebaseFirestore.instance.collection('FcmTokens').get();
    return snapshot.docs
        .map((doc) => (doc.data()['token']).toString())
        .toList();
  }

  Future<void> requestRide(String pickupLocation, String dropLocation) async {
    List<String> driverTokens = await getDriverTokens();
    if (driverTokens == []) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No driver available right now...')));
      return;
    }
    if (myFcmToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unable to share details, please try restarting app')));
      return;
    }

    var response = await http.post(Uri.parse(cloudMessagingApiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization":
              "key=AAAACjgM6cI:APA91bGtSocRefhqegUzpstlLc7t7ycNzsAqCtEMXe9GvDcTxrPlekq_6WFGi0IMpiKh1iY9viCgoxOiXMhz6_GoQGWbXmgJ8eOP4aB8ae_NoY8dO4ojTnaQR0x0ZYwID7miuM0ETIR7"
        },
        body: jsonEncode({
          "registration_ids": driverTokens,
          "notification": {
            "body": "From:\n $pickupLocation\n To:\n $dropLocation",
            "title": "Ride Request"
          },
          "data": {"fcm-token": myFcmToken}
        }));

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Ride Request Sent"),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to Request Ride!"),
      ));
    }
  }

  void updateMyToken() async {
    myFcmToken = await FirebaseMessaging.instance.getToken() ?? '';
  }

  void setupInAppDialog() {
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
                    Text(
                      message.notification!.body ?? "",
                      style: const TextStyle(color: Colors.white),
                    )
                  ],
                ),
                actions: <Widget>[
                  if (message.notification!.title != 'Contact Number') ...[
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
                        http.post(Uri.parse(cloudMessagingApiUrl),
                          headers: {
                            "Content-Type": "application/json",
                            "Authorization":
                                "key=AAAACjgM6cI:APA91bGtSocRefhqegUzpstlLc7t7ycNzsAqCtEMXe9GvDcTxrPlekq_6WFGi0IMpiKh1iY9viCgoxOiXMhz6_GoQGWbXmgJ8eOP4aB8ae_NoY8dO4ojTnaQR0x0ZYwID7miuM0ETIR7"
                          },
                          body: jsonEncode({
                            "to": message.data['fcm-token'],
                            "notification": {
                              "body": "Offer ${message.notification!.body} declined",
                              "title": "Fare Rejected",
                            },
                          })
                        );
                        Navigator.of(context).pop();
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
                                    "Pickup the rider from ${markerSet.first.infoWindow.title}",
                                "title": "Fare Accepted",
                              },
                              "data": {"fcm-token": myFcmToken}
                            }));
                        Navigator.of(context).pop();
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
        title: const Text("Ghumo"),
        actions: [
          // logout action
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: BlocListener<RideDirectionBloc, RideDirectionState>(
        listener: (BuildContext context, RideDirectionState state) {
          if (state is RideDirectionGeolocationLoaded) {
            setState(() {
              userCurrentLocation = state.userCurrentLocation;
              initialCameraPosition = CameraPosition(
                  target:
                      LatLng(state.position.latitude, state.position.longitude),
                  zoom: 16);
              newGoogleMapController.animateCamera(
                  CameraUpdate.newLatLngZoom(LatLng(state.position.latitude, state.position.longitude), 16));
            });
          } else if (state is RideDirectionLoadedDirectionDetailsState) {
            Navigator.pop(context);
            setState(() {
              isBookRide = true;
              polylineSet.clear();
              Polyline polyline = Polyline(
                polylineId: PolylineId(
                    'polyline_id_${DateTime.now().millisecondsSinceEpoch}'),
                color: Colors.pink,
                jointType: JointType.round,
                points: state.pLineCoordinates,
                width: 5,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                geodesic: true,
              );
              polylineSet.add(polyline);

              //code to update the markers
              Marker pickUpLocMarker = Marker(
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    (BitmapDescriptor.hueGreen)),
                infoWindow: InfoWindow(
                    title: state.pickUpLocation.placeName,
                    snippet: "my Location"),
                position: LatLng(state.pickUpLocation.latitude,
                    state.pickUpLocation.longitude),
                markerId: const MarkerId("pickUpId"),
              );
              Marker dropOffLocMarker = Marker(
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    (BitmapDescriptor.hueRed)),
                infoWindow: InfoWindow(
                    title: state.dropOffLocation.placeName, snippet: "DropOff"),
                position: LatLng(state.dropOffLocation.latitude,
                    state.dropOffLocation.longitude),
                markerId: MarkerId("dropOffId"),
              );

              markerSet.add(pickUpLocMarker);
              markerSet.add(dropOffLocMarker);

              // updating the circles
              Circle pickUpLocCircle = Circle(
                fillColor: Colors.white,
                center: LatLng(state.pickUpLocation.latitude,
                    state.pickUpLocation.longitude),
                radius: 12,
                strokeWidth: 4,
                strokeColor: Colors.grey,
                circleId: const CircleId("pickUpId"),
              );
              Circle dropOffLocCircle = Circle(
                fillColor: Colors.white,
                center: LatLng(state.dropOffLocation.latitude,
                    state.dropOffLocation.longitude),
                radius: 12,
                strokeWidth: 4,
                strokeColor: Colors.grey,
                circleId: const CircleId("dropOffId"),
              );

              circleSet.add(pickUpLocCircle);
              circleSet.add(dropOffLocCircle);
              newGoogleMapController.animateCamera(
                  CameraUpdate.newLatLngBounds(state.latLngBounds, 0));
            });

          }
          else if(state is RideDirectionErrorState){
            isSnackBar = true;
            errorMessage = state.errorMessage;
          }
        },
        child: Stack(
          children: [
            GoogleMap(
              padding: EdgeInsets.fromLTRB(1, 1, 1, bottomPaddingOfMap),
              mapType: MapType.normal,
              initialCameraPosition: initialCameraPosition,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
              zoomGesturesEnabled: true,
              polylines: polylineSet,
              markers: markerSet,
              circles: circleSet,
              onMapCreated: (GoogleMapController controller) {
                _controllerGoogleMap.complete(controller);
                newGoogleMapController = controller;
                setState(() {
                  bottomPaddingOfMap = 310.0;
                });
              },
            ),
            Positioned(
              left: 5,
              right: 5,
              bottom: 0.0,
              child: Container(
                height: 230.0,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15.0),
                    topRight: Radius.circular(18.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18.0,
                    horizontal: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 6.0),
                      const Text("Where to?", style: TextStyle(fontSize: 20.0)),
                      const SizedBox(height: 20.0),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isBookRide = false;
                            pLineCoordinates = [];
                            polylineSet = {};
                            markerSet = {};
                            circleSet = {};
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SearchPage(userCurrentLocation: userCurrentLocation)),
                          );
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 6.0,
                                spreadRadius: 0.5,
                                offset: Offset(0.7, 0.7),
                              )
                            ],
                          ),
                          child: const Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.search, color: Colors.grey),
                              ),
                              SizedBox(width: 10.0),
                              Text("Search Drop off..."),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (isBookRide)
                      SizedBox(
                        height: 40,
                        width: 150,
                        child: ElevatedButton(
                          onPressed: () {
                            requestRide(markerSet.first.infoWindow.title ?? '',
                                markerSet.last.infoWindow.title ?? '');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[300],
                          ),
                          child: const Text("Book Ride",
                              style: TextStyle(fontSize: 20)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

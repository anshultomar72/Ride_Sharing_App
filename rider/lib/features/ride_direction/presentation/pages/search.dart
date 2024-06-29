import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/place_prediction.dart';
import '../bloc/ride_direction_bloc.dart';
import 'dart:async';


class SearchPage extends StatelessWidget {
  final Address userCurrentLocation;
  const SearchPage({super.key, required this.userCurrentLocation});

  @override
  Widget build(BuildContext context) {
    return SearchPageView(userCurrentLocation: userCurrentLocation,);
  }
}

class SearchPageView extends StatefulWidget {
  final Address userCurrentLocation;
  const SearchPageView({Key? key, required this.userCurrentLocation}) : super(key: key);

  @override
  State<SearchPageView> createState() => _SearchPageViewState();
}

class _SearchPageViewState extends State<SearchPageView> {
  TextEditingController pickUpTextController = TextEditingController();
  TextEditingController dropOffTextController = TextEditingController();
  bool isPickup = false;
  Address pickUpLocation = Address();
  Address dropOffLocation = Address();

  List<PlacePrediction> placePredictionList = [];

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    pickUpTextController.addListener(() {
      setState(() {
        isPickup = true;
      });
    });

    dropOffTextController.addListener(() {
      setState(() {
        isPickup = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text("Search Location"),
        centerTitle: true,
      ),
      body: BlocListener<RideDirectionBloc, RideDirectionState>(
        listener: (BuildContext context, RideDirectionState state) {
          if (state is RideDirectionSelectLocationState) {
            setState(() {
              placePredictionList = [];
            });
          } else if (state is RideDirectionLocationChangedState) {
            setState(() {
              placePredictionList = state.placePredictionList;
            });
          } else if (state is RideDirectionLocationSelectedState) {
            setState(() {
              placePredictionList = [];
              if (isPickup) {
                pickUpLocation = state.address;
              } else {
                dropOffLocation = state.address;
              }
            });
          }
        },
        child: Column(
          children: [
            Container(
              height: 230.0,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 6.0,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(25.0, 5.0, 25.0, 10),
                child: Column(
                  children: [
                    const SizedBox(height: 14.0),
                    //Pickup Location Field
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.red[300],
                        ),
                        const SizedBox(
                          width: 18,
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: TextField(
                                onChanged: (val) {
                                    _debounceTimer?.cancel();

                                    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
                                      BlocProvider.of<RideDirectionBloc>(context).add(
                                          RideDirectionLocationChangedEvent(placeName: val)
                                      );
                                    });
                                  },

                                controller: pickUpTextController,
                                decoration: InputDecoration(
                                  hintText: "PickUp Location",
                                  fillColor: Colors.grey[100],
                                  filled: true,
                                  border: InputBorder.none,
                                  // isDense: true,
                                  contentPadding:
                                      const EdgeInsets.fromLTRB(11, 8, 0, 8),
                                  suffixIcon:
                                      pickUpTextController.text.isNotEmpty
                                          ? IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  pickUpTextController.clear();
                                                });
                                              },
                                              icon: const Icon(Icons.clear),
                                            )
                                          : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    // DropOff Location Field
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.green[300],
                        ),
                        SizedBox(
                          width: 18,
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: TextField(
                                onChanged: (val) {
                                  _debounceTimer?.cancel();

                                  _debounceTimer = Timer(const Duration(milliseconds: 350), () {
                                    BlocProvider.of<RideDirectionBloc>(context).add(
                                        RideDirectionLocationChangedEvent(placeName: val)
                                    );
                                  });
                                },
                                controller: dropOffTextController,
                                decoration: InputDecoration(
                                  hintText: "DropOff Location",
                                  fillColor: Colors.grey[100],
                                  filled: true,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.fromLTRB(11, 8, 0, 8),
                                  suffixIcon:
                                      dropOffTextController.text.isNotEmpty
                                          ? IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  dropOffTextController.clear();
                                                });
                                              },
                                              icon: Icon(Icons.clear),
                                            )
                                          : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    // Continue and YourLocation Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            pickUpLocation = widget.userCurrentLocation;
                            pickUpTextController.text = widget.userCurrentLocation.placeName;
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[300],
                          ),
                          child: const Text("Current Location",style: TextStyle(color: Colors.black),),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (pickUpTextController.text.isNotEmpty &&
                                dropOffTextController.text.isNotEmpty) {
                              BlocProvider.of<RideDirectionBloc>(context).add(
                                  RideDirectionLoadDirectionDetailsEvent(
                                      pickUpLocation: pickUpLocation,
                                      dropOffLocation: dropOffLocation));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fetching direction details...'),
                                  duration: Duration(seconds: 2), // Adjust duration as needed
                                ),
                              );
                            }
                            else {
                              // If pickUpLocation or dropOffLocation is empty, display another snackbar
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter both pickup and drop-off locations.'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[300],
                          ),
                          child: const Text("Continue",style: TextStyle(color: Colors.black),),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            //List View
            Expanded(
              child: ListView.builder(
                itemCount: placePredictionList.length,
                itemBuilder: (context, index) {
                  PlacePrediction place = placePredictionList[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    leading: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                    ),
                    title: Text(
                      place.description,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      // AssistantMethods.convertAddresstoLatLng(place.description, context, pickOrdrop);
                      BlocProvider.of<RideDirectionBloc>(context).add(
                          RideDirectionLocationSelectedEvent(
                              placeName: place.description));
                      if (isPickup) {
                        pickUpTextController.text = place.description;
                      } else {
                        dropOffTextController.text = place.description;
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

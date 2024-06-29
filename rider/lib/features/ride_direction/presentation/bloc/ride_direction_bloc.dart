import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

import '../../../../config/map_api_key.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/direction_details.dart';
import '../../domain/entities/place_prediction.dart';

part 'ride_direction_events.dart';
part 'ride_direction_states.dart';

class RideDirectionBloc extends Bloc<RideDirectionEvent,RideDirectionState>{
  RideDirectionBloc() : super(RideDirectionGeolocationLoading()) {
    add(RideDirectionLoadGeolocation());
  }

  @override
  Stream<RideDirectionState> mapEventToState(RideDirectionEvent event) async*{
    if(event is RideDirectionLoadGeolocation){
      yield* _mapLoadGeolocationToState();
    }
    else if(event is RideDirectionUpdateGeolocation){
      yield* _mapUpdateGeolocationToState(event);
    }
    else if (event is RideDirectionSelectLocationEvent){
      yield* _mapSelectLocationToSelectLocationState();
    }
    else if (event is RideDirectionLocationChangedEvent){
      yield* _mapLocationChangedToLocationChangedState(event.placeName);
    }
    else if (event is RideDirectionLocationSelectedEvent){
      yield* _mapLocationSelectedToLocationSelectedState(event.placeName);
    }
    else if (event is RideDirectionLoadDirectionDetailsEvent){
      yield* _mapLoadDirectionDetailsToLoadingDirectionDetailsState(event.pickUpLocation, event.dropOffLocation);
    }
    else if(event is RideDirectionUpdateDirectionDetailsEvent){
      yield* _mapUpdateDirectionDetailsToLoadedDirectionDetailsState(event);
    }
  }

  Stream<RideDirectionState> _mapLoadGeolocationToState() async*{
    // Request permission
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      yield RideDirectionErrorState(errorMessage: "Permission denied"); // Emit error state
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      yield RideDirectionErrorState(errorMessage: "Permission denied forever You need to give permission manually for accessing your current location"); // Emit error state
      return;
    }

    final Position position = await getUserCurrentLocation();
    add(RideDirectionUpdateGeolocation(position: position));
  }

  Stream<RideDirectionState> _mapUpdateGeolocationToState(RideDirectionUpdateGeolocation event) async*{
    Address userCurrentLocation = await convertLatLngToAddress(event.position);
    yield RideDirectionGeolocationLoaded(position: event.position, userCurrentLocation: userCurrentLocation);
  }

  Stream<RideDirectionState> _mapSelectLocationToSelectLocationState() async*{
    try{
      yield RideDirectionSelectLocationState();
    } catch(e) {
      yield RideDirectionErrorState(errorMessage: "");
    }
  }

  Stream<RideDirectionState> _mapLocationChangedToLocationChangedState(String placeName) async*{
    try{
      List<PlacePrediction> placePredictionList = await getMapPrediction(placeName);
      yield RideDirectionLocationChangedState(placePredictionList: placePredictionList);
    } catch(e) {
      yield RideDirectionErrorState(errorMessage: "");
    }
  }

  Stream<RideDirectionState> _mapLocationSelectedToLocationSelectedState(String placeName) async*{
    try{
      Address address = await convertAddressToLatLng(placeName);

      yield RideDirectionLocationSelectedState(address: address);
    } catch(e) {
      yield RideDirectionErrorState(errorMessage: "");
    }
  }

  Stream<RideDirectionState> _mapLoadDirectionDetailsToLoadingDirectionDetailsState(Address pickUpLocation, Address dropOffLocation) async*{
    try{
      Future<List<dynamic>> dataFuture = getRouteDetails(pickUpLocation, dropOffLocation);
      List<dynamic> data = await dataFuture;
      List<LatLng> pLineCoordinates = data[0] as List<LatLng>;
      LatLngBounds latLngBounds = data[1] as LatLngBounds;
      add(RideDirectionUpdateDirectionDetailsEvent(
          pLineCoordinates: pLineCoordinates,
          latLngBounds: latLngBounds,
          pickUpLocation: pickUpLocation,
          dropOffLocation: dropOffLocation
      ));
    } catch (e){
      yield RideDirectionErrorState(errorMessage: "");
    }
  }

  Stream<RideDirectionState> _mapUpdateDirectionDetailsToLoadedDirectionDetailsState(RideDirectionUpdateDirectionDetailsEvent event) async*{
    try{
      yield RideDirectionLoadedDirectionDetailsState(
          pickUpLocation: event.pickUpLocation,
          dropOffLocation: event.dropOffLocation,
          pLineCoordinates: event.pLineCoordinates,
          latLngBounds: event.latLngBounds
      );
    } catch (e){
      yield RideDirectionErrorState(errorMessage: "");
    }
  }
}

Future<Position> getUserCurrentLocation() async {
  return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
  );
}

//reverse geocoding
Future<Address> convertLatLngToAddress(Position position) async {
  String placeAddress = "";
  Address userCurrentLocation = Address();
  String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";

  var response = await http.get(Uri.parse(url));
  try {
    if (response.statusCode == 200) {
      String jsonData = response.body;
      var decodeData = jsonDecode(jsonData);

      placeAddress = decodeData["results"][0]["formatted_address"];

      userCurrentLocation.longitude = position.longitude;
      userCurrentLocation.latitude = position.latitude;
      userCurrentLocation.placeName = placeAddress;

    }
  } catch (err) {
    print('Error fetching autocomplete suggestions: $err');
  }
  return userCurrentLocation;
}

Future<List<PlacePrediction>> getMapPrediction(String placeName) async{
  List<PlacePrediction> placePredictionList = [];

  String autocompleteUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessiontoken=1234567890&components=country:in';

  var response = await http.get(Uri.parse(autocompleteUrl));

  try {
    if (response.statusCode == 200) {
      String jsonData = response.body;
      var decodeData = jsonDecode(jsonData);
      var predictions = decodeData["predictions"];
      var placeList = (predictions as List).map((e) => PlacePrediction.fromJson(e)).toList();

      placePredictionList = placeList;
    }
  } catch (err) {
    print('Error fetching autocomplete suggestions: $err');
  }

  return placePredictionList;
}

// Geocoding
Future<Address> convertAddressToLatLng(String placeName) async {
  Address address = Address();

  String url = "https://maps.googleapis.com/maps/api/geocode/json?address=$placeName&key=$mapKey";

  var response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    String jsonData = response.body;
    var decodeData = jsonDecode(jsonData);
    double latitude = decodeData["results"][0]["geometry"]["location"]["lat"];
    double longitude = decodeData["results"][0]["geometry"]["location"]["lng"];

    address.longitude = longitude;
    address.latitude = latitude;
    address.placeName = placeName;
  }
  return address;
}

Future<List<dynamic>> getRouteDetails(Address pickUpLocation, Address dropOffLocation) async{
  List<LatLng> pLineCoordinates = [];
  var pickUpLatLng = LatLng(pickUpLocation.latitude, pickUpLocation.longitude);
  var dropOffLatLng = LatLng(dropOffLocation.latitude, dropOffLocation.longitude);

  var details = await getMapDirectionDetails(pickUpLatLng, dropOffLatLng);

  //updating the poly-lines
  PolylinePoints polylinePoints = PolylinePoints();

  List<PointLatLng> decodedPolylinePointsResult = polylinePoints.decodePolyline(details.encodedPoints);

  pLineCoordinates.clear();
  if(decodedPolylinePointsResult.isNotEmpty) {
    decodedPolylinePointsResult.forEach((PointLatLng pointLatLng) {
      pLineCoordinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));

    });
  }

  LatLngBounds latLngBounds;

  if(pickUpLatLng.latitude > dropOffLatLng.latitude && pickUpLatLng.longitude > dropOffLatLng.longitude){
    latLngBounds = LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
  }
  else if(pickUpLatLng.longitude > dropOffLatLng.longitude){
    latLngBounds = LatLngBounds(southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude), northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
  }
  else if(pickUpLatLng.latitude > dropOffLatLng.latitude){
    latLngBounds = LatLngBounds(southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude), northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
  }
  else {
    latLngBounds = LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
  }
  return [pLineCoordinates, latLngBounds];
}

Future<DirectionDetails> getMapDirectionDetails(LatLng initialPos, LatLng finalPos) async {
  DirectionDetails directionDetails = DirectionDetails();

  String directionUrl = "https://maps.googleapis.com/maps/api/directions/json?destination=${initialPos.latitude},${initialPos.longitude}&origin=${finalPos.latitude},${finalPos.longitude}&key=$mapKey";

  var response = await http.get(Uri.parse(directionUrl));

  if (response.statusCode == 200) {
    String jsonData = response.body;
    var decodeData = jsonDecode(jsonData);

    directionDetails.encodedPoints =
    decodeData["routes"][0]["overview_polyline"]["points"];
    directionDetails.distanceText =
    decodeData["routes"][0]["legs"][0]["distance"]["text"];
    directionDetails.durationValue =
    decodeData["routes"][0]["legs"][0]["distance"]["value"];
    directionDetails.durationText =
    decodeData["routes"][0]["legs"][0]["duration"]["text"];
    directionDetails.durationValue =
    decodeData["routes"][0]["legs"][0]["duration"]["value"];
  }
  return directionDetails;
}
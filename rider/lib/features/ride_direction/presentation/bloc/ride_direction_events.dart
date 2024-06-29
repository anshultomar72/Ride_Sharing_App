part of 'ride_direction_bloc.dart';

abstract class RideDirectionEvent extends Equatable {
  const RideDirectionEvent();

  @override
  List<Object> get props => [];
}

class RideDirectionLoadGeolocation extends RideDirectionEvent{}

class RideDirectionUpdateGeolocation extends RideDirectionEvent{
  final Position position;

  const RideDirectionUpdateGeolocation({required this.position});

  @override
  List<Object> get props => [position];
}

class RideDirectionSelectLocationEvent extends RideDirectionEvent{}

class RideDirectionLocationChangedEvent extends RideDirectionEvent{
  final String placeName;

  const RideDirectionLocationChangedEvent({
    required this.placeName
  });

  @override
  List<Object> get props => [placeName];
}

class RideDirectionLocationSelectedEvent extends RideDirectionEvent{
  final String placeName;

  const RideDirectionLocationSelectedEvent({
    required this.placeName
  });

  @override
  List<Object> get props => [placeName];
}

class RideDirectionLoadDirectionDetailsEvent extends RideDirectionEvent{
  final Address pickUpLocation;
  final Address dropOffLocation;

  const RideDirectionLoadDirectionDetailsEvent({
    required this.pickUpLocation,
    required this.dropOffLocation
  });

  @override
  List<Object> get props => [pickUpLocation, dropOffLocation];
}

class RideDirectionUpdateDirectionDetailsEvent extends RideDirectionEvent{
  final Address pickUpLocation;
  final Address dropOffLocation;
  final List<LatLng> pLineCoordinates;
  final LatLngBounds latLngBounds;

  const RideDirectionUpdateDirectionDetailsEvent({
    required this.pickUpLocation,
    required this.dropOffLocation,
    required this.latLngBounds,
    required this.pLineCoordinates
  });

  @override
  List<Object> get props => [pickUpLocation, dropOffLocation, pLineCoordinates, latLngBounds];
}
part of 'ride_direction_bloc.dart';

abstract class RideDirectionState extends Equatable {
  const RideDirectionState();

  @override
  List<Object?> get props => [];
}

class RideDirectionGeolocationLoading extends RideDirectionState{}

class RideDirectionGeolocationLoaded extends RideDirectionState {
  final Position position;
  final Address userCurrentLocation;

  const RideDirectionGeolocationLoaded({
    required this.position,
    required this.userCurrentLocation
  });

  @override
  List<Object?> get props => [position, userCurrentLocation];
}

class RideDirectionSelectLocationState extends RideDirectionState{}

class RideDirectionLocationChangedState extends RideDirectionState{
  final List<PlacePrediction> placePredictionList;

  const RideDirectionLocationChangedState({required this.placePredictionList});

  @override
  List<Object> get props => [placePredictionList];
}

class RideDirectionLocationSelectedState extends RideDirectionState{
  final Address address;

  const RideDirectionLocationSelectedState({required this.address});

  @override
  List<Object> get props => [address];
}

class RideDirectionLoadingDirectionDetailsState extends RideDirectionState{}

class RideDirectionLoadedDirectionDetailsState extends RideDirectionState{

  final List<LatLng> pLineCoordinates;
  final Address dropOffLocation;
  final Address pickUpLocation;
  final LatLngBounds latLngBounds;

  const RideDirectionLoadedDirectionDetailsState({
    required this.latLngBounds,
    required this.pLineCoordinates,
    required this.dropOffLocation,
    required this.pickUpLocation
  });
  @override
  List<Object?> get props => [latLngBounds, pLineCoordinates, dropOffLocation, pickUpLocation];

}

class RideDirectionErrorState extends RideDirectionState{
  final String errorMessage;

  RideDirectionErrorState({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}
part of 'auth_bloc.dart';

abstract class AuthenticationState extends Equatable {
  const AuthenticationState();

  @override
  List<Object> get props => [];
}

class AuthenticationInitialState extends AuthenticationState{}

class AuthenticationEnterOTPState extends AuthenticationState{}

class AuthenticationVerifiedState extends AuthenticationState{}

class AuthenticationErrorState extends AuthenticationState{
  final String errorMessage;

  const AuthenticationErrorState({
    required this.errorMessage
  });

  @override
  List<Object> get props => [errorMessage];
}

class AuthenticationCompletedState extends AuthenticationState{}
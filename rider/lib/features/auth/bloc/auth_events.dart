part of 'auth_bloc.dart';

abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object> get props => [];
}

class AuthenticationPhoneNumberEntered extends AuthenticationEvent {
  final String phoneNumber;

  const AuthenticationPhoneNumberEntered({
    required this.phoneNumber
  });

  @override
  List<Object> get props => [phoneNumber];
}

class AuthenticationOTPEntered extends AuthenticationEvent {
  final String otp;

  const AuthenticationOTPEntered({
    required this.otp
  });

  @override
  List<Object> get props => [otp];
}

class AuthenticationPhoneNumberChangeRequest extends AuthenticationEvent{}

class AuthenticationResendOTPRequest extends AuthenticationEvent{
  final String phoneNumber;

  const AuthenticationResendOTPRequest({
    required this.phoneNumber
  });

  @override
  List<Object> get props => [phoneNumber];
}

class AuthenticationErrorEvent extends AuthenticationEvent{
  final String errorMessage;

  const AuthenticationErrorEvent({
    required this.errorMessage
  });

  @override
  List<Object> get props => [errorMessage];
}
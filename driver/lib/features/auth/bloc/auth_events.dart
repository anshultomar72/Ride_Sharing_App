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
  final String otp,fullName;

  const AuthenticationOTPEntered({
    required this.otp,
    required this.fullName
  });

  @override
  List<Object> get props => [otp,fullName];
}

class AuthenticationDocumentsUploaded extends AuthenticationEvent{
  final String aadhaar,pan;

  const AuthenticationDocumentsUploaded({
    required this.aadhaar,
    required this.pan,
  });
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
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rider/features/auth/data/firebase.dart';


part 'auth_events.dart';
part 'auth_states.dart';


class AuthenticationBloc extends Bloc<AuthenticationEvent,AuthenticationState>{
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();

  AuthenticationBloc() : super(AuthenticationInitialState());

  @override
  Stream<AuthenticationState> mapEventToState(AuthenticationEvent event) async*{
    if (event is AuthenticationPhoneNumberEntered){
      yield* _mapPhoneNumberEnteredToEnterOTPState(event.phoneNumber);
    }
    else if (event is AuthenticationOTPEntered){
      yield* _mapOTPEnteredToVerifiedState(event.otp);
    }
    else if (event is AuthenticationPhoneNumberChangeRequest){
      yield* _mapPhoneNumberChangeRequestToState();
    }
    else if (event is AuthenticationResendOTPRequest){
      yield* _mapResendOTPRequestToState(event.phoneNumber);
    }
  }

  Stream<AuthenticationState> _mapPhoneNumberEnteredToEnterOTPState(String phoneNumber) async* {
    try{

      // Initiating verification process
      await _firebaseAuthService.verifyPhoneNumber(
          phoneNumber, (FirebaseAuthException e) {
            add(AuthenticationErrorEvent(errorMessage: e.message ?? 'Verification failed, please try again'));
          }
      );

      // signaling the UI to go for the OTP Entering state
      yield AuthenticationEnterOTPState();

    } catch (e) {
      yield AuthenticationErrorState(errorMessage: e.toString());
    }
  }

  Stream<AuthenticationState> _mapOTPEnteredToVerifiedState(String otp) async*{
    try{

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _firebaseAuthService.verificationId,smsCode: otp
      );

      // credential verification (verificationId+otp)
      await _firebaseAuthService.signInWithCredential(credential);

      yield AuthenticationVerifiedState();

    } catch (e) {
      yield AuthenticationErrorState(errorMessage: e.toString());
    }
  }

  Stream<AuthenticationState> _mapPhoneNumberChangeRequestToState() async*{
    try{
      yield AuthenticationInitialState();
    } catch (e) {
      yield AuthenticationErrorState(errorMessage: e.toString());
    }
  }

  Stream<AuthenticationState> _mapResendOTPRequestToState(String phoneNumber) async*{
    // add code for resend otp here
    try{
      yield AuthenticationEnterOTPState();
    } catch (e) {
      yield AuthenticationErrorState(errorMessage: e.toString());
    }
  }
}
import 'package:bloc/bloc.dart';
import 'package:driver/features/auth/data/firebase_storage.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:driver/features/auth/data/firebase.dart';
import 'package:driver/features/auth/data/firestore.dart';

part 'auth_events.dart';
part 'auth_states.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorageService _firebaseStorageService = FirebaseStorageService();

  AuthenticationBloc() : super(AuthenticationInitialState()) {
    on<AuthenticationPhoneNumberEntered>((event, emit) async {
      try {
        // Initiating verification process
        await _firebaseAuthService.verifyPhoneNumber(event.phoneNumber,(FirebaseAuthException e) {
          add(AuthenticationErrorEvent(errorMessage:e.message ?? 'Verification failed, please try again'));
        });
        // signaling the UI to go for the OTP Entering state
        emit(AuthenticationEnterOTPState());
      } catch (e) {
        emit(AuthenticationErrorState(errorMessage: e.toString()));
      }
    });

    on<AuthenticationOTPEntered>((event,emit) async {
      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: _firebaseAuthService.verificationId, smsCode: event.otp);

        // Credential verification (verificationId+otp)
        await _firebaseAuthService.signInWithCredential(credential);

        // Creating and Storing user
        await _firestoreService.createUser(event.fullName,_firebaseAuthService.authInstance.currentUser!.uid,_firebaseAuthService.authInstance.currentUser!.phoneNumber);

        emit(AuthenticationVerifiedState());
      } catch (e) {
        emit(AuthenticationErrorState(errorMessage: e.toString()));
      }
    });

    on<AuthenticationPhoneNumberChangeRequest>((event,emit) async{
      try {
        emit(AuthenticationInitialState());
      } catch (e) {
        emit(AuthenticationErrorState(errorMessage: e.toString()));
      }
    });

    on<AuthenticationResendOTPRequest>((event,emit) async{
      try {
        emit(AuthenticationEnterOTPState());
      } catch (e) {
        emit(AuthenticationErrorState(errorMessage: e.toString()));
      }
    });

    on<AuthenticationDocumentsUploaded>((event,emit) async{
      try {
        print('here-2');
        await _firebaseStorageService.uploadDocuments(
            _firebaseAuthService.authInstance.currentUser!.uid,
            {'aadhaar': event.aadhaar, 'pan': event.pan});
        emit(AuthenticationCompletedState());
      } catch (e) {
        emit(AuthenticationErrorState(errorMessage: e.toString()));
      }
    });
  }

}

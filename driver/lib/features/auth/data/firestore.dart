import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService{
  static final FirestoreService _instance = FirestoreService._internal();

  factory FirestoreService(){
    return _instance;
  }

  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get instance => _firestore;

  Future<void> createUser(String fullName,String uid,String? phoneNumber) async {
    await FirebaseFirestore.instance.collection('Users').doc(uid).set({
      'phoneNumber':phoneNumber,
      'fullName':fullName
    });
  }
}
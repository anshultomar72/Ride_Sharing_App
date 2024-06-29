import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService{
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();

  factory FirebaseStorageService(){
    return _instance;
  }

  FirebaseStorageService._internal();

  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  FirebaseStorage get instance => _firebaseStorage;

  Future<void> uploadDocuments(String uid,Map<String,String> filePaths) async {
    print('here-3');
    File? aadhaar = File(filePaths['aadhaar']!);
    File? pan = File(filePaths['pan']!);
    Reference documentsReference = FirebaseStorage.instance.ref().child('Documents');

    print('uploading');
    await documentsReference.child('${uid}_aadhaar').putFile(aadhaar);
    await documentsReference.child('${uid}_pan').putFile(pan);
  }
}
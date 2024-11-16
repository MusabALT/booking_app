import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:booking_room/core/models/user.dart' as local_model;

class AuthController {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<local_model.User?> register(String email, String password, String name,
      String phoneNumber, String address) async {
    local_model.User? user;
    try {
      final firebase_auth.UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      final firebase_auth.User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        user = local_model.User(
          uid: firebaseUser.uid,
          email: email,
          name: name,
          role: 'customer',
          phoneNumber: phoneNumber,
          address: address,
        );
        await _firestore.collection('users').doc(user.uid).set(user.toMap());
        print('User registered: ${user.toMap()}');
      }
    } catch (e) {
      print('Error during registration: $e');
    }
    return user;
  }

  Future<local_model.User?> login(String email, String password) async {
    local_model.User? user;
    try {
      final firebase_auth.UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      final firebase_auth.User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        final DocumentSnapshot doc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          user = local_model.User.fromMap(doc.data() as Map<String, dynamic>);
          print('User logged in: ${user.toMap()}');
        } else {
          print('No user document found for uid: ${firebaseUser.uid}');
        }
      }
    } catch (e) {
      print('Error during login: $e');
    }
    return user;
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      print('User logged out');
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}

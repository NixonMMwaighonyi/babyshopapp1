import 'package:firebase_auth/firebase_auth.dart';
import 'package:babyshopapp/models/userModel.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create user object based on firebase user
  UserModel? _userFromFirebaseUser(User? userObj) {
    return userObj != null ? UserModel(uid: userObj.uid) : null;
  }

  // Auth change user Stream
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map(
      (User? userObj) => _userFromFirebaseUser(userObj),
    );
  }

  // Sign in Anon
  Future signInAnon() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign in Email & Password
  Future signInWithEmailAndPassword(email, password) async {}

  // Register with Email & Password
  


  // Sign out
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}

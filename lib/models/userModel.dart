/// Lightweight role holder (most profile data lives in Firestore `users` maps).
class UserModel {
  final String? uid;
  final String? role; 

  UserModel({
    this.uid,
    this.role,
  });
}
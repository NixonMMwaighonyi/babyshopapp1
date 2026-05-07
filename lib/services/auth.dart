import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Admin email ──────────────────────────────────────────────────────────────
// Any account registered (or already existing) with this email gets role=admin.
const String kAdminEmail = 'mwalughanixon252@gmail.com';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? lastAuthError;
  static const Duration _authTimeout = Duration(seconds: 15);
  static const Duration _firestoreTimeout = Duration(seconds: 15);

  Stream<User?> get user => _auth.authStateChanges();

  // ── Sign in ────────────────────────────────────────────────────────────────
  Future<dynamic> signInWithEmailAndPassword(String email, String password) async {
    try {
      lastAuthError = null;
      final result = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(_authTimeout);
      return result.user;
    } catch (e) {
      print(e.toString());
      lastAuthError = e.toString();
      return null;
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────
  Future<dynamic> registerWithEmailAndPassword(String email, String password, {String name = ''}) async {
    try {
      lastAuthError = null;
      final result = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(_authTimeout);

      final normalizedEmail = email.trim().toLowerCase();
      final isHardcodedAdmin = normalizedEmail == kAdminEmail.toLowerCase();
      final adminDoc = await _db
          .collection('admin_emails')
          .doc(normalizedEmail)
          .get()
          .timeout(_firestoreTimeout);

      final role = (isHardcodedAdmin || adminDoc.exists) ? 'admin' : 'customer';
      await _db
          .collection('users')
          .doc(result.user!.uid)
          .set({
            'role': role,
            'email': email,
            'name': name,
            'phone': '',
            'address': '',
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(_firestoreTimeout);
      return result.user;
    } catch (e) {
      print(e.toString());
      lastAuthError = e.toString();
      return null;
    }
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // ── Get role ───────────────────────────────────────────────────────────────
  // Also handles legacy accounts that have no Firestore doc yet by creating one.
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get().timeout(_firestoreTimeout);
      if (!doc.exists) {
        // Legacy account — create doc with correct role
        final currentUser = _auth.currentUser;
        final email = (currentUser?.email ?? '').trim().toLowerCase();
        final isHardcodedAdmin = email == kAdminEmail.toLowerCase();
        final adminDoc = await _db
            .collection('admin_emails')
            .doc(email)
            .get()
            .timeout(_firestoreTimeout);
        final role = (isHardcodedAdmin || adminDoc.exists) ? 'admin' : 'customer';
        await _db
            .collection('users')
            .doc(uid)
            .set({
              'role': role,
              'email': email,
              'name': '',
              'phone': '',
              'address': '',
              'createdAt': FieldValue.serverTimestamp(),
            })
            .timeout(_firestoreTimeout);
        return role;
      }
      final data = doc.data() as Map<String, dynamic>;
      var role = data['role'] ?? 'customer';

      // If account was created earlier as customer but email is now allowed as admin,
      // upgrade it automatically.
      if (role != 'admin') {
        final currentUser = _auth.currentUser;
        final email = (currentUser?.email ?? '').trim().toLowerCase();
        if (email.isNotEmpty) {
          final isHardcodedAdmin = email == kAdminEmail.toLowerCase();
          final adminDoc = await _db
              .collection('admin_emails')
              .doc(email)
              .get()
              .timeout(_firestoreTimeout);

          if (isHardcodedAdmin || adminDoc.exists) {
            role = 'admin';
            await _db.collection('users').doc(uid).update({'role': role}).timeout(_firestoreTimeout);
          }
        }
      }

      return role;
    } catch (e) {
      return 'customer';
    }
  }

  // ── Get full user data ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      return null;
    }
  }

  // ── Update user data ───────────────────────────────────────────────────────
  Future<bool> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }
}


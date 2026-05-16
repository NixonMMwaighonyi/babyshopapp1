import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles sign-in, registration, roles, and account cleanup for BabyShopHub.
/// Admin access is granted only when an email exists in Firestore `admin_emails`
/// (add documents there in the Firebase console — no hardcoded admin address).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Last error from sign-in / register / delete — shown in the UI when needed.
  String? lastAuthError;
  /// Shown under the email field on the login screen.
  String? lastSignInEmailError;
  /// Shown under the password field on the login screen.
  String? lastSignInPasswordError;

  static const Duration _authTimeout = Duration(seconds: 15);
  static const Duration _firestoreTimeout = Duration(seconds: 15);

  /// Stream of the current Firebase user (null when logged out).
  Stream<User?> get user => _auth.authStateChanges();

  void _clearSignInErrors() {
    lastSignInEmailError = null;
    lastSignInPasswordError = null;
    lastAuthError = null;
  }

  /// Whether this email is allowed to be an admin (document in `admin_emails`).
  Future<bool> _isListedAdminEmail(String normalizedEmail) async {
    if (normalizedEmail.isEmpty) return false;
    final adminDoc = await _db
        .collection('admin_emails')
        .doc(normalizedEmail)
        .get()
        .timeout(_firestoreTimeout);
    return adminDoc.exists;
  }

  // ── Sign in ────────────────────────────────────────────────────────────────

  Future<dynamic> signInWithEmailAndPassword(String email, String password) async {
    _clearSignInErrors();
    final trimmedEmail = email.trim();
    try {
      final result = await _auth
          .signInWithEmailAndPassword(email: trimmedEmail, password: password)
          .timeout(_authTimeout);
      return result.user;
    } on FirebaseAuthException catch (e) {
      await _applySignInError(e, trimmedEmail);
      return null;
    } catch (_) {
      lastAuthError = 'Something went wrong. Try again.';
      return null;
    }
  }

  /// Turns Firebase error codes into messages on the email or password field.
  Future<void> _applySignInError(FirebaseAuthException e, String email) async {
    switch (e.code) {
      case 'invalid-email':
        lastSignInEmailError = 'Wrong email.';
        break;
      case 'user-not-found':
        lastSignInEmailError = 'Wrong email. No account found — tap Register to sign up.';
        break;
      case 'wrong-password':
        lastSignInPasswordError = 'Wrong password.';
        break;
      case 'invalid-credential':
      case 'invalid-login-credentials':
        await _resolveInvalidCredential(email);
        break;
      case 'user-disabled':
        lastAuthError = 'This account is disabled. Contact support.';
        break;
      case 'too-many-requests':
        lastAuthError = 'Too many tries. Wait a minute and try again.';
        break;
      case 'network-request-failed':
        lastAuthError = 'Check your internet connection.';
        break;
      default:
        await _resolveInvalidCredential(email);
    }
  }

  /// Newer Firebase often returns one code for both bad email and bad password.
  /// We peek at Firestore: if there is no profile for that email, blame the email.
  Future<void> _resolveInvalidCredential(String email) async {
    if (email.isEmpty) {
      lastSignInEmailError = 'Wrong email.';
      return;
    }
    try {
      final profile = await getUserProfileByEmail(email);
      if (profile == null) {
        lastSignInEmailError = 'Wrong email. No account found — tap Register to sign up.';
      } else {
        lastSignInPasswordError = 'Wrong password.';
      }
    } catch (_) {
      lastSignInPasswordError = 'Wrong password.';
    }
  }

  /// Sends the standard Firebase password-reset email. Returns null on success.
  Future<String?> sendPasswordResetEmail(String email) async {
    lastAuthError = null;
    final trimmed = email.trim();
    if (trimmed.isEmpty) return 'Enter your email address.';
    try {
      await _auth.sendPasswordResetEmail(email: trimmed).timeout(_authTimeout);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'Wrong email.';
        case 'user-not-found':
          return 'Wrong email. No account found for this address.';
        case 'too-many-requests':
          return 'Too many requests. Wait a minute and try again.';
        default:
          return 'Could not send reset email. Try again.';
      }
    } catch (_) {
      return 'Could not send reset email. Check your connection.';
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
      final isAdmin = await _isListedAdminEmail(normalizedEmail);
      final role = isAdmin ? 'admin' : 'customer';

      await _db
          .collection('users')
          .doc(result.user!.uid)
          .set({
            'role': role,
            'email': normalizedEmail,
            'name': name,
            'phone': '',
            'address': '',
            'paymentMethods': <Map<String, dynamic>>[],
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(_firestoreTimeout);
      await recordLastLogin(result.user!.uid);
      return result.user;
    } catch (e) {
      lastAuthError = e.toString();
      return null;
    }
  }

  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      return null;
    }
  }

  // ── Roles & profile ────────────────────────────────────────────────────────

  /// Returns `admin` or `customer`. Creates a missing Firestore profile for older Auth accounts.
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get().timeout(_firestoreTimeout);
      if (!doc.exists) {
        final currentUser = _auth.currentUser;
        final email = (currentUser?.email ?? '').trim().toLowerCase();
        final isAdmin = await _isListedAdminEmail(email);
        final role = isAdmin ? 'admin' : 'customer';
        await _db
            .collection('users')
            .doc(uid)
            .set({
              'role': role,
              'email': email,
              'name': '',
              'phone': '',
              'address': '',
              'paymentMethods': <Map<String, dynamic>>[],
              'createdAt': FieldValue.serverTimestamp(),
            })
            .timeout(_firestoreTimeout);
        return role;
      }
      final data = doc.data() as Map<String, dynamic>;
      var role = data['role'] ?? 'customer';

      // Someone may have been added to admin_emails after they first registered.
      if (role != 'admin') {
        final currentUser = _auth.currentUser;
        final email = (currentUser?.email ?? '').trim().toLowerCase();
        if (email.isNotEmpty && await _isListedAdminEmail(email)) {
          role = 'admin';
          await _db.collection('users').doc(uid).update({'role': role}).timeout(_firestoreTimeout);
        }
      }

      return role;
    } catch (e) {
      return 'customer';
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Admin user list ────────────────────────────────────────────────────────

  /// Live list of all `users` documents for the admin dashboard.
  Stream<List<Map<String, dynamic>>> allUsersStream() => _db
      .collection('users')
      .snapshots()
      .map((s) => s.docs.map((d) => {'uid': d.id, ...d.data()}).toList());

  Future<bool> setUserRole(String uid, String role) async {
    try {
      await _db.collection('users').doc(uid).update({'role': role});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Removes a user's Firestore profile only (not their Auth login — that needs the Firebase console).
  Future<bool> deleteUserProfileDocument(String uid, {String? adminUid}) async {
    lastAuthError = null;
    if (uid.isEmpty) return false;
    if (adminUid != null && adminUid.isNotEmpty && uid == adminUid) return false;
    try {
      await _db.collection('users').doc(uid).delete().timeout(_firestoreTimeout);
      return true;
    } catch (e) {
      lastAuthError = e.toString();
      return false;
    }
  }

  // ── Customer deletes their own account ─────────────────────────────────────

  /// Password is required so Firebase knows it is really them. Deletes profile + Auth user.
  Future<String?> deleteCurrentUserAccountWithPassword(String password) async {
    lastAuthError = null;
    final user = _auth.currentUser;
    if (user == null) return 'You are not signed in.';
    final email = user.email?.trim();
    if (email == null || email.isEmpty) {
      return 'This account type cannot be deleted from the app. Contact support.';
    }
    try {
      final cred = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(cred).timeout(_authTimeout);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Wrong password.';
      }
      lastAuthError = e.message;
      return e.message ?? 'Could not verify your password.';
    } catch (e) {
      return e.toString();
    }
    try {
      await _db.collection('users').doc(user.uid).delete().timeout(_firestoreTimeout);
    } catch (e) {
      return 'Could not remove your profile. Check your connection or try again.';
    }
    try {
      await user.delete().timeout(_authTimeout);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'For security, sign out, sign in again, then delete your account.';
      }
      return e.message ?? 'Could not delete your login.';
    } catch (e) {
      return e.toString();
    }
    return null;
  }

  /// Handy for login errors and admin email lookup.
  Future<Map<String, dynamic>?> getUserProfileByEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return null;
    try {
      var q = await _db.collection('users').where('email', isEqualTo: trimmed).limit(1).get();
      if (q.docs.isEmpty && trimmed != trimmed.toLowerCase()) {
        q = await _db.collection('users').where('email', isEqualTo: trimmed.toLowerCase()).limit(1).get();
      }
      if (q.docs.isEmpty) return null;
      final d = q.docs.first;
      return {'uid': d.id, ...d.data()};
    } catch (_) {
      return null;
    }
  }

  // ── Activity timestamps (admin “last seen”) ──────────────────────────────

  Future<void> recordLastLogin(String uid) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .set({'lastLoginAt': FieldValue.serverTimestamp()}, SetOptions(merge: true))
          .timeout(_firestoreTimeout);
    } catch (_) {}
  }

  Future<void> recordLastActive(String uid) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .set({'lastActiveAt': FieldValue.serverTimestamp()}, SetOptions(merge: true))
          .timeout(_firestoreTimeout);
    } catch (_) {}
  }
}

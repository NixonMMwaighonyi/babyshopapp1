// Decides what to show: login, customer shop, or admin panel based on Firebase user + role.
import 'package:babyshopapp/Screens/admin/admin.dart';
import 'package:babyshopapp/Screens/authenticate/authenticate.dart';
import 'package:babyshopapp/Screens/home/home.dart';
import 'package:babyshopapp/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  /// Avoid creating a new [Future] on every rebuild — that resets [FutureBuilder] forever.
  String? _uidForRoleFuture;
  Future<String>? _roleFuture;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      _uidForRoleFuture = null;
      _roleFuture = null;
      return const Authenticate();
    }

    if (_uidForRoleFuture != user.uid) {
      _uidForRoleFuture = user.uid;
      _roleFuture = AuthService().getUserRole(user.uid);
    }

    return FutureBuilder<String>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load your profile. Check your connection and try again.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == 'admin' ? const AdminPanel() : const Home();
      },
    );
  }
}

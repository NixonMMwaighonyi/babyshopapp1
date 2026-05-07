import 'package:babyshopapp/Screens/admin/admin.dart';
import 'package:babyshopapp/Screens/authenticate/authenticate.dart';
import 'package:babyshopapp/Screens/home/home.dart';
import 'package:babyshopapp/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) return  Authenticate();

    return FutureBuilder<String>(
      future: AuthService().getUserRole(user.uid),
      builder: (context, snapshot) {
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
// Thin shell around [SignIn] when no user is logged in.
import 'package:babyshopapp/Screens/authenticate/sign-in.dart';
import 'package:flutter/material.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  @override
  Widget build(BuildContext context) {
    return const SignIn();
  }
}
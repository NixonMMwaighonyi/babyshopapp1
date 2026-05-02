import 'package:babyshopapp/Screens/authenticate/authenticate.dart';
import 'package:babyshopapp/Screens/authenticate/sign-in.dart';
import 'package:babyshopapp/Screens/home/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:babyshopapp/models/userModel.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    // Return either Home or Authenticate Screens
    if (user == null) {
      return Authenticate();
    } else {
      return Home();
    }
    // return SignIn();
  }
}

import 'package:babyshopapp/Screens/authenticate/sign-in.dart';
import 'package:flutter/material.dart';

class Authenticate extends StatefulWidget{
  @override
  __AuthenticateState createState() => __AuthenticateState();
}

class __AuthenticateState extends State<Authenticate> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: SignIn(),
    );
  }
}
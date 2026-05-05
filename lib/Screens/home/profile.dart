import 'package:babyshopapp/Screens/authenticate/sign-in.dart';
import 'package:babyshopapp/services/auth.dart';
import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final Color BabyBackgroundColor = Color(0xFFeef9fa);
  final Color BabyTeal = Color(0xFF6ecdd4);
  final Color BabyRose = Color(0xFFf79c81);
  final Color BabyDarkGrey = Color(0xFF575757);
  final Color BabyTorquoise = Color(0xFF2e9fb4);

  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BabyBackgroundColor,
      appBar: AppBar(
        backgroundColor: BabyTorquoise,
        title: Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontFamily: 'DynaPuff'),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Placeholder
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: BabyRose,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            
            // Profile Details
            Text(
              'Name: John Doe', // Replace with dynamic data later
              style: TextStyle(
                color: BabyDarkGrey,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Email: john.doe@example.com', // Replace with dynamic data later
              style: TextStyle(
                color: BabyDarkGrey,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Phone: +123 456 7890', // Replace with dynamic data later
              style: TextStyle(
                color: BabyDarkGrey,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 20),
            
            // Edit Profile Button
            ElevatedButton(
              onPressed: () {
                // Add edit functionality later
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BabyTorquoise,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              child: Center(
                child: Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'DynaPuff',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),  // Add spacing
            
            // Logout Button
            ElevatedButton(
              onPressed: () async {
                await _auth.signOut();  // Call the signOut method
                // Navigate to sign-in screen after logout
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SignIn()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BabyRose,  // Use a different color for logout
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              child: Center(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'DynaPuff',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:babyshopapp/Screens/authenticate/sign-in.dart';
import 'package:babyshopapp/services/auth.dart';
import 'package:flutter/material.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final Color BabyBackgroundColor = Color(0xFFeef9fa);
  final Color BabyTeal = Color(0xFF6ecdd4);
  final Color BabyRose = Color(0xFFf79c81);
  final Color BabyDarkGrey = Color(0xFF575757);
  final Color BabyTorquoise = Color(0xFF2e9fb4);

  final AuthService _auth = AuthService();

  String _error = '';
  bool _loading = false;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BabyBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8.0),

                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 20.0,
                  ),
                  child: Image.asset(
                    'assets/png/Logo01.png',
                    width: 300,
                    height: 300,
                  ),
                ),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Text(
                      'Create ',
                      style: TextStyle(
                        color: BabyTeal,
                        fontFamily: 'DynaPuff',
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Account!',
                      style: TextStyle(
                        color: BabyTorquoise,
                        fontFamily: 'DynaPuff',
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      "Do you have an account? ",
                      style: TextStyle(color: BabyDarkGrey, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => {
                        // Navigation to Register Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignIn()),
                        ),
                      },
                      child: Text(
                        'Log in!',
                        style: TextStyle(
                          color: BabyRose,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintStyle: TextStyle(color: const Color(0xFFcdd9da)),
                    hintText: 'Name...',
                    prefixIcon: const Icon(Icons.short_text, size: 25),
                    prefixIconColor: const Color(0xFFcdd9da),
                    filled: true,
                    fillColor: BabyBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18.0,
                      horizontal: 16.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      borderSide: BorderSide(color: BabyTeal),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      borderSide: BorderSide(color: BabyTeal),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      borderSide: BorderSide(color: BabyTorquoise),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintStyle: TextStyle(color: const Color(0xFFcdd9da)),
                    hintText: 'Email...',
                    prefixIcon: const Icon(Icons.email_outlined, size: 25),
                    prefixIconColor: const Color(0xFFcdd9da),
                    filled: true,
                    fillColor: BabyBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18.0,
                      horizontal: 16.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      borderSide: BorderSide(color: BabyTeal),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      borderSide: BorderSide(color: BabyTeal),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      borderSide: BorderSide(color: BabyTorquoise),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintStyle: TextStyle(color: const Color(0xFFcdd9da)),
                    hintText: 'Password...',
                    prefixIcon: const Icon(Icons.lock_outline),
                    prefixIconColor: const Color(0xFFcdd9da),
                    filled: true,
                    fillColor: BabyBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18.0,
                      horizontal: 16.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      borderSide: BorderSide(color: BabyTeal),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      borderSide: BorderSide(color: BabyTeal),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      borderSide: BorderSide(color: BabyTorquoise),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                const SizedBox(height: 18),

                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          setState(() => _loading = true);

                          final name = _nameController.text.trim();
                          final email = _emailController.text.trim();
                          final password = _passwordController.text.trim();

                          if (name.isEmpty ||
                              email.isEmpty ||
                              password.isEmpty) {
                            setState(() {
                              _error = 'Please enter name, email and password.';
                              _loading = false;
                            });
                            return;
                          }

                          // Calling Register method
                          String? result = await _auth.registerWithEmailAndPassword(
                            name: name,
                            email: email,
                            password: password,
                          );

                          setState(() {
                            _loading = false;
                          });

                          if (result == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Registration Successful!"),
                              ),
                            );
                            Navigator.pop(context);
                          } else {
                            setState(() {
                              _error = result;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BabyTorquoise,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _loading ? 'Registering...' : 'Register',
                        style: const TextStyle(
                          fontSize: 18,
                          color: const Color(0xFFeef9fa),
                          fontFamily: 'DynaPuff',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5.0),
                      Icon(
                        Icons.app_registration,
                        size: 25.0,
                        color: const Color(0xFFeef9fa),
                        weight: 900.0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

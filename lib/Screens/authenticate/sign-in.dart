import 'package:babyshopapp/Screens/authenticate/register.dart';
import 'package:babyshopapp/services/auth.dart';
import 'package:flutter/material.dart';

class SignIn extends StatefulWidget {
  final Function? toggleView; // Added support for toggleView if used by wrapper
  const SignIn({super.key, this.toggleView});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  // Brand Colors
  final Color babyBackgroundColor = const Color(0xFFeef9fa);
  final Color babyTeal = const Color(0xFF6ecdd4);
  final Color babyRose = const Color(0xFFf79c81);
  final Color babyDarkGrey = const Color(0xFF575757);
  final Color babyTorquoise = const Color(0xFF2e9fb4);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _error = '';
  bool _loading = false;
  bool _obscurePassword = true;

  final AuthService _auth = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: babyBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8.0),
                  // Logo
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                    child: Image.asset(
                      'assets/png/Logo01.png',
                      width: 300,
                      height: 300,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Header Text
                  Row(
                    children: [
                      Text(
                        'Login ',
                        style: TextStyle(
                          color: babyTeal,
                          fontFamily: 'DynaPuff',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Page',
                        style: TextStyle(
                          color: babyTorquoise,
                          fontFamily: 'DynaPuff',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Toggle to Register
                  Row(
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: babyDarkGrey, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (widget.toggleView != null) {
                            widget.toggleView!();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const Register()),
                            );
                          }
                        },
                        child: Text(
                          'Register!',
                          style: TextStyle(
                            color: babyRose,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                    decoration: _inputDecoration('Email...', Icons.email_outlined),
                  ),
                  const SizedBox(height: 24),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: (val) => val!.isEmpty ? 'Enter your password' : null,
                    decoration: _inputDecoration(
                      'Password...',
                      Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: babyTeal,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Error Message
                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        _error,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: babyRose, fontSize: 14),
                      ),
                    ),

                  const SizedBox(height: 18),

                  // Login Button
                  ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _loading = true;
                          _error = '';
                        });

                        final email = _emailController.text.trim();
                        final password = _passwordController.text.trim();

                        // Calling Sign in method
                        dynamic result = await _auth.signInWithEmailAndPassword(
                          email,
                          password,
                        );

                        if (result == null) {
                          final err = _auth.lastAuthError;
                          setState(() {
                            _error = err == null
                                ? 'Could not sign in with those credentials'
                                : _friendlyAuthError(err);
                            _loading = false;
                          });
                        } else {
                          setState(() {
                            _loading = false;
                          });
                          // On success, your 'Wrapper' will automatically switch to Home
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Login Successful!")),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: babyTeal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _loading ? 'Logging in...' : 'Login',
                          style: TextStyle(
                            fontSize: 18,
                            color: babyDarkGrey,
                            fontFamily: 'DynaPuff',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Icon(Icons.login, size: 25.0, color: babyDarkGrey),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _friendlyAuthError(String raw) {
    final msg = raw.toLowerCase();
    if (msg.contains('user-not-found')) return 'No account found for this email.';
    if (msg.contains('wrong-password')) return 'Wrong password for this email.';
    if (msg.contains('invalid-email')) return 'Invalid email format.';
    if (msg.contains('too-many-requests')) return 'Too many attempts. Please wait and try again.';
    return 'Sign in failed: ${raw}';
  }

  // Helper decoration to maintain UI consistency
  InputDecoration _inputDecoration(String hint, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      hintStyle: const TextStyle(color: Color(0xFFcdd9da)),
      hintText: hint,
      prefixIcon: Icon(icon, size: 25),
      prefixIconColor: const Color(0xFFcdd9da),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: babyBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18.0),
        borderSide: BorderSide(color: babyTeal),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18.0),
        borderSide: BorderSide(color: babyTeal),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18.0),
        borderSide: BorderSide(color: babyTorquoise),
      ),
    );
  }
}

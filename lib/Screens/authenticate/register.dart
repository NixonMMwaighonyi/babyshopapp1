import 'package:babyshopapp/Screens/authenticate/sign-in.dart';
import 'package:babyshopapp/services/auth.dart';
import 'package:flutter/material.dart';

/// New customer sign-up — creates Firebase Auth user + Firestore `users` profile (role from `admin_emails`).
class Register extends StatefulWidget {
  final Function? toggleView;
  const Register({super.key, this.toggleView});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final Color babyBackgroundColor = const Color(0xFFeef9fa);
  final Color babyTeal = const Color(0xFF6ecdd4);
  final Color babyRose = const Color(0xFFf79c81);
  final Color babyDarkGrey = const Color(0xFF575757);
  final Color babyTorquoise = const Color(0xFF2e9fb4);

  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  String _error = '';
  bool _loading = false;
  bool _obscurePassword = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
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
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8.0),
                  // Logo Section
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
                          color: babyTeal,
                          fontFamily: 'DynaPuff',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Account!',
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
                  Row(
                    children: [
                      Text(
                        "Do you have an account? ",
                        style: TextStyle(color: babyDarkGrey, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (widget.toggleView != null) {
                            widget.toggleView!();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignIn()),
                            );
                          }
                        },
                        child: Text(
                          'Log in!',
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

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                    decoration: _inputDecoration('Name...', Icons.short_text),
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
                    validator: (val) => val!.length < 6 ? 'Enter 6+ chars long' : null,
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

                  const SizedBox(height: 12),

                  if (_error.isNotEmpty)
                    Text(
                      _error,
                      style: TextStyle(color: babyRose, fontSize: 14.0),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _loading = true;
                          _error = '';
                        });

                        dynamic result = await _auth.registerWithEmailAndPassword(
                          _emailController.text.trim(),
                          _passwordController.text.trim(),
                          name: _nameController.text.trim(),
                        );

                        if (result == null) {
                          final err = _auth.lastAuthError;
                          setState(() {
                            _error = err == null ? 'Registration failed. Please try again.' : _friendlyAuthError(err);
                            _loading = false;
                          });
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Account Created!")),
                          );
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: babyTorquoise,
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
                          style: TextStyle(
                            fontSize: 18,
                            color: babyBackgroundColor,
                            fontFamily: 'DynaPuff',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Icon(
                          Icons.app_registration,
                          size: 25.0,
                          color: babyBackgroundColor,
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
      ),
    );
  }

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

  String _friendlyAuthError(String raw) {
    final msg = raw.toLowerCase();
    if (msg.contains('email-already-in-use')) return 'This email is already registered.';
    if (msg.contains('weak-password')) return 'Password is too weak.';
    if (msg.contains('invalid-email')) return 'Invalid email format.';
    return 'Registration failed: $raw';
  }
}

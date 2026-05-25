import 'package:babyshopapp/Screens/authenticate/register.dart';
import 'package:babyshopapp/Screens/home/checkoutScreen.dart';
import 'package:babyshopapp/services/auth.dart';
import 'package:flutter/material.dart';

/// Email/password login — errors show on the right field; forgot-password sends a reset link.
class SignIn extends StatefulWidget {
  final Function? toggleView;
  final bool goToCheckoutOnSuccess;
  const SignIn({
    super.key,
    this.toggleView,
    this.goToCheckoutOnSuccess = false,
  });

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

  // Field-level errors from AuthService (wrong email vs wrong password).
  String _emailError = '';
  String _passwordError = '';
  String _generalError = '';
  bool _loading = false;
  bool _obscurePassword = true;

  final AuthService _auth = AuthService();

  void _clearErrors() {
    _emailError = '';
    _passwordError = '';
    _generalError = '';
  }

  /// Firebase emails a reset link; we pre-fill the email they typed on the login form.
  void _showForgotPasswordDialog() {
    final resetEmailCtrl = TextEditingController(text: _emailController.text.trim());
    var sending = false;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Forgot password?', style: TextStyle(fontFamily: 'DynaPuff')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your account email and we\'ll send a link to reset your password.',
                style: TextStyle(height: 1.35, color: babyDarkGrey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                enabled: !sending,
                decoration: _inputDecoration('Email...', Icons.email_outlined),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: babyDarkGrey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: babyTorquoise),
              onPressed: sending
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final email = resetEmailCtrl.text.trim();
                      if (email.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Enter your email address.')),
                        );
                        return;
                      }
                      setSt(() => sending = true);
                      final err = await _auth.sendPasswordResetEmail(email);
                      if (!ctx.mounted) return;
                      setSt(() => sending = false);
                      if (err == null) {
                        Navigator.pop(ctx);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Password reset link sent to $email'),
                            backgroundColor: babyTorquoise,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(err), backgroundColor: babyRose),
                        );
                      }
                    },
              child: sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Send link', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ).then((_) => resetEmailCtrl.dispose());
  }

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

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) {
                      if (_emailError.isNotEmpty) setState(() => _emailError = '');
                    },
                    validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                    decoration: _inputDecoration(
                      'Email...',
                      Icons.email_outlined,
                      errorText: _emailError.isEmpty ? null : _emailError,
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onChanged: (_) {
                      if (_passwordError.isNotEmpty) setState(() => _passwordError = '');
                    },
                    validator: (val) => val!.isEmpty ? 'Enter your password' : null,
                    decoration: _inputDecoration(
                      'Password...',
                      Icons.lock_outline,
                      errorText: _passwordError.isEmpty ? null : _passwordError,
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
                  // Reset link — does not sign the user in; check inbox/spam.
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _loading ? null : _showForgotPasswordDialog,
                      style: TextButton.styleFrom(
                        foregroundColor: babyTorquoise,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                  if (_generalError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        _generalError,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: babyRose, fontSize: 14),
                      ),
                    ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _loading = true;
                          _clearErrors();
                        });

                        final email = _emailController.text.trim();
                        final password = _passwordController.text.trim();

                        dynamic result = await _auth.signInWithEmailAndPassword(
                          email,
                          password,
                        );

                        if (result == null) {
                          // Map AuthService errors onto the email/password fields.
                          setState(() {
                            _emailError = _auth.lastSignInEmailError ?? '';
                            _passwordError = _auth.lastSignInPasswordError ?? '';
                            _generalError = _auth.lastAuthError ?? '';
                            if (_emailError.isEmpty && _passwordError.isEmpty && _generalError.isEmpty) {
                              _generalError = 'Could not sign in. Please try again.';
                            }
                            _loading = false;
                          });
                        } else {
                          await _auth.recordLastLogin(result.uid);
                          setState(() {
                            _loading = false;
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!context.mounted) return;

                            Navigator.of(context).popUntil((route) => route.isFirst);

                            if (!context.mounted) return;

                            if (widget.goToCheckoutOnSuccess) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CheckoutScreen(),
                                ),
                              );
                              return;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Login successful!')),
                            );
                          });
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

  InputDecoration _inputDecoration(String hint, IconData icon, {Widget? suffixIcon, String? errorText}) {
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18.0),
      borderSide: BorderSide(color: babyRose, width: 1.5),
    );
    return InputDecoration(
      hintStyle: const TextStyle(color: Color(0xFFcdd9da)),
      hintText: hint,
      prefixIcon: Icon(icon, size: 25),
      prefixIconColor: const Color(0xFFcdd9da),
      suffixIcon: suffixIcon,
      errorText: errorText,
      errorStyle: TextStyle(color: babyRose, fontSize: 13),
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
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
    );
  }
}

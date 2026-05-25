import 'package:babyshopapp/Screens/authenticate/register.dart';
import 'package:babyshopapp/Screens/authenticate/sign-in.dart';
import 'package:flutter/material.dart';

class GuestCheckoutGate extends StatelessWidget {
  const GuestCheckoutGate({super.key});

  static const Color bgColor = Color(0xFFeef9fa);
  static const Color teal = Color(0xFF6ecdd4);
  static const Color rose = Color(0xFFf79c81);
  static const Color torquoise = Color(0xFF2e9fb4);
  static const Color darkGrey = Color(0xFF575757);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Login required',
          style: TextStyle(fontFamily: 'DynaPuff'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: rose.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: rose,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Login is required to place an order',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'DynaPuff',
                      color: darkGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You can still browse and add items to your cart as a guest. Sign in or create an account to complete your checkout.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: darkGrey.withOpacity(0.85),
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: torquoise,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignIn(
                              goToCheckoutOnSuccess: true,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'DynaPuff',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: teal),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Register(
                              goToCheckoutOnSuccess: true,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Create account',
                        style: TextStyle(
                          color: teal,
                          fontSize: 16,
                          fontFamily: 'DynaPuff',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Back to checkout',
                      style: TextStyle(
                        color: darkGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:babyshopapp/models/cart_model.dart';
import 'package:babyshopapp/services/productService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const Color bgColor   = Color(0xFFeef9fa);
  static const Color teal      = Color(0xFF6ecdd4);
  static const Color rose      = Color(0xFFf79c81);
  static const Color torquoise = Color(0xFF2e9fb4);

  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final ProductService _ps = ProductService();

  bool _placing = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(CartProvider cart) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _placing = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _placing = false);
      return;
    }

    final address = '${_addressCtrl.text.trim()}, ${_cityCtrl.text.trim()}';
    final success = await _ps.placeOrder(
      userId: user.uid,
      userEmail: user.email ?? '',
      cartItems: cart.items,
      totalAmount: cart.totalAmount,
      shippingAddress: address,
    );

    if (success) {
      cart.clearCart();
      if (mounted) {
        Navigator.popUntil(context, (r) => r.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully. You can track it in My Orders.'),
            backgroundColor: Color(0xFF2e9fb4),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      setState(() => _placing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to place order. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontFamily: 'DynaPuff')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: teal.withOpacity(0.1), blurRadius: 8)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'DynaPuff')),
                    const Divider(),
                    ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Text('${item.product.title} x${item.quantity}', overflow: TextOverflow.ellipsis)),
                        Text('\$${item.totalPrice.toStringAsFixed(2)}', style: TextStyle(color: torquoise, fontWeight: FontWeight.w500)),
                      ]),
                    )),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('\$${cart.totalAmount.toStringAsFixed(2)}', style: TextStyle(color: torquoise, fontWeight: FontWeight.bold, fontSize: 18)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Shipping details
              const Text('Shipping Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'DynaPuff')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                validator: (v) => v!.isEmpty ? 'Enter your street address' : null,
                decoration: _dec('Street Address', Icons.home_outlined),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityCtrl,
                validator: (v) => v!.isEmpty ? 'Enter your city' : null,
                decoration: _dec('City', Icons.location_city_outlined),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Enter your phone number' : null,
                decoration: _dec('Phone Number', Icons.phone_outlined),
              ),
              const SizedBox(height: 24),

              // Payment note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber[200]!)),
                child: const Row(children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text('This is a demo app. No real payment is processed.', style: TextStyle(fontSize: 13))),
                ]),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: rose, padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _placing ? null : () => _placeOrder(cart),
                  child: _placing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Place Order', style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'DynaPuff')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: teal),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: teal)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: teal)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: torquoise, width: 1.5)),
  );
}
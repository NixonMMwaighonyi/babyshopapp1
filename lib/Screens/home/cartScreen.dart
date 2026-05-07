import 'package:babyshopapp/Screens/home/checkoutScreen.dart';
import 'package:babyshopapp/models/cart_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const Color bgColor   = Color(0xFFeef9fa);
  static const Color teal      = Color(0xFF6ecdd4);
  static const Color rose      = Color(0xFFf79c81);
  static const Color torquoise = Color(0xFF2e9fb4);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('My Cart', style: TextStyle(fontFamily: 'DynaPuff')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
                title: const Text('Clear Cart'),
                content: const Text('Remove all items from your cart?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: rose),
                    onPressed: () { cart.clearCart(); Navigator.pop(context); },
                    child: const Text('Clear', style: TextStyle(color: Colors.white)),
                  ),
                ],
              )),
              child: const Text('Clear', style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: teal.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Add some baby products to get started!', style: TextStyle(color: Colors.grey)),
        ]),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              itemBuilder: (_, i) {
                final item = cart.items[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(color: item.product.color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                          child: Icon(item.product.icon, color: item.product.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.product.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                            Text('\$${item.product.priceValue.toStringAsFixed(2)} each', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            Text('Subtotal: \$${item.totalPrice.toStringAsFixed(2)}', style: TextStyle(color: torquoise, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                        Column(children: [
                          Row(children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: teal),
                              onPressed: () => cart.updateQuantity(item.product.id, item.quantity - 1),
                              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: teal),
                              onPressed: () => cart.updateQuantity(item.product.id, item.quantity + 1),
                              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                            ),
                          ]),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: rose),
                            onPressed: () => cart.removeFromCart(item.product.id),
                          ),
                        ]),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -4))],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${cart.itemCount} items', style: const TextStyle(color: Colors.grey)),
                Text('Total: \$${cart.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: torquoise)),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: rose, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                  child: const Text('Proceed to Checkout', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'DynaPuff')),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
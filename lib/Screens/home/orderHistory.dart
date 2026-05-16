// Lists the signed-in customer's orders; tap through to track delivery status.
import 'package:babyshopapp/models/cart_model.dart';
import 'package:babyshopapp/services/productService.dart';
import 'package:babyshopapp/Screens/home/track_order_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  static const Color bgColor   = Color(0xFFeef9fa);
  static const Color teal      = Color(0xFF6ecdd4);
  static const Color rose      = Color(0xFFf79c81);
  static const Color torquoise = Color(0xFF2e9fb4);

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return Colors.green;
      case 'shipped':   return Colors.blue;
      case 'delivered': return Colors.teal;
      case 'cancelled': return Colors.red;
      default:          return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(fontFamily: 'DynaPuff')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Please log in to see your orders.'))
          : StreamBuilder<List<AppOrder>>(
        stream: ProductService().userOrdersStream(user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: teal));
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 62, color: rose.withOpacity(0.8)),
                    const SizedBox(height: 10),
                    const Text(
                      'Could not load order history.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Please check your internet and Firestore rules, then try again.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          final orders = snap.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.local_shipping_outlined, size: 80, color: teal.withOpacity(0.4)),
                const SizedBox(height: 16),
                const Text('No orders yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                const SizedBox(height: 8),
                const Text('Your orders will appear here after checkout.', style: TextStyle(color: Colors.grey)),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final order = orders[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFeef9fa), child: Icon(Icons.shopping_bag_outlined, color: torquoise)),
                  title: Text('Order #${order.id.substring(0, 6).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${order.date.day}/${order.date.month}/${order.date.year} · \$${order.totalAmount.toStringAsFixed(2)}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(order.status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(order.status, style: TextStyle(color: _statusColor(order.status), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('${item.productTitle} x${item.quantity}'),
                              Text('\$${(item.priceValue * item.quantity).toStringAsFixed(2)}', style: TextStyle(color: torquoise)),
                            ]),
                          )),
                          const Divider(),
                          if (order.shippingAddress.isNotEmpty)
                            Text('Shipping to: ${order.shippingAddress}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => TrackOrderScreen(orderId: order.id)),
                              ),
                              icon: const Icon(Icons.map_outlined, size: 18, color: torquoise),
                              label: const Text('Track delivery', style: TextStyle(color: torquoise, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}